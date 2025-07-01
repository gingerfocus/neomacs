//! TODO: Fully modular system for keymaps
//! Dont have the nuance of reference counting escape this file

const root = @import("root.zig");
const std = root.std;
const scu = root.scu;
const trm = root.trm;
const lua = root.lua;

const State = root.State;

const rc = @import("zigrc");

const MapId = usize;

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

    pub fn none(_: *State) !void {}
};


pub const KeyMapings = std.AutoArrayHashMapUnmanaged(u16, KeyMap);

pub const KeyMaps = struct {
    keys: KeyMapings = .{},
    fallback: ?KeyMap = null,
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

            try self.targeter(state);
        } else if (self.fallback) |fallback| {
            // if there is no handler and its just a regular key then send it to
            // the buffer
            try fallback.run(state);
        }
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
                .LuaFnc => |id| {
                    // TODO: unref global
                    _ = id;
                },
                else => {},
            }
        }
        const map = try a.create(KeyMaps);
        map.* = KeyMaps{};
        res.value_ptr.* = KeyMap{ .SubMap = map };
        return map;
    }
};

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
