const root = @import("../root.zig");
const std = root.std;
const lua = root.lua;
const km = root.km;
const lib = root.lib;

const State = root.State;
const KeyMaps = km.KeyMaps;
const Buffer = root.Buffer;

const thunk = struct {
    fn setmode(buffer: *Buffer, argdata: ?*anyopaque) !void {
        const data = @as(?*const km.ModeId, @ptrCast(@alignCast(argdata)));

        if (data) |mode| buffer.setMode(mode.*);
    }
};


pub const KeyDataPtr = lib.types.TypeErasedData;
// pub const KeyDataPtr = anyopaque;

dataptr: ?*lib.types.TypeErasedData = null,
function: FunctionAction,

const Self = @This();

pub fn initstate(func: *const fn (*State, km.KeyFunctionDataValue) anyerror!void) Self {
    return .{
        .function = .{ .state = func },
    };
}

pub fn initbuffer(func: *const fn (*Buffer, km.KeyFunctionDataValue) anyerror!void) Self {
    return .{
        .function = .{ .buffer = func },
    };
}

pub fn initlua(L: ?*lua.State, index: lua.LuaRef) !Self {
    if (lua.sys.lua_type(L, index) != lua.sys.LUA_TFUNCTION) {
        return error.NotALuaFunction;
    }

    lua.sys.lua_pushvalue(L, index);
    const ref = lua.sys.luaL_ref(L, lua.sys.LUA_REGISTRYINDEX);
    if (ref <= 0) return error.CantMakeReference;

    return .{
        .function = .{ .lua_function = ref },
    };
}

pub fn initsetmod(mode: km.ModeId) Self {
    return .{
        .function = .{ .setmod = mode },
    };
}

pub fn setdata(self: *Self, comptime T: type, alloc: std.mem.Allocator, value: T) !void {
    self.dataptr = try lib.types.TypeErased(T).init(alloc, value);
}

pub fn getdata(self: *Self, comptime T: type) ?*T {
    if (self.dataptr) |ptr| return ptr.get(T);
    return null;
}

pub fn deinit(self: *Self, L: ?*lua.State, a: std.mem.Allocator) void {
    if (self.dataptr) |ptr| ptr.deinit(a);

    switch (self.function) {
        // .SubMap => |map| {
        //     map.deinit(L, a);
        //     a.destroy(map);
        // },
        .lua_function => |id| {
            lua.sys.luaL_unref(L, lua.sys.LUA_REGISTRYINDEX, id);
        },
        else => {},
    }

    self.* = undefined;
}

pub fn run(self: Self, state: *State) anyerror!void {
    return switch (self.function) {
        .state => |fc| {
            try fc(state, .{ .character = state.ch, .dataptr = self.dataptr });
        },
        .lua_function => |id| {
            std.debug.assert(id > 0);

            lua.sys.lua_rawgeti(state.L, lua.sys.LUA_REGISTRYINDEX, id);

            if (lua.sys.lua_pcall(state.L, 0, 0, 0) != 0) {
                // nlua_error(lstate, _("Error executing vim.schedule lua callback: %.*s"));
                return error.ExecuteLuaCallback;
            }
        },
        // TODO: this can be run as a coroutine as it only takes buffer state
        .buffer => |fc| {
            const buffer = state.getCurrentBuffer();
            try fc(buffer, .{ .character = state.ch, .dataptr = self.dataptr });
        },
        .setmod => |mode| {
            root.log(@src(), .debug, "setting mode {s}", .{mode.toString()});
            const buffer = state.getCurrentBuffer();
            buffer.setMode(mode);
        },
    };
}

const FunctionAction = union(enum) {
    lua_function: lua.LuaRef,
    setmod: km.ModeId,
    state: *const fn (*State, km.KeyFunctionDataValue) anyerror!void,
    buffer: *const fn (*Buffer, km.KeyFunctionDataValue) anyerror!void,
};
