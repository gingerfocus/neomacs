const std = @import("std");
const root = @import("root");

const lua = @import("lua.zig");
const scu = root.scu;
const luajitsys = root.luajitsys;

const State = @import("State.zig");

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

    pub fn initLua(L: *lua.LuaState, index: c_int) !KeyMap {
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

                luajitsys.lua_rawgeti(state.L, luajitsys.LUA_REGISTRYINDEX, id);
                luajitsys.luaL_unref(state.L, luajitsys.LUA_REGISTRYINDEX, id);
                // ref_state->ref_count--;

                if (luajitsys.lua_pcall(state.L, 0, 0, 0) != 0) {
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
