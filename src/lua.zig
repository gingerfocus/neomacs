const root = @import("root");
const std = @import("std");
const scu = root.scu;

const mem = std.mem;
const luajitsys = root.luajitsys;

pub const LuaState = luajitsys.lua_State;

pub fn init() *LuaState {
    const L = luajitsys.luaL_newstate() orelse unreachable;
    luajitsys.luaL_openlibs(L);

    // Main Neomacs Object
    pushStruct(L, .{
        .api = .{},
        .keymap = .{
            .set = nluaKeymapSet,
        },
        .cmd = .{
            .w = nluaWrite,
            .q = nluaQuit,
            .wq = nluaWriteQuit,
            // .help = nluaHelp,
            // .tutor = nluaTutor,
        },
        .opt = .{
            .relativelines = true,
            .scrolloff = 8,
        },
        .notify = nluaNotify,
        .print = nluaPrint,
        // ._treesitter = .{},
        // .schedule = nlua_schedule
        // .in_fast_event = nlua_in_fast_event
        // .call = nlua_call
        // .rpcrequest = nlua_rpcrequest,
        // .rpcnotify = nlua_rpcnotify,
        // .wait = nlua_wait,
        // .ui_attach = nlua_ui_attach,
        // .ui_detach = nlua_ui_detach,
    });
    luajitsys.lua_setglobal(L, "neomacs");

    // overwrite print implementation
    luajitsys.lua_pushcfunction(L, luaPrint);
    luajitsys.lua_setglobal(L, "print");

    // TODO: patch require(...) to a different function for profiling

    return L;
}

pub fn runInit(L: *LuaState) !void {
    var ret: c_int = undefined;

    const sysinit = @embedFile("sysinit.lua");
    ret = luajitsys.luaL_loadstring(L, sysinit);
    try luaError(L, ret);

    // ret = luajitsys.luaL_loadfile(L, "share/init.lua");
    // try luaError(L, ret);

    ret = luajitsys.lua_pcall(L, 0, luajitsys.LUA_MULTRET, 0);
    try luaError(L, ret);
}

fn luaError(L: *LuaState, ret: c_int) !void {
    if (ret != 0) {
        const c = luajitsys.lua_tolstring(L, -1, null);
        std.log.err("{s}", .{c});
        return error.LuaError;
    }
}

fn pushStruct(L: *LuaState, comptime value: anytype) void {
    const Value = @TypeOf(value);
    const typeInfo: std.builtin.Type = @typeInfo(Value);

    luajitsys.lua_newtable(L);

    // const v = Value{};
    inline for (typeInfo.Struct.fields) |field| {
        const f = @field(value, field.name);
        switch (@typeInfo(field.type)) {
            .ComptimeInt, .Int => luajitsys.lua_pushinteger(L, f),
            .Bool => luajitsys.lua_pushboolean(L, @intFromBool(f)),
            .Struct => pushStruct(L, f),
            .Fn => luajitsys.lua_pushcfunction(L, f),
            else => unreachable,
        }
        luajitsys.lua_setfield(L, -2, field.name);
    }
}

pub fn deinit(L: *LuaState) void {
    luajitsys.lua_close(L);
}

pub fn runCommand(L: *LuaState, cmd: [:0]const u8) !void {
    luajitsys.lua_getglobal(L, "neomacs");
    luajitsys.lua_getfield(L, -1, "cmd");
    luajitsys.lua_getfield(L, -1, cmd.ptr);

    const t = luajitsys.lua_type(L, -1);

    switch (t) {
        luajitsys.LUA_TFUNCTION => {
            const ret = luajitsys.lua_pcall(L, 0, 0, 0);
            if (ret != 0) return error.FunctionError;
            // try luaError(L, ret);
        },
        luajitsys.LUA_TNUMBER => {
            const n = luajitsys.lua_tonumber(L, -1);
            const num: i32 = @intFromFloat(n);
            std.log.info("[loop] got n: {}\n", .{num});
        },
        luajitsys.LUA_TNIL => {
            luajitsys.lua_pop(L, -1);
            std.log.warn("[loop] unknown key \"{s}\"\n", .{cmd});
        },
        else => {
            const name = luajitsys.lua_typename(L, luajitsys.lua_type(L, -1));
            std.log.err("[loop] unknown object type: {s}\n", .{mem.span(name)});
        },
    }

    // std.debug.print("[loop] ending loop\n", .{});
}

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

