// https://raw.githubusercontent.com/daurnimator/zig-autolua/refs/heads/master/src/autolua.zig

// TODO: this file should have an event pipe to the main state and then it
// sends its requests back. Managing a global state is hard. :<

const root = @import("root.zig");

const std = @import("std");
const mem = std.mem;
const scu = root.scu;
const lua = @This();

const Config = @import("Config.zig");
const Global = @import("State.zig");

// pub const sys = @cImport({
//     @cInclude("lua.h");
//     @cInclude("lualib.h");
//     @cInclude("luajit.h");
//     @cInclude("luajit-2.1/lauxlib.h");
// });
pub const sys = @import("syslua");

pub const LuaState = sys.lua_State;

pub fn init() *LuaState {
    root.log(@src(), .debug, "creating lua state", .{});

    const L = sys.luaL_newstate() orelse unreachable;
    sys.luaL_openlibs(L);

    // Neomacs Object
    push(L, .{
        .ui = .{
            .input = nluaUiInput,
        },
        .loop = .{
            .stat = nluaLoopStat,
        },
        .api = .{},
        .win = .{
            .open = nluaWinOpen,
        },
        // .pkg = .{},
        .buf = .{
            // .getName = nluaGetName
            // .create = nluaCreate(focus, )
        },
        .opt = .{
            .__metatable = .{
                .__index = nluaOptIndex,
                .__newindex = nluaOptNewIndex,
            },
        },
        .keymap = .{
            .del = nluaKeymapDel,
            .set = nluaKeymapSet,
        },
        .cmd = .{
            .w = nluaWrite,
            .q = nluaQuit,
            .wq = nluaWriteQuit,
            .e = nluaEdit,
            // .help = nluaHelp,
            // .tutor = nluaTutor,
            .bn = nluaBufferNext,
            .bp = nluaBufferPrev,
        },
        .notify = nluaNotify,
        .print = nluaPrint,
        .treesitter = .{},
        // .schedule = nluaSchedule
    });
    sys.lua_setglobal(L, "neomacs");

    // overwrite print implementation
    sys.lua_pushcfunction(L, luaPrint);
    sys.lua_setglobal(L, "print");

    // TODO: patch require(...) to a different function for profiling

    // -----------------
    root.log(@src(), .debug, "running init.lua state", .{});

    const SYSINIT = @embedFile("embed.lua");

    if (sys.luaL_loadstring(L, SYSINIT) != 0)
        unreachable; // embeded file is always the same

    if (sys.lua_pcall(L, 0, sys.LUA_MULTRET, 0) != 0) {
        var len: usize = undefined;
        const c = sys.lua_tolstring(L, -1, &len);
        root.log(@src(), .err, "could not run lua init:\n {s}", .{c[0..len]});
    }
    // -----------------

    return L;
}

pub fn deinit(L: *LuaState) void {
    sys.lua_close(L);
}

pub fn push(L: ?*LuaState, value: anytype) void {
    const Value = @TypeOf(value);
    const typeInfo = @typeInfo(Value);

    switch (typeInfo) {
        .comptime_int => sys.lua_pushinteger(L, value),
        .int => |int| {
            if (int.bits <= 32) sys.lua_pushinteger(L, value) //
            else sys.lua_pushnumber(L, @floatFromInt(value));
        },
        .bool => sys.lua_pushboolean(L, @intFromBool(value)),
        .@"struct" => {
            sys.lua_newtable(L);

            inline for (typeInfo.@"struct".fields) |field| {
                const f = @field(value, field.name);

                push(L, f);

                if (comptime std.mem.eql(u8, field.name, "__metatable")) {
                    _ = sys.lua_setmetatable(L, -2);
                } else {
                    sys.lua_setfield(L, -2, field.name);
                }
            }
        },
        .@"fn" => sys.lua_pushcfunction(L, value),
        .@"enum" => {
            const name = @tagName(value);
            sys.lua_pushlstring(L, name.ptr, name.len);
        },
        .pointer => {
            if (Value == *anyopaque) {
                sys.lua_pushlightuserdata(L, value);
                return;
            }
            if (Value == []const u8) {
                sys.lua_pushlstring(L, value.ptr, value.len);
                return;
            }
            @compileError("unable to push type: " ++ @typeName(Value));
        },
        else => @compileError("unable to push type: " ++ @typeName(Value)),
    }
}

