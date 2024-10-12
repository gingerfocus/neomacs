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
const State = @This();

a: std.mem.Allocator,
arena: std.heap.ArenaAllocator,

term: scu.Term,

// undos: Undo_Stack,
// redos: Undo_Stack,
// undo: Undo,

ch: trm.KeyEvent = .{ .character = scu.thermit.KeySymbol.None.toBits() },

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

keyMaps: [Mode.COUNT]km.KeyMaps,
/// If null then do the normal key map look up, else use this as the key maps,
/// dont touch this as if you try to be clever it will just be set to null
currentKeyMap: ?*km.KeyMaps = null,

L: *lua.LuaState,

// clipboard: ?[]const u8 = null,
buffer: *Buffer,

resized: bool,

line_num_win: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),
main_win: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),
status_bar: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),

config: Config = .{},

pub fn init(a: std.mem.Allocator, file: []const u8) !State {
    root.log(@src(), .debug, "opening file ({s})", .{file});

    const buffer = try a.create(Buffer);
    buffer.* = Buffer.init(a, file) catch |err| {
        root.log(@src(), .err, "File Not Found: {s}", .{file});
        return err;
    };

    const t = try scu.Term.init(a);
    const L = lua.init();

    var state = State{
        .a = a,
        .arena = std.heap.ArenaAllocator.init(a),
        .term = t,
        .L = L,

        .keyMaps = .{.{}} ** Mode.COUNT,

        // .undo_stack = Undo_Stack.init(a),
        // .redo_stack = Undo_Stack.init(a),
        // .cur_undo = Undo{},

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

    // for (state.files.items) |file| {
    //     state.a.free(file.name);
    //     state.a.free(file.path);
    // }
    // state.files.deinit(state.a);

    // state.cur_undo.data.deinit(state.a);
    // state.undo_stack.deinit();
    // state.redo_stack.deinit();

    // state.a.free(state.status_bar_msg);

    state.command.deinit(state.a);

    state.buffer.deinit(state.a);
    state.a.destroy(state.buffer);

    state.term.deinit();

    state.arena.deinit();
}

pub fn getKeyMaps(state: *const State) *const km.KeyMaps {
    if (state.currentKeyMap) |map| return map;
    return &state.keyMaps[@intFromEnum(state.config.mode)];
}

pub const Config = struct {
    // relative_nums: c_int = 1,
    // auto_indent: c_int = 1,
    // syntax: c_int = 1,
    // indent: c_int = 0,
    // undo_size: c_int = 16,
    // lang: []const u8,

    /// If true then exit the program, ussually dont need to lock for this as
    /// if we are exiting then a race condition is not that important
    QUIT: bool = false,
    mode: Mode = .normal,
    // background_color: c_int = -1,
    // leaders: [4]u8,
    // .leaders = .{ ' ', 'r', 'd', 'y' },
    // key_maps: Maps,

    // Used by lua call backs to lock the config state before changing it
    // luaLock: std.Thread.Mutex = .{},
};

pub const Leader = enum(u32) { NONE = 0, R = 1, D = 2, Y = 3 };

pub const Mode = enum(usize) {
    normal = 0,
    insert = 1,
    search = 2,
    comand = 3,
    visual = 4,

    const COUNT = @typeInfo(Mode).Enum.fields.len;

    pub fn toString(self: Mode) []const u8 {
        return switch (self) {
            .normal => "NORMAL",
            .insert => "INSERT",
            .search => "SEARCH",
            .comand => "COMMAND",
            .visual => "VISUAL",
        };
    }
};

pub const Repeating = struct {
    is: bool = false,
    count: usize = 0,
};
