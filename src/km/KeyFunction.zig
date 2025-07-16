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

// TODO: move to lua file
pub const LuaRef = c_int;

pub const KeyDataPtr = lib.types.TypeErasedData;
// pub const KeyDataPtr = anyopaque;

dataptr: ?*lib.types.TypeErasedData = null,
function: FunctionAction,

const Self = @This();

pub fn initstate(func: *const fn (*State, ?*KeyDataPtr) anyerror!void) Self {
    return .{
        .function = .{ .state = func },
    };
}

pub fn initbuffer(func: *const fn (*Buffer, ?*KeyDataPtr) anyerror!void) Self {
    return .{
        .function = .{ .buffer = func },
    };
}

pub fn initlua(L: ?*lua.State, index: LuaRef) !Self {
    if (lua.sys.lua_type(L, index) != lua.sys.LUA_TFUNCTION) {
        return error.NotALuaFunction;
    }

    lua.sys.lua_pushvalue(L, index);
    const ref = lua.sys.luaL_ref(L, lua.sys.LUA_REGISTRYINDEX);
    if (ref <= 0) return error.CantMakeReference;

    return .{
        .function = .{ .LuaFnc = ref },
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
        .LuaFnc => |id| {
            lua.sys.luaL_unref(L, lua.sys.LUA_REGISTRYINDEX, id);
        },
        else => {},
    }
}

pub fn run(self: Self, state: *State) anyerror!void {
    return switch (self.function) {
        .state => |fc| {
            // const buffer = state.getCurrentBuffer();
            // buffer.curkeymap = null;

            try fc(state, self.dataptr);
        },
        .LuaFnc => |id| {
            std.debug.assert(id > 0);

            lua.sys.lua_rawgeti(state.L, lua.sys.LUA_REGISTRYINDEX, id);

            if (lua.sys.lua_pcall(state.L, 0, 0, 0) != 0) {
                // nlua_error(lstate, _("Error executing vim.schedule lua callback: %.*s"));
                return error.ExecuteLuaCallback;
            }

            // const buffer = state.getCurrentBuffer();
            // buffer.curkeymap = null;
        },
        .buffer => |fc| {
            const buffer = state.getCurrentBuffer();
            buffer.curkeymap = null;
            try fc(buffer, self.dataptr);
        },

        .setmod => |mode| {
            const buffer = state.getCurrentBuffer();
            buffer.setMode(mode);

            // std.debug.print("set mode: {any}\n", .{mode});
            // km.debuginner(buffer.curkeymap.?, 1);

            // std.log.debug("keys: {any}", .{buffer.curkeymap.?.keys.keys()});
        },
    };
}

const FunctionAction = union(enum) {
    LuaFnc: LuaRef,
    setmod: km.ModeId,
    state: *const fn (*State, ?*KeyDataPtr) anyerror!void,
    buffer: *const fn (*Buffer, ?*KeyDataPtr) anyerror!void,
};