var static: [256]u8 = undefined;
fn tmpCString(str: []const u8) [:0]const u8 {
    @memcpy(static[0..str.len], str);
    static[str.len] = 0;
    return static[0..str.len :0];
}

pub fn runCommand(L: *LuaState, cmd: [:0]const u8) !void {
    var iter = std.mem.splitScalar(u8, cmd, ' ');

    // var isCommand = true;
    // for (cmd) |c| {
    //     if (!std.ascii.isAlphabetic(c)) {
    //         isCommand = false;
    //         break;
    //     }
    // }

    if (cmd[0] == '?') {
        if (sys.luaL_loadstring(L, cmd[1..]) != 0) {
            std.log.warn("[loop] unknown key or syntax \"{s}\"", .{cmd});
            return error.SyntaxError;
        }

        if (sys.lua_pcall(L, 0, 0, 0) != 0) {
            return error.CodeError;
        }
        return;
    }
    // return true;
    // const isCommand = all(u8, cmd, std.ascii.isAlphabetic);
    // if (std.mem.indexOfScalarPos(u8, cmd, 0, ' ')) |_| isCommand = false;

    // if (isCommand) {
    const zfunc = iter.next() orelse return;
    const func: [:0]const u8 = tmpCString(zfunc);

    sys.lua_getglobal(L, "neomacs");
    sys.lua_getfield(L, -1, "cmd");
    sys.lua_getfield(L, -1, func.ptr);

    const t = sys.lua_type(L, -1);

    switch (t) {
        sys.LUA_TFUNCTION => {
            var nargs: c_int = 0;
            while (iter.next()) |zarg| {
                const arg = tmpCString(zarg);
                sys.lua_pushlstring(L, arg.ptr, arg.len);
                nargs += 1;
            }
            std.log.info("nargs: {d}", .{nargs});
            const ret = sys.lua_pcall(L, nargs, 0, 0);
            if (ret != 0) {
                var len: usize = undefined;
                const str = sys.lua_tolstring(L, -1, &len);
                root.log(@src(), .err, "{s}", .{str[0..len]});
                return error.FunctionError;
            }
            return;
        },
        sys.LUA_TNIL => {
            sys.lua_pop(L, -1);
            // fall through to the execute case
        },
        else => {
            const name = sys.lua_typename(L, sys.lua_type(L, -1));
            root.log(@src(), .err, "[loop] not a function, object type: {s}", .{mem.span(name)});
            return;
        },
    }

    std.log.warn("[loop] ending loop", .{});

    return;
}

// --- Lua Functions ---------------------------------------------------------

fn nluaQuit(_: ?*LuaState) callconv(.C) c_int {
    std.log.debug("quitting", .{});
    root.state().config.QUIT = true;
    return 0;
}

fn nluaWrite(_: ?*LuaState) callconv(.C) c_int {
    const state = root.state();

    const buffer = state.getCurrentBuffer() orelse return 0;
    buffer.save() catch |err| {
        root.log(@src(), .err, "could not save buffer {s}: {any}", .{ buffer.filename, err });
        return 0;
    };

    return 0;
}

fn nluaWriteQuit(s: ?*LuaState) callconv(.C) c_int {
    _ = nluaWrite(s);
    _ = nluaQuit(s);
    return 0;
}

fn nluaEdit(L: ?*lua.LuaState) callconv(.C) c_int {
    const state = root.state();

    const file = check(L, 1, []const u8) orelse {
        // TODO: make a prompt thing that requests it from the user
        return 0;
    };

    const buf = state.a.create(root.Buffer) catch return 0;
    buf.* = root.Buffer.initFile(state, file) catch {
        state.a.destroy(buf);
        root.log(@src(), .err, "File Not Found: {s}", .{file});
        return 0;
    };

    state.buffers.append(state.a, buf) catch return 0;
    state.buffer = state.buffers.items[state.buffers.items.len - 1];

    return 0;
}

fn nluaBufferNext(_: ?*LuaState) callconv(.C) c_int {
    root.state().bufferNext();
    return 0;
}

fn nluaBufferPrev(_: ?*LuaState) callconv(.C) c_int {
    root.state().bufferPrev();
    return 0;
}

