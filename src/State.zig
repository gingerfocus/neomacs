const std = @import("std");
const root = @import("root");
const keys = @import("keys.zig");
const lua = @import("lua.zig");
const tools = @import("tools.zig");
const fr = @import("frontend.zig");

const km = @import("keymaps.zig");

const luajitsys = root.luajitsys;
const scu = root.scu;
const trm = scu.thermit;

const Buffer = @import("Buffer.zig");
const Config = @import("Config.zig");
const State = @This();

a: std.mem.Allocator,
arena: std.heap.ArenaAllocator,

term: scu.Term,

// undos: Undo_Stack,
// redos: Undo_Stack,
// undo: Undo,

ch: trm.KeyEvent = .{ .character = scu.thermit.KeySymbol.None.toBits() },
/// Motion keys have two ways in which they select text, a region and a
/// point. A motion can set this structure to not null to indicate what it
/// wants. Then a selector runs using this data. The default one just sets the
/// cursor to target position. Some other common ones are `d` which deletes
/// text in the selection. The can also be user defined.
target: ?struct {
    select: struct { x1: usize, y1: usize, x2: usize, y2: usize },
    cursor: usize,
} = null,

command: std.ArrayListUnmanaged(u8),
repeating: Repeating = .{},
leader: Leader = .NONE,

/// Message to show in the status bar, remains until cleared
/// must be area allocated
status_bar_msg: ?[]const u8 = null,

// cursor x position
// x: usize = 0,
// cursor y position
// y: usize = 0,

keyMaps: [Buffer.Mode.COUNT]km.KeyMaps,
/// If null then do the normal key map look up, else use this as the key maps,
/// dont touch this as if you try to be clever it will just be set to null
currentKeyMap: ?*km.KeyMaps = null,

L: *lua.LuaState,

// clipboard: ?[]const u8 = null,

buffers: std.ArrayListUnmanaged(*Buffer),
/// Always a memeber of the buffers array
buffer: *Buffer,

resized: bool,

line_num_win: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),
main_win: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),
status_bar: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),

config: ?Config = null,

pub fn init(a: std.mem.Allocator, file: []const u8) !State {
    root.log(@src(), .debug, "opening file ({s})", .{file});

    const buffer = try a.create(Buffer);
    buffer.* = Buffer.init(a, file) catch |err| {
        root.log(@src(), .err, "File Not Found: {s}", .{file});
        return err;
    };
    var buffers = std.ArrayListUnmanaged(*Buffer){};
    try buffers.append(a, buffer);

    const t = try scu.Term.init(a);
    const L = lua.init();

    var state = State{
        .a = a,
        .arena = std.heap.ArenaAllocator.init(a),
        .term = t,
        .L = L,

        .keyMaps = .{.{}} ** Buffer.Mode.COUNT,

        // .undo_stack = Undo_Stack.init(a),
        // .redo_stack = Undo_Stack.init(a),
        // .cur_undo = Undo{},

        .buffers = buffers,
        .buffer = buffer,
        .command = .{},

        // Do all the screen math before the first render starts
        .resized = true,
    };
    try keys.initKeyMaps(&state);

    // try lua.runCommand(state.L, "tester");

    return state;
}

pub fn deinit(state: *State) void {
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

    state.term.deinit();

    state.arena.deinit();
}

pub fn getKeyMaps(state: *const State) *const km.KeyMaps {
    if (state.currentKeyMap) |map| return map;
    return &state.keyMaps[@intFromEnum(state.buffer.mode)];
}

pub fn getConfig(state: *State) *const Config {
    if (state.config) |*config| {
        return config;
    }
    state.config = Config.get(state.L);
    return &state.config.?;
}

pub fn slowExit(state: *State) void {
    Config.set(state.L, "QUIT", true);
}

pub const Leader = enum(u32) { NONE = 0, R = 1, D = 2, Y = 3 };

pub const Repeating = struct {
    is: bool = false,
    count: usize = 0,

    pub inline fn reset(self: *Repeating) void {
        self.is = false;
        self.count = 0;
    }
};
