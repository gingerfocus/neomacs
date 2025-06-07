const std = @import("std");
const root = @import("root");
const trm = root.trm;

const lua = @import("lua.zig");
const scu = root.scu;

const State = @import("State.zig");

fn fallbackNone(_: *State) !void {
    // state.currentKeyMap = null;
}

pub const action = struct {
    fn move(state: *State) !void {
        try moveKeep(state);

        const buffer = state.getCurrentBuffer() orelse return;

        buffer.target = null; // reset the target
        state.currentKeyMap = null;
    }

    pub fn moveKeep(state: *State) !void {
        const buffer = state.getCurrentBuffer() orelse return;

        if (buffer.target) |target| {
            buffer.row = target.end.row;
            buffer.col = target.end.col;
        }
    }
};

pub const KeyMapings = std.AutoArrayHashMapUnmanaged(u16, KeyMap);
pub const KeyMaps = struct {
    keys: KeyMapings = .{},
    fallback: KeyMap = .{ .Native = fallbackNone },
    targeter: *const fn (*State) anyerror!void = action.move,

    pub fn deinit(self: *KeyMaps, a: std.mem.Allocator) void {
        var iter = self.keys.iterator();
        while (iter.next()) |key| key.value_ptr.deinit(a);

        self.keys.deinit(a);
    }

    pub fn run(self: KeyMaps, state: *State, ke: trm.KeyEvent) !void {
        if (self.keys.get(scu.thermit.keys.bits(ke))) |function| {
            // if there is a custom handler then run it
            try function.run(state);
        } else {
            // if there is no handler and its just a regular key then send it to
            // the buffer
            try self.fallback.run(state);
        }

        // TODO: I dont think this should run after a fallback
        try self.targeter(state);
    }

    pub inline fn put(self: *KeyMaps, a: std.mem.Allocator, character: u16, value: KeyMap) !void {
        try self.keys.put(a, character, value);
    }

    /// Gets the next
    pub fn then(self: *KeyMaps, a: std.mem.Allocator, character: u16) !*KeyMaps {
        const res = try self.keys.getOrPut(a, character);
        if (res.found_existing) {
            switch (res.value_ptr.*) {
                .SubMap => |map| return map,
                else => {},
            }
        }
        const map = try a.create(KeyMaps);
        map.* = .{};
        res.value_ptr.* = .{ .SubMap = map };
        return map;
    }
};

const Id = usize;

pub const KeyMap = union(enum) {
    const Callback = *const fn (*State) anyerror!void; // Id
    const LuaRef = c_int;

    Native: Callback,
    LuaFnc: LuaRef,
    SubMap: *KeyMaps,

    pub fn deinit(self: KeyMap, a: std.mem.Allocator) void {
        switch (self) {
            .SubMap => |map| {
                map.deinit(a);
                a.destroy(map);
            },
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
            .Native => |fc| {
                try fc(state);
                state.currentKeyMap = null;
            },
            .LuaFnc => |id| {
                std.debug.assert(id > 0);

                lua.sys.lua_rawgeti(state.L, lua.sys.LUA_REGISTRYINDEX, id);
                lua.sys.luaL_unref(state.L, lua.sys.LUA_REGISTRYINDEX, id);
                // ref_state->ref_count--;

                if (lua.sys.lua_pcall(state.L, 0, 0, 0) != 0) {
                    // nlua_error(lstate, _("Error executing vim.schedule lua callback: %.*s"));
                    return error.ExecuteLuaCallback;
                }
                state.currentKeyMap = null;
            },
            .SubMap => |map| {
                state.currentKeyMap = map;
                return;
            },
        }
    }
};