// if (lua.lua_type(L, 1) != lua.LUA_TFUNCTION) {
//     const msg = "vim.schedule: expected function";
//     lua.lua_pushlstring(L, msg.ptr, msg.len);
//     // makes a lua error
//     return lua.lua_error(L);
// }

fn nluaHelp(L: ?*LuaState) callconv(.C) c_int {
    const file = scu.log.getFile() orelse return 1;

    sys.lua_getglobal(L, "neomacs");
    std.debug.assert(sys.lua_istable(L, -1));

    sys.lua_getfield(L, -1, "cmd");
    std.debug.assert(sys.lua_istable(L, -1));

    root.log(@src(), .info, "[zig] globals:", .{});

    sys.lua_pushnil(L); // first key
    while (sys.lua_next(L, -2) != 0) {
        // uses 'key' (at index -2) and 'value' (at index -1)
        const key = sys.lua_tolstring(L, -2, null); // may not be a string
        const val = sys.lua_typename(L, sys.lua_type(L, -1));

        std.fmt.format(file.writer(), "\t- {s}: {s}\n", .{ mem.span(key), mem.span(val) }) catch unreachable;
        // removes 'value'; keeps 'key' for next iteration
        sys.lua_pop(L, 1);
    }
    return 0;
}

fn nluaNotify(L: ?*LuaState) callconv(.C) c_int {
    // const n = luajitsys.lua_gettop(L);
    if (sys.lua_isstring(L, 1) != 0) {
        // TODO: error
        return 0;
    }

    var len: usize = undefined;
    const str = sys.lua_tolstring(L, 1, &len);
    std.log.info("notify: {s}", .{str[0..len]});

    return 0;
}

// luajitsys.lua_touserdata();
// luajitsys.lua_newuserdata();

