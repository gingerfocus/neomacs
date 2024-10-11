const std = @import("std");
const root = @import("root");
const keys = @import("keys.zig");
const lua = @import("lua.zig");
const tools = @import("tools.zig");
const fr = @import("frontend.zig");

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

ch: trm.KeyEvent = std.mem.zeroes(trm.KeyEvent),

// command: std.ArrayListUnmanaged(u8),
repeating: Repeating = .{},
leader: Leader = .NONE,

/// Message to show in the status bar, remains until cleared
/// must be area allocated
status_bar_msg: ?[]const u8 = null,

/// cursor x position
x: usize = 0,
/// cursor y position
y: usize = 0,

keyMaps: [5]KeyMaps = .{ .{}, .{}, .{}, .{}, .{} },
/// If null then do the normal key map look up, else use this as the key maps
currentKeyMap: ?*KeyMaps = null,

L: *lua.State,

// clipboard: ?[]const u8 = null,
buffer: *Buffer,

resized: bool,

line_num_win: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),
main_win: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),
status_bar: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),

config: Config,

pub fn init(a: std.mem.Allocator, file: []const u8) !State {
    root.log(@src(), .debug, "opening file ({s})", .{file});

    const buffer = try a.create(Buffer);
    buffer.* = Buffer.init(a, file) catch |err| {
        root.log(@src(), .err, "File Not Found: {s}", .{file});
        return err;
    };

    const t = try scu.Term.init(a);
    const L = try lua.init();

    var state = State{
        .a = a,
        .arena = std.heap.ArenaAllocator.init(a),

        .term = t,
        .L = L,

        // .undo_stack = Undo_Stack.init(a),
        // .redo_stack = Undo_Stack.init(a),
        // .cur_undo = Undo{},
        .buffer = buffer,
        // .num_of_braces = @import("std").mem.zeroes(usize),
        // .ch = 0,
        // .env = null,
        // .command = try a.allocSentinel(u8, 63, 0),
        // .command_s = @import("std").mem.zeroes(usize),
        // .variables = Variables{},
        // .repeating = @import("std").mem.zeroes(Repeating),
        // .is_print_msg = false,
        // .status_bar_msg = try a.alloc(u8, 128),
        // .x = @import("std").mem.zeroes(usize),
        // .y = @import("std").mem.zeroes(usize),
        // .normal_pos = @import("std").mem.zeroes(usize),
        // .key_func = null,
        // .clipboard = @import("std").mem.zeroes(Sized_Str),
        // .files = Files{},

        // Do all the screen math before the first render starts
        .resized = true,

        .config = try Config.init(a),
    };
    try keys.initKeyMaps(&state);

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

    state.buffer.deinit(state.a);
    state.a.destroy(state.buffer);

    state.config.deinit(state.a);

    state.term.deinit();

    state.arena.deinit();
}

pub fn getKeyMaps(state: *const State) *const KeyMaps {
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
    QUIT: bool = false,
    mode: Mode = .NORMAL,
    // background_color: c_int = -1,
    // leaders: [4]u8,
    // key_maps: Maps,

    /// Used by lua call backs to lock the config state before changing it
    luaLock: std.Thread.Mutex = .{},

    pub fn init(a: std.mem.Allocator) !Config {
        _ = a; // autofix
        // const lang = try a.dupe(u8, " ");
        // _ = lang; // autofix
        return Config{
            // .lang = lang,
            // .relative_nums = 1,
            // .auto_indent = 1,
            // .syntax = 1,
            // .indent = 0,
            // .undo_size = 16,
            .QUIT = false,
            .mode = .NORMAL,
            // .background_color = -@as(c_int, 1),
            // .leaders = .{ ' ', 'r', 'd', 'y' },
            // .key_maps = Maps{},
        };
    }

    pub fn deinit(config: Config, a: std.mem.Allocator) void {
        _ = config; // autofix
        _ = a; // autofix
        // a.free(config.lang);
    }
};

fn fallbackNone(_: *State) !void {}
// fn targeterNone(state: *State, target: usize) void {
//     state.buffer.cursor = target;
// }

