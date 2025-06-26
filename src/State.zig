const std = @import("std");
const root = @import("root");
const scu = root.scu;
const trm = root.trm;
const Buffer = root.Buffer;
const Args = root.Args;

pub const Backend = @import("backend/Backend.zig");
const Command = @import("Command.zig");
const Config = @import("Config.zig");
const keys = @import("keys.zig");
const km = @import("keymaps.zig");
const lua = @import("lua.zig");
const Component = @import("render/Component.zig");
const render = @import("render/root.zig");

const State = @This();

const Mountable = struct {
    view: Component.View,
    comp: Component,
};

/// Must be an allocator that can handle races
a: std.mem.Allocator,
arena: std.heap.ArenaAllocator,

backend: Backend,

// undos: Undo_Stack,
// redos: Undo_Stack,
// undo: Undo,

ch: trm.KeyEvent = @bitCast(@as(u16, 0)),

repeating: Repeating = .{},

command: Command,

/// Message to show in the status bar, remains until cleared
/// must be arena allocated
status_bar_msg: ?[]const u8 = null,

keyMaps: [Buffer.Mode.COUNT]km.KeyMaps,
/// If null then do the normal key map look up, else use this as the key maps,
/// dont touch this as if you try to be clever it will just be set to null
currentKeyMap: ?*km.KeyMaps = null,

L: *lua.State,

config: Config = .{},

buffers: std.ArrayListUnmanaged(*Buffer),
/// Always a memeber of the buffers array
buffer: *Buffer, // todo: might be better to make it an index
// bufferindex: usize = 0,

resized: bool,

components: std.AutoArrayHashMapUnmanaged(usize, Mountable) = .{},

// line_num_win: scu.Term.Screen,
// main_win: scu.Term.Screen,
// status_bar: scu.Term.Screen,

// TreeSitter Parsers
tsmap: std.ArrayListUnmanaged(void) = .{},

pub fn init(a: std.mem.Allocator, file: ?[]const u8, args: Args) anyerror!State {
    try checkfirstrun(a);

    var buffers = std.ArrayListUnmanaged(*Buffer){};
    const buffer = try a.create(Buffer);
    if (file) |f| {
        root.log(@src(), .debug, "opening file ({s})", .{f});
        buffer.* = Buffer.initFile(a, f) catch |err| {
            root.log(@src(), .err, "File Not Found: {s}", .{f});
            a.destroy(buffer);
            return err;
        };
    } else {
        buffer.* = Buffer.initEmpty();
    }
    try buffers.append(a, buffer);

    const backend = try Backend.init(a, args);
    // const t = try scu.Term.init(a);

    const L = lua.init();

    var state = State{
        .a = a,
        .arena = std.heap.ArenaAllocator.init(a),
        .L = L,

        // .term = t,
        .backend = backend,

        .keyMaps = .{km.KeyMaps{}} ** Buffer.Mode.COUNT,

        // .undo_stack = Undo_Stack.init,
        // .redo_stack = Undo_Stack.init(a),
        // .cur_undo = Undo{},

        .buffers = buffers,
        .buffer = buffer,
        .command = try Command.init(a),

        // Do all the screen math before the first render starts
        .resized = true,

        // .line_num_win = undefined,
        // .main_win = undefined,
        // .status_bar = undefined,
    };
    try keys.initKeyMaps(&state);
    try render.init(&state);

    return state;
}

pub fn deinit(state: *State) void {
    std.log.debug("deiniting state", .{});

    // keymaps before lua as they reference the lua state
    for (&state.keyMaps) |*keyMap| keyMap.deinit(state.a);

    lua.deinit(state.L);

    // state.cur_undo.data.deinit(state.a);
    // state.undo_stack.deinit();
    // state.redo_stack.deinit();

    // state.a.free(state.status_bar_msg);

    state.command.deinit(state.a);

    for (state.buffers.items) |buffer| {
        buffer.deinit(state.a);
        state.a.destroy(buffer);
    }
    state.buffers.deinit(state.a);

    std.log.debug("closing backend", .{});
    state.backend.deinit();

    state.arena.deinit();
}

// pub fn getBuffer(state: *const State) *Buffer {
//     return state.buffers.items[state.bufferindex];
// }

pub fn getCurrentBuffer(state: *State) ?*Buffer {
    return state.buffer;
}

pub fn press(state: *State, ke: trm.KeyEvent) !void {
    // -- Command Thing --------------------
    if (state.command.is) {
        try state.command.maps.run(state, ke);
        return;
    }
    // -------------------------

    try state.getKeyMaps().run(state, ke);
}

fn getKeyMaps(state: *const State) *const km.KeyMaps {
    if (state.currentKeyMap) |map| return map;
    return &state.keyMaps[@intFromEnum(state.buffer.mode)];
}

pub const Repeating = struct {
    is: bool = false,
    count: usize = 0,

    pub inline fn reset(self: *Repeating) void {
        self.is = false;
        self.count = 0;
    }
};

pub fn takeRepeating(state: *State) usize {
    const count = if (state.repeating.is) state.repeating.count else 1;
    state.repeating.count = 0;
    state.repeating.is = false;
    return count;
}

fn checkfirstrun(a: std.mem.Allocator) !void {
    const home = std.posix.getenv("HOME") orelse unreachable;
    const initFile = try std.fmt.allocPrint(a, "{s}/.config/neomacs/init.lua", .{home});
    defer a.free(initFile);

    if (std.fs.accessAbsolute(initFile, .{})) |_| {
        std.log.info("Welcome back vet!", .{});
        return;
    } else |_| {
        // welcome FNG
        // const DEFAULTCONFIG = @embedFile("config.lua");
        // const file = try std.fs.openFileAbsolute(initFile, .{ .mode = .write_only });
        // defer file.close();
        // try file.writeAll(DEFAULTCONFIG);
        return;
    }
}

// TODO: fix these and make them better
pub fn bufferNext(state: *State) void {
    if (state.buffers.items.len < 2) return;

    for (state.buffers.items, 0..) |buf, i| {
        if (@intFromPtr(buf) == @intFromPtr(state.buffer)) {
            if (i == state.buffers.items.len - 1) {
                state.buffer = state.buffers.items[0];
            } else {
                state.buffer = state.buffers.items[i + 1];
            }
        }
        return;
    }
}
pub fn bufferPrev(state: *State) void {
    if (state.buffers.items.len < 2) return;

    for (state.buffers.items, 0..) |buf, i| {
        if (@intFromPtr(buf) == @intFromPtr(state.buffer)) {
            if (i == 0) {
                state.buffer = state.buffers.items[state.buffers.items.len - 1];
            } else {
                state.buffer = state.buffers.items[i - 1];
            }
        }
        return;
    }
}
