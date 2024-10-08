const root = @import("root");
const std = @import("std");

const mem = std.mem;
const luajitsys = root.luajitsys;

pub const State = luajitsys.lua_State;

// fn stateWrite() void {
//     std.debug.print("[zig] Should write\n", .{});
// }
//
// fn stateQuit() void {
//     state.run = false;
//     std.debug.print("[zig] Should quit\n", .{});
// }
//
// fn nluaQuit(L: ?*LuaState) callconv(.C) c_int {
//     stateQuit();
//
//     if (lua.lua_type(L, 1) != lua.LUA_TFUNCTION) {
//         const msg = "vim.schedule: expected function";
//         lua.lua_pushlstring(L, msg.ptr, msg.len);
//         // makes a lua error
//         return lua.lua_error(L);
//     }
//
//     // LuaRef cb = nlua_ref_global(lstate, 1);
//
//     // multiqueue_put(main_loop.events, nlua_schedule_event,
//     //                1, (void *)(ptrdiff_t)cb);
//
//     return 0;
// }
//
// fn nluaWrite(L: ?*const LuaState) callconv(.C) c_int {
//     _ = L;
//     stateWrite();
//     return 0;
// }
//
// fn nluaWriteQuit(L: ?*const LuaState) callconv(.C) c_int {
//     _ = L;
//     stateWrite();
//     stateQuit();
//     return 0;
// }
//
// fn nluaHelp(L: ?*LuaState) callconv(.C) c_int {
//     lua.lua_getglobal(L, "cmd");
//
//     std.debug.assert(lua.lua_istable(L, -1));
//
//     std.debug.print("[zig] globals:\n", .{});
//     lua.lua_pushnil(L); // first key
//     while (lua.lua_next(L, -2) != 0) {
//         // uses 'key' (at index -2) and 'value' (at index -1)
//         const key = lua.lua_tolstring(L, -2, null); // may not be a string
//         const val = lua.lua_typename(L, lua.lua_type(L, -1));
//
//         std.debug.print("\t- {s}: {s}\n", .{ mem.span(key), mem.span(val) });
//         // removes 'value'; keeps 'key' for next iteration
//         lua.lua_pop(L, 1);
//     }
//     return 0;
// }
//
// fn luaError(L: *LuaState, ret: c_int) !void {
//     if (ret != 0) {
//         const c = lua.lua_tolstring(L, -1, null);
//         std.debug.print("error: {s}\n", .{std.mem.span(c)});
//         return error.LuaError;
//     }
// }

pub fn init() !*State {
    const L = luajitsys.luaL_newstate() orelse {
        // TODO: this might be unreachable I am not sure
        root.log(@src(), .err, "Cant init lua\n", .{});
        // return error.CantInitLua;
        return error.LuaInitState;
    };
    luajitsys.luaL_openlibs(L);

    luajitsys.lua_newtable(L); // cmd

    // lua.lua_pushcfunction(L, &nluaQuit);
    // lua.lua_setfield(L, -2, "q");
    //
    // lua.lua_pushcfunction(L, &nluaWrite);
    // lua.lua_setfield(L, -2, "w");
    //
    // lua.lua_pushcfunction(L, &nluaWriteQuit);
    // lua.lua_setfield(L, -2, "wq");
    //
    // lua.lua_pushcfunction(L, &nluaHelp);
    // lua.lua_setfield(L, -2, "help");
    //
    // lua.lua_pushnumber(L, 1.0);
    // lua.lua_setfield(L, -2, "scale");
    //
    // lua.lua_pushinteger(L, 3);
    // lua.lua_setfield(L, -2, "score");
    //
    // lua.lua_pushstring(L, "John Smith");
    // lua.lua_setfield(L, -2, "name");

    luajitsys.lua_setglobal(L, "cmd");
    return L;
}

pub fn deinit(L: *State) void {
    luajitsys.lua_close(L);
}

// const State = struct { run: bool };
// var state: State = State{ .run = true };
//
// fn commandRoutine(L: *LuaState) !void {
//     while (state.run) {
//         const r = std.io.getStdIn().reader();
//         var buf: [256]u8 = undefined;
//         const str = try r.readUntilDelimiter(&buf, '\n');
//
//         buf[str.len] = 0; // null terminate
//         lua.lua_getglobal(L, "cmd");
//         lua.lua_getfield(L, -1, str.ptr);
//         const t = lua.lua_type(L, -1);
//
//         switch (t) {
//             lua.LUA_TFUNCTION => {
//                 const ret = lua.lua_pcall(L, 0, 0, 0);
//                 try luaError(L, ret);
//             },
//             lua.LUA_TNUMBER => {
//                 const n = lua.lua_tonumber(L, -1);
//                 const num: i32 = @intFromFloat(n);
//                 std.debug.print("[loop] got n: {}\n", .{num});
//             },
//             lua.LUA_TNIL => {
//                 lua.lua_pop(L, -1);
//                 std.debug.print("[loop] unknown key \"{s}\"\n", .{str});
//             },
//             else => {
//                 const name = lua.lua_typename(L, lua.lua_type(L, -1));
//                 std.debug.print("[loop] unknown object type: {s}\n", .{mem.span(name)});
//             },
//         }
//
//         // std.debug.print("[loop] ending loop\n", .{});
//     }
// }
//
// fn runFile(L: *LuaState) !void {
//     var ret: c_int = 0;
//     ret = lua.luaL_loadfile(L, "lua/test.lua");
//     try luaError(L, ret);
//
//     ret = lua.lua_pcall(L, 0, lua.LUA_MULTRET, 0);
//     try luaError(L, ret);
//
//     // ret = lua.luaL_dofile(L, "lua/test.lua");
//     // try luaError(L, ret);
// }