pub const KeyMapings = std.AutoArrayHashMapUnmanaged(u16, KeyMap);
pub const KeyMaps = struct {
    keys: KeyMapings = .{},

    // targeter: *const fn (*State, usize) void,
    fallback: KeyMap = .{ .Native = fallbackNone },

    pub fn deinit(self: *KeyMaps, a: std.mem.Allocator) void {
        var iter = self.keys.iterator();
        while (iter.next()) |key| key.value_ptr.deinit(a);

        self.keys.deinit(a);
    }

    pub fn run(self: KeyMaps, state: *State) !void {
        if (self.keys.get(scu.thermit.keys.bits(state.ch))) |function| {
            // if there is a custom handler then run it
            try function.run(state);
        } else {
            // if there is no handler and its just a regular key then send it to
            // the buffer
            try self.fallback.run(state);
        }
    }

    pub inline fn put(self: *KeyMaps, a: std.mem.Allocator, character: u16, value: KeyMap) !void {
        self.keys.put(a, character, value);
    }

    /// Gets the next
    pub fn then(self: *KeyMaps, a: std.mem.Allocator, character: u16) *KeyMaps {
        const res = self.keys.getOrPut(a, character) catch @panic("OOM");
        if (res.found_existing) {
            switch (res.value_ptr) {
                .SubMap => |map| return map,
                else => {},
            }
        }
        res.value_ptr.* = .{ .SubMap = a.create(KeyMaps) catch @panic("OOM") };
        return res.value_ptr;
    }
};

pub const KeyMap = union(enum) {
    const Callback = *const fn (*State) anyerror!void;
    const LuaRef = c_int;

    Native: Callback,
    LuaFnc: LuaRef,
    SubMap: *KeyMaps,

    pub fn deinit(self: KeyMap, a: std.mem.Allocator) void {
        switch (self) {
            .SubMap => |map| map.deinit(a),
            else => {},
        }
    }

    pub fn initLua(L: *lua.State, index: c_int) !KeyMap {
        if (lua.lua_type(L, index) != lua.LUA_TFUNCTION) {
            return error.NotALuaFunction;
            // lua.lua_pushliteral(L, "vim.schedule: expected function");
            // return lua.lua_error(L);
        }

        lua.lua_pushvalue(L, index);
        const ref = lua.luaL_ref(L, lua.LUA_REGISTRYINDEX);
        if (ref > 0) {
            // ref_state->ref_count++;
        } else {
            return error.CantMakeReference;
        }

        return .{ .LuaFnc = ref };
    }

    pub fn run(self: KeyMap, state: *State) anyerror!void {
        switch (self) {
            .Native => |fc| try fc(state),
            .LuaFnc => |id| {
                std.debug.assert(id > 0);

                luajitsys.lua_rawgeti(state.L, luajitsys.LUA_REGISTRYINDEX, id);
                luajitsys.luaL_unref(state.L, luajitsys.LUA_REGISTRYINDEX, id);
                // ref_state->ref_count--;

                if (luajitsys.lua_pcall(state.L, 0, 0, 0) != 0) {
                    // nlua_error(lstate, _("Error executing vim.schedule lua callback: %.*s"));
                    return error.ExecuteLuaCallback;
                }
            },
            .SubMap => |map| {
                state.currentKeyMap = map;
                return;
            },
        }
    }
};

pub const Leader = enum(u32) { NONE = 0, R = 1, D = 2, Y = 3 };

pub const Mode = enum(usize) {
    NORMAL = 0,
    INSERT = 1,
    SEARCH = 2,
    COMMAND = 3,
    VISUAL = 4,

    pub fn toString(self: Mode) []const u8 {
        return switch (self) {
            .NORMAL => "NORMAL",
            .INSERT => "INSERT",
            .SEARCH => "SEARCH",
            .COMMAND => "COMMAND",
            .VISUAL => "VISUAL",
        };
    }
};

pub const Repeating = struct {
    is: bool = false,
    count: usize = 0,
};
