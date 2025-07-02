const root = @import("root.zig");
const std = root.std;
const scu = root.scu;
const trm = root.trm;
const xev = root.xev;
const lua = root.lua;
const km = root.km;

const Buffer = root.Buffer;
const Args = root.Args;

const Command = @import("Command.zig");
const Config = @import("Config.zig");
const keys = @import("keys.zig");
const Component = @import("render/Component.zig");
const render = @import("render/root.zig");

pub const Backend = @import("backend/Backend.zig");

const State = @This();

const Mountable = struct {
    view: Component.View,
    comp: Component,
};

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

// defaultKeyMap: [3]rc.RcUnmanaged(km.KeyMaps),

namedmaps: std.AutoArrayHashMapUnmanaged(Buffer.Mode, *km.KeyMaps),
currentKeyMap: ?*km.KeyMaps = null,

// If null then do the normal key map look up, else use this as the key maps,
// dont touch this as if you try to be clever it will just be set to null
// currentKeyMap: ?*km.KeyMaps = null,

L: *lua.LuaState,

config: Config = .{},

resized: bool = false,

// zygotbuffer: *Buffer,

buffers: std.ArrayListUnmanaged(*Buffer),
/// Always a memeber of the buffers array
buffer: *Buffer, // todo: might be better to make it an index
// bufferindex: usize = 0,

// resized: bool = true,

components: std.AutoArrayHashMapUnmanaged(usize, Mountable) = .{},

// TreeSitter Parsers
// tsmap: std.ArrayListUnmanaged(void) = .{},

loop: xev.Loop,
inputcallback: ?struct { *xev.Completion, xev.Async } = null,

pub fn init(a: std.mem.Allocator, file: ?[]const u8, args: Args) anyerror!State {
    try checkfirstrun(a);

    const L = lua.init();

    var arena = std.heap.ArenaAllocator.init(a);
    const maps = try keys.create(a, &arena);

    var state = State{
        .a = a,
        .arena = arena,
        .L = L,

        // .term = t,
        .backend = try Backend.init(a, args),

        .namedmaps = maps,

        // .undo_stack = Undo_Stack.init,
        // .redo_stack = Undo_Stack.init(a),
        // .cur_undo = Undo{},

        .command = try Command.init(a),
        .buffers = .{},
        .buffer = undefined,

        .loop = try xev.Loop.init(.{}),
    };

    var buffers = std.ArrayListUnmanaged(*Buffer){};
    const buffer = try a.create(Buffer);
    if (file) |f| {
        root.log(@src(), .debug, "opening file ({s})", .{f});
        buffer.* = Buffer.initFile(&state, f) catch |err| {
            root.log(@src(), .err, "File Not Found: {s}", .{f});
            a.destroy(buffer);
            return err;
        };
    } else {
        buffer.* = Buffer.initEmpty();
    }

    // for (0..Buffer.Mode.COUNT) |i| {
    //     buffer.keymap = state.defaultKeyMaps[i].clone();
    // }

    try buffers.append(a, buffer);

    state.buffers = buffers;
    state.buffer = buffer;

    try render.init(&state);

    return state;
}

pub fn deinit(state: *State) void {
    std.log.debug("deiniting state", .{});

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

    // keymaps before lua as they reference the lua state
    //                                 v comfirm it got released
    state.namedmaps.deinit(state.a);
    state.components.deinit(state.a);

    lua.deinit(state.L);

    std.log.debug("closing backend", .{});
    state.backend.deinit();

    state.loop.deinit();
    state.arena.deinit();
}

// pub fn getBuffer(state: *const State) *Buffer {
//     return state.buffers.items[state.bufferindex];
// }

pub fn getCurrentBuffer(state: *State) ?*Buffer {
    return state.buffer;
}

pub fn press(state: *State, ke: trm.KeyEvent) !void {
    try state.loop.run(.no_wait);

    // -- Command Thing --------------------
    if (state.command.is) {
        try state.command.maps.run(state, ke);
        return;
    }
    // -------------------------

    try state.getKeyMaps().run(state, ke);
}

fn getKeyMaps(state: *const State) *const km.KeyMaps {
    if (state.currentKeyMap) |map| {
        std.log.info("using current keymap", .{});
        return map;
    }

    const buffer = state.buffer;
    return state.namedmaps.get(buffer.mode) orelse state.namedmaps.get(.normal).?;
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
            return;
        }
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