/// Unpretty print, emulates default print function but just changes output
fn luaPrint(L: ?*LuaState) callconv(.C) c_int {
    const nargs = sys.lua_gettop(L);

    const a = std.heap.c_allocator;
    var buf = std.ArrayList(u8).initCapacity(a, 80) catch unreachable;
    defer buf.deinit();

    sys.lua_getglobal(L, "tostring");

    // root.log(@src(), .info, "[zig] printing...", .{});

    var curargidx: c_int = 1;
    while (curargidx <= nargs) : (curargidx += 1) {
        sys.lua_pushvalue(L, -1); // tostring
        sys.lua_pushvalue(L, curargidx); // arg
        //
        if (sys.lua_pcall(L, 1, 1, 0) != 0) {
            var errmsg_len: usize = undefined;
            const errmsg = sys.lua_tolstring(L, -1, &errmsg_len);
            return printError(L, curargidx, errmsg[0..errmsg_len]);
        }

        var len: usize = undefined;
        const s = sys.lua_tolstring(L, -1, &len);
        if (s == null) {
            return printError(L, curargidx, "<Unknown error: lua_tolstring returned NULL for tostring result>");
        }

        buf.appendSlice(s[0..len]) catch unreachable;
        if (curargidx < nargs) {
            buf.append(' ') catch unreachable;
        }
        sys.lua_pop(L, 1);
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

    sys.lua_pushlstring(L, msg.ptr, msg.len);
    return sys.lua_error(L);
}

fn nluaKeymapDel(L: ?*LuaState) callconv(.C) c_int {
    root.log(@src(), .info, "neomacs.keymap.del not implemented", .{});
    _ = L; // autofix
    return 0;
}

fn nluaKeymapSet(L: ?*LuaState) callconv(.C) c_int {
    root.log(@src(), .info, "neomacs.keymap.set not implemented", .{});
    _ = L; // autofix
    return 0;
}

/// Pretty print
/// vim.print
fn nluaPrint(L: ?*LuaState) callconv(.C) c_int {
    const nargs = sys.lua_gettop(L);

    const a = std.heap.c_allocator;

    var buf = std.ArrayList(u8).initCapacity(a, 80) catch unreachable;
    defer buf.deinit();

    var state = PrintState{
        .buf = &buf,
        .indent = 0,
        .functionCount = 0,
    };

    var idx: c_int = 1;
    while (idx <= nargs) : (idx += 1) {
        neomacsPrintInner(L, idx, &state) catch return 0;
        sys.lua_pop(L, 1);
    }

    std.log.info("print: \n{s}", .{buf.items});
    return 0;
}

const PrintState = struct {
    indent: usize,
    buf: *std.ArrayList(u8),
    functionCount: usize,
};

fn neomacsPrintInner(L: ?*LuaState, idx: c_int, state: *PrintState) !void {
    const ty = sys.lua_type(L, idx);

    switch (ty) {
        sys.LUA_TNIL => try state.buf.appendSlice("nil"),
        sys.LUA_TSTRING => {
            var len: usize = undefined;
            const ptr = sys.lua_tolstring(L, idx, &len);
            try state.buf.appendSlice(ptr[0..len]);
        },
        sys.LUA_TFUNCTION => {
            try std.fmt.format(state.buf.writer(), "<function {}>", .{state.functionCount});
            state.functionCount += 1;
        },
        sys.LUA_TTABLE => {
            try state.buf.appendSlice("{");

            state.indent += 2;

            // iter the table
            var first = true;
            sys.lua_pushnil(L); // first key
            while (sys.lua_next(L, -2) != 0) {
                if (first) {
                    try state.buf.append('\n');
                    first = false;
                } else {
                    try state.buf.appendSlice(",\n");
                }

                // uses 'key' (at index -2) and 'value' (at index -1)
                const key = sys.lua_tolstring(L, -2, null); // may not be a string
                //
                try state.buf.appendNTimes(' ', state.indent);

                try std.fmt.format(state.buf.writer(), "{s}: ", .{key});

                neomacsPrintInner(L, -1, state) catch unreachable;
                // removes 'value'; keeps 'key' for next iteration
                sys.lua_pop(L, 1);
            }

            state.indent -= 2;

            if (!first) {
                try state.buf.append('\n');
                try state.buf.appendNTimes(' ', state.indent);
            }

            try state.buf.appendSlice("}");
        },
        sys.LUA_TNUMBER => {
            const val = sys.lua_tonumber(L, idx);
            const v: isize = @intFromFloat(val);
            try std.fmt.format(state.buf.writer(), "{}", .{v});
        },
        sys.LUA_TBOOLEAN => {
            const val = sys.lua_toboolean(L, idx);
            try std.fmt.format(state.buf.writer(), "{}", .{val != 0});
        },
        sys.LUA_TNONE => {},
        else => unreachable,
    }
}

// Creates the language into the internal language map.
//
// Returns true if the language is correctly loaded in the language map
// int tslua_add_language(lua_State *L)
fn tsLuaAddLanguage(L: ?*LuaState) callconv(.C) c_int {
    const path = check(L, 1, []const u8) orelse return 0;
    const lang_name = check(L, 2, []const u8) orelse return 0;
    const symbol_name = check(L, 3, []const u8) orelse return 0;

    _ = path; // autofix
    _ = symbol_name; // autofix

    const state = root.state();

    for (state.tsmap) |*lang| {
        if (std.mem.eql(u8, lang.name, lang_name)) {
            root.log(@src(), .info, "language already loaded: {s}", .{lang_name});

            push(L, true);
            return 1;
        }
    }

    // put(
    //     root.state().a,
    //     mem.span(lang_name),
    //     mem.span(path),
    // ) catch return 0;

    // #define BUFSIZE 128
    //   char symbol_buf[BUFSIZE];
    //   snprintf(symbol_buf, BUFSIZE, "tree_sitter_%s", symbol_name);
    // #undef BUFSIZE
    //
    //   uv_lib_t lib;
    //   if (uv_dlopen(path, &lib)) {
    //     snprintf(IObuff, IOSIZE, "Failed to load parser for language '%s': uv_dlopen: %s",
    //              lang_name, uv_dlerror(&lib));
    //     uv_dlclose(&lib);
    //     lua_pushstring(L, IObuff);
    //     return lua_error(L);
    //   }
    //
    //   TSLanguage *(*lang_parser)(void);
    //   if (uv_dlsym(&lib, symbol_buf, (void **)&lang_parser)) {
    //     snprintf(IObuff, IOSIZE, "Failed to load parser: uv_dlsym: %s",
    //              uv_dlerror(&lib));
    //     uv_dlclose(&lib);
    //     lua_pushstring(L, IObuff);
    //     return lua_error(L);
    //   }
    //
    //   TSLanguage *lang = lang_parser();
    //   if (lang == NULL) {
    //     uv_dlclose(&lib);
    //     return luaL_error(L, "Failed to load parser %s: internal error", path);
    //   }
    //
    //   uint32_t lang_version = ts_language_version(lang);
    //   if (lang_version < TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION
    //       || lang_version > TREE_SITTER_LANGUAGE_VERSION) {
    //     return luaL_error(L,
    //                       "ABI version mismatch for %s: supported between %d and %d, found %d",
    //                       path,
    //                       TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION,
    //                       TREE_SITTER_LANGUAGE_VERSION, lang_version);
    //   }
    //
    //   pmap_put(cstr_t)(&langs, xstrdup(lang_name), lang);
    //
    //   lua_pushboolean(L, true);
    //   return 1;
}

pub fn is(L: ?*LuaState, idx: c_int, comptime T: type) bool {
    switch (@typeInfo(T)) {
        .void => return sys.lua_isnil(L, idx),
        .bool => return sys.lua_isboolean(L, idx),
        .int, .float => return sys.lua_isnumber(L, idx) != 0,
        .array => return sys.lua_istable(L, idx),
        .pointer => |ptrdata| {
            if (T == []const u8) {
                return sys.lua_isstring(L, idx) != 0;
            }

            _ = ptrdata;
            // if (T == *anyopaque) {
            //     return sys.lua_topointer(L, idx);
            // }

            @compileError("NYI");
        },
        .optional => |N| {
            if (sys.lua_isnoneornil(L, idx)) return true;
            return is(L, idx, N.child);
        },
        else => @compileError("unable to coerce to type: " ++ @typeName(T)),
    }
}

/// Gets idx as a type T, if you are not sure will match then use ?T
pub fn check(L: ?*LuaState, idx: c_int, comptime T: type) ?T {
    if (!is(L, idx, T)) {
        return null;
        // _ = sys.luaL_argerror(L, idx, "expected " ++ @typeName(T));
        // unreachable;
    }

    switch (@typeInfo(T)) {
        .void => return {},
        .bool => return sys.lua_toboolean(L, idx) != 0,
        .int => return @intCast(sys.lua_tointeger(L, idx)),
        .float => return @floatCast(sys.lua_tonumber(L, idx)),
        .array => |arr| {
            // assume it is a table
            var A: T = undefined;
            for (&A, 0..) |*p, i| {
                _ = sys.lua_geti(L, idx, @intCast(i + 1));
                p.* = check(L, -1, arr.child);
                sys.lua_pop(L, 1);
            }
            return A;
        },
        .pointer => |_| {
            if (T == *anyopaque) {
                return sys.lua_topointer(L, idx);
            }

            if (T == []const u8) {
                var len: usize = undefined;
                const ptr = sys.lua_tolstring(L, idx, &len);
                return ptr[0..len];
            }

            // const t = sys.lua_type(L, idx);
            // if (t != sys.LUA_TUSERDATA) {
            //     _ = sys.luaL_argerror(L, idx, "expected userdata");
            //     unreachable;
            // }

            // if (sys.lua_getmetatable(L, idx) == 0) {
            //     _ = sys.luaL_argerror(L, idx, "unexpected userdata metatable");
            //     unreachable;
            // }

            // TODO: check if metatable is valid for Pointer type
            @panic("unable to coerce to type: " ++ @typeName(T));

            // sys.lua_pop(L, 1);
            // const ptr = sys.lua_touserdata(L, idx);
            // return @as(T, @alignCast(@ptrCast(ptr)));
        },
        .optional => |N| {
            if (sys.lua_isnoneornil(L, idx)) {
                return null;
            }
            return check(L, idx, N.child);
        },
        else => @compileError("unable to coerce to type: " ++ @typeName(T)),
    }
}

// /// Wraps an arbitrary function in a Lua C-API using version
// pub fn wrap(comptime func: anytype) sys.lua_CFunction {
//     const Args: type = std.meta.ArgsTuple(@TypeOf(func));
//     // See https://github.com/ziglang/zig/issues/229
//     return struct {
//         fn thunk(L: ?*State) callconv(.C) c_int {
//             var args: Args = undefined;
//             comptime var i = 0;
//             inline while (i < args.len) : (i += 1) {
//                 args[i] = check(L, i + 1, @TypeOf(args[i]));
//             }
//             const result = @call(.auto, func, args);
//
//             if (@TypeOf(result) == void) {
//                 return 0;
//             } else {
//                 // state.push(result);
//                 return 0; // 1
//             }
//         }
//     }.thunk;
// }

// if (!luajitsys.lua_isboolean(L, VAL_INDEX)) return 0;
// const val = luajitsys.lua_toboolean(L, VAL_INDEX);

// if (luajitsys.lua_isnumber(L, VAL_INDEX) != 0) return 0;
// const val = luajitsys.lua_tonumber(L, VAL_INDEX); // val

fn nluaOptNewIndex(L: ?*LuaState) callconv(.C) c_int {
    // const TBL = 1;
    const KEY = 2;
    const VAL = 3;

    var len: usize = undefined;
    const ptr = sys.lua_tolstring(L, KEY, &len);
    const key = ptr[0..len];

    inline for (@typeInfo(Config).@"struct".fields) |field| {
        if (std.mem.eql(u8, field.name, key)) {
            const val = check(L, VAL, field.type) orelse return 0;

            @field(root.state().config, field.name) = val;

            root.log(@src(), .debug, "set({s}={any})", .{ field.name, val });

            return 0;
        }
    }

    root.log(@src(), .warn, "set(\"{s}\", ...): does not exist", .{key});

    // if (false) {
    //     lua.sys.lua_getglobal(L, "rawset");
    //     lua.sys.lua_pushvalue(L, TBL);
    //     lua.sys.lua_pushvalue(L, KEY);
    //     lua.sys.lua_pushvalue(L, VAL);
    //     if (lua.sys.lua_pcall(L, 3, 0, 0) != 0) {
    //         var errmsglen: usize = undefined;
    //         const errmsg = lua.sys.lua_tolstring(L, -1, &errmsglen);
    //         root.log(@src(), .err, "could not rawset: {s}", .{errmsg[0..errmsglen]});
    //         return 0;
    //     }
    // }

    return 0;
}

fn nluaOptIndex(L: ?*LuaState) callconv(.C) c_int {
    // const TBL = 1;
    const KEY = 2; // key

    var len: usize = undefined;
    const ptr = sys.lua_tolstring(L, KEY, &len);
    const key = ptr[0..len];

    root.log(@src(), .debug, "get(\"{s}\")", .{key});

    inline for (@typeInfo(Config).@"struct".fields) |field| {
        if (std.mem.eql(u8, field.name, key)) {
            const val = @field(root.state().config, field.name);
            push(L.?, val);
            return 1;
        }
    }

    // nothing found
    return 0;
}

const xev = root.xev;

fn callback(
    ud: ?*void,
    l: *xev.Loop,
    c: *xev.Completion,
    r: xev.Async.WaitError!void,
) xev.CallbackAction {
    _ = ud;
    _ = l;
    _ = c;
    r catch {};

    root.log(@src(), .warn, "callback", .{});
    return xev.CallbackAction.disarm;
}

fn nluaUiInput(L: ?*LuaState) callconv(.C) c_int {
    root.log(@src(), .debug, "ui.input", .{});

    const s = root.state();
    const as = xev.Async.init() catch unreachable;

    // xev.Stream.initFd()

    const c = s.a.create(xev.Completion) catch unreachable;
    as.wait(&s.loop, c, void, null, callback);

    s.inputcallback = .{ c, as };
    _ = L;

    return 0;
}

const FsStat = struct { size: u64, kind: []const u8 };

fn nluaLoopStat(L: ?*LuaState) callconv(.C) c_int {
    const file = check(L, 1, []const u8) orelse return 0;
    const stat = std.fs.cwd().statFile(file) catch return 0;
    push(L, FsStat{
        .size = stat.size,
        .kind = @tagName(stat.kind),
    });
    return 1;
}

fn nluaWinOpen(L: ?*LuaState) callconv(.C) c_int {
    _ = L;
    // local win_id = vim.api.nvim_open_win(
    //      bufnr, -- buf id
    //      true, -- focus on create
    //      {
    //     relative = "editor",
    //     title = "Harpoon",
    //     title_pos = toggle_opts.title_pos or "left",
    //     row = math.floor(((vim.o.lines - height) / 2) - 1),
    //     col = math.floor((vim.o.columns - width) / 2),
    //     width = width,
    //     height = height,
    //     style = "minimal",
    //     border = toggle_opts.border or "single",
    // })
    return 0;
}
