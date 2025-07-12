//! TODO: Fully modular system for keymaps
//! Dont have the nuance of reference counting escape this file

const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;
const lua = root.lua;
// const rc = @import("zigrc");

const State = root.State;

pub const ModeId = root.Buffer.ModeId;

pub const ModeToKeys = std.AutoArrayHashMapUnmanaged(ModeId, *KeyMaps);

pub const action = struct {
    pub fn move(state: *State) !void {
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

pub const KeyToFunction = std.AutoArrayHashMapUnmanaged(u16, KeyFunction);

pub const KeyMaps = struct {
    keys: KeyToFunction = .{},

    fallback: ?KeyFunction = null,
    targeter: ?KeyFunction = .{ .Native = action.move },

    name: ?[]const u8 = null,

    // use this as name instead of name
    // modeid: ModeId, 

    // Note: you can statically init this but just be sure to use the same
    // allocator for everything
    // pub fn init(name: ?[]const u8) KeyMaps {
    //     return .{
    //         .name = name,
    //     };
    // }

    pub fn deinit(self: *KeyMaps, a: std.mem.Allocator) void {
        var iter = self.keys.iterator();
        while (iter.next()) |key| key.value_ptr.deinit(a);

        if (self.name) |name| a.free(name);

        self.keys.deinit(a);
    }

    pub fn run(self: KeyMaps, state: *State, ke: trm.KeyEvent) !void {
        if (self.keys.get(trm.keys.bits(ke))) |function| {
            // if there is a custom handler then run it
            try function.run(state);

            if (self.targeter) |targeter| {
                if (targeter == .SubMap) {
                    std.log.debug("you cant set targeter as submap", .{});
                    return;
                }
                try targeter.run(state);
            }
        } else if (self.fallback) |fallback| {
            // if there is no handler and its just a regular key then send it to
            // the buffer
            try fallback.run(state);
        }
    }

    pub inline fn put(self: *KeyMaps, a: std.mem.Allocator, character: u16, value: KeyFunction) !void {
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
        res.value_ptr.* = KeyFunction{ .SubMap = map };
        return map;
    }
};

pub const KeyFunction = union(enum) {
    const Callback = *const fn (*State) anyerror!void; // Id
    const LuaRef = c_int;

    Native: Callback,
    LuaFnc: LuaRef,
    SubMap: *KeyMaps,

    pub fn deinit(self: KeyFunction, a: std.mem.Allocator) void {
        switch (self) {
            .SubMap => |map| {
                map.deinit(a);
                a.destroy(map);
            },
            else => {},
        }
    }

    pub fn initLua(L: *lua.LuaState, index: c_int) !KeyFunction {
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

    pub fn run(self: KeyFunction, state: *State) anyerror!void {
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