// pub var tt_string: [18][*:0]const u8 = [18][*:0]const u8{
//     "set_var",
//     "set_output",
//     "set_map",
//     "let",
//     "plus",
//     "minus",
//     "mult",
//     "div",
//     "echo",
//     "w",
//     "e",
//     "we",
//     "ident",
//     "special key",
//     "string",
//     "config var",
//     "int",
//     "float",
// };

// pub var ctrl_keys: [26]Ctrl_Key = [26]Ctrl_Key{
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-a>".*;
//         }).static,
//         .value = @as(c_int, 'a') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-b>".*;
//         }).static,
//         .value = @as(c_int, 'b') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-c>".*;
//         }).static,
//         .value = @as(c_int, 'c') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-d>".*;
//         }).static,
//         .value = @as(c_int, 'd') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-e>".*;
//         }).static,
//         .value = @as(c_int, 'e') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-f>".*;
//         }).static,
//         .value = @as(c_int, 'f') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-g>".*;
//         }).static,
//         .value = @as(c_int, 'g') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-h>".*;
//         }).static,
//         .value = @as(c_int, 'h') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-i>".*;
//         }).static,
//         .value = @as(c_int, 'i') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-j>".*;
//         }).static,
//         .value = @as(c_int, 'j') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-k>".*;
//         }).static,
//         .value = @as(c_int, 'k') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-l>".*;
//         }).static,
//         .value = @as(c_int, 'l') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-m>".*;
//         }).static,
//         .value = @as(c_int, 'm') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-n>".*;
//         }).static,
//         .value = @as(c_int, 'n') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-o>".*;
//         }).static,
//         .value = @as(c_int, 'o') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-p>".*;
//         }).static,
//         .value = @as(c_int, 'p') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-q>".*;
//         }).static,
//         .value = @as(c_int, 'q') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-r>".*;
//         }).static,
//         .value = @as(c_int, 'r') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-s>".*;
//         }).static,
//         .value = @as(c_int, 's') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-t>".*;
//         }).static,
//         .value = @as(c_int, 't') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-u>".*;
//         }).static,
//         .value = @as(c_int, 'u') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-v>".*;
//         }).static,
//         .value = @as(c_int, 'v') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-w>".*;
//         }).static,
//         .value = @as(c_int, 'w') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-x>".*;
//         }).static,
//         .value = @as(c_int, 'x') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-y>".*;
//         }).static,
//         .value = @as(c_int, 'y') & @as(c_int, 31),
//     },
//     Ctrl_Key{
//         .name = &(struct {
//             var static = "<ctrl-z>".*;
//         }).static,
//         .value = @as(c_int, 'z') & @as(c_int, 31),
//     },
// };

fn stateWrite() void {
    root.log(@src(), .info, "[zig] Should write", .{});
}

fn nluaQuit(_: ?*LuaState) callconv(.C) c_int {
    root.state.config.QUIT = true;
    return 0;
}

fn nluaWrite(_: ?*const LuaState) callconv(.C) c_int {
    stateWrite();
    return 0;
}

fn nluaWriteQuit(_: ?*const LuaState) callconv(.C) c_int {
    stateWrite();
    root.state.config.QUIT = true;
    return 0;
}

// if (lua.lua_type(L, 1) != lua.LUA_TFUNCTION) {
//     const msg = "vim.schedule: expected function";
//     lua.lua_pushlstring(L, msg.ptr, msg.len);
//     // makes a lua error
//     return lua.lua_error(L);
// }

// LuaRef cb = nlua_ref_global(lstate, 1);

// multiqueue_put(main_loop.events, nlua_schedule_event,
//                1, (void *)(ptrdiff_t)cb);
fn nluaHelp(L: ?*LuaState) callconv(.C) c_int {
    const file = scu.log.getFile() orelse return 1;

    luajitsys.lua_getglobal(L, "neomacs");
    std.debug.assert(luajitsys.lua_istable(L, -1));

    luajitsys.lua_getfield(L, -1, "cmd");
    std.debug.assert(luajitsys.lua_istable(L, -1));

    root.log(@src(), .info, "[zig] globals:", .{});

    luajitsys.lua_pushnil(L); // first key
    while (luajitsys.lua_next(L, -2) != 0) {
        // uses 'key' (at index -2) and 'value' (at index -1)
        const key = luajitsys.lua_tolstring(L, -2, null); // may not be a string
        const val = luajitsys.lua_typename(L, luajitsys.lua_type(L, -1));

        std.fmt.format(file.writer(), "\t- {s}: {s}\n", .{ mem.span(key), mem.span(val) }) catch unreachable;
        // removes 'value'; keeps 'key' for next iteration
        luajitsys.lua_pop(L, 1);
    }
    return 0;
}

fn nluaNotify(L: ?*LuaState) callconv(.C) c_int {
    // const n = luajitsys.lua_gettop(L);
    if (luajitsys.lua_isstring(L, 1) != 0) {
        // TODO: error
        return 0;
    }

    var len: usize = undefined;
    const str = luajitsys.lua_tolstring(L, 1, &len);
    std.log.info("notify: {s}", .{str[0..len]});

    return 0;
}

// luajitsys.lua_touserdata();
// luajitsys.lua_newuserdata();

/// Unpretty print, emulates default print function but just changes output
fn luaPrint(L: ?*LuaState) callconv(.C) c_int {
    const nargs = luajitsys.lua_gettop(L);

    const a = std.heap.c_allocator;
    var buf = std.ArrayList(u8).initCapacity(a, 80) catch unreachable;
    defer buf.deinit();

    luajitsys.lua_getglobal(L, "tostring");

    // root.log(@src(), .info, "[zig] printing...", .{});

    var curargidx: c_int = 1;
    while (curargidx <= nargs) : (curargidx += 1) {
        luajitsys.lua_pushvalue(L, -1); // tostring
        luajitsys.lua_pushvalue(L, curargidx); // arg
        //
        if (luajitsys.lua_pcall(L, 1, 1, 0) != 0) {
            var errmsg_len: usize = undefined;
            const errmsg = luajitsys.lua_tolstring(L, -1, &errmsg_len);
            return printError(L, curargidx, errmsg[0..errmsg_len]);
        }

        var len: usize = undefined;
        const s = luajitsys.lua_tolstring(L, -1, &len);
        if (s == null) {
            return printError(L, curargidx, "<Unknown error: lua_tolstring returned NULL for tostring result>");
        }

        buf.appendSlice(s[0..len]) catch unreachable;
        if (curargidx < nargs) {
            buf.append(' ') catch unreachable;
        }
        luajitsys.lua_pop(L, 1);
    }

    std.log.info("[lua] {s}", .{buf.items});
    return 0;
}

fn printError(L: ?*LuaState, idx: c_int, msg: []const u8) c_int {
    const a = std.heap.c_allocator;

    const fmtmsg = std.fmt.allocPrint(
        a,
        "E5114: Error while converting print argument #{}: {s}",
        .{ idx, msg },
    ) catch unreachable;
    defer a.free(fmtmsg);

    luajitsys.lua_pushlstring(L, msg.ptr, msg.len);
    return luajitsys.lua_error(L);
}

fn nluaKeymapSet(L: ?*LuaState) callconv(.C) c_int {
    root.log(@src(), .info, "neomacs.keymap.set not implemented", .{});
    _ = L; // autofix
    return 0;
}

/// Pretty print
/// vim.print
fn nluaPrint(L: ?*LuaState) callconv(.C) c_int {
    if (true) return 0;

    const nargs = luajitsys.lua_gettop(L);

    const a = std.heap.c_allocator;

    var buf = std.ArrayList(u8).initCapacity(a, 80) catch unreachable;
    defer buf.deinit();

    var curargidx: c_int = 1;
    while (curargidx <= nargs) : (curargidx += 1) {
        neomacsPrintInner(L, curargidx, 0) catch return 0;
        luajitsys.lua_pop(L, 1);
    }

    std.log.info("print: {s}", .{buf.items});
    return 0;
}

fn neomacsPrintInner(L: *LuaState, buf: *std.ArrayList(u8), idx: c_int, indent: usize) !void {
    const ty = luajitsys.lua_type(L, idx);

    switch (ty) {
        luajitsys.LUA_TNIL => try buf.appendSlice("nil"),

        //         luajitsys.LUA_TFUNCTION => return .Function,
        luajitsys.LUA_TTABLE => {
            buf.appendNTimes(' ', indent);
            buf.appendSlice("{\n");
            // iter the table
            // for (field) {
            //     neomacsPrintInner(L, -1, indent + 2) catch return 0;
            // }
        },
        else => unreachable,
    }
}
