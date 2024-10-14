const root = @import("root");
const std = @import("std");
const scu = root.scu;

const mem = std.mem;
const luajitsys = root.luajitsys;

const State = @import("State.zig");
const Config = @import("Config.zig");

pub const LuaState = luajitsys.lua_State;

pub fn init() *LuaState {
    root.log(@src(), .debug, "creating lua state", .{});

    const L = luajitsys.luaL_newstate() orelse unreachable;
    luajitsys.luaL_openlibs(L);

    // Neomacs Object
    pushStruct(L, .{
        .api = .{
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
        },
        .buf = .{
            // .getName = nluaGetName
            // .create = nluaCreate(focus, )
        },
        .opt = Config{},
        .keymap = .{
            .del = nluaKeymapDel,
            .set = nluaKeymapSet,
        },
        .cmd = .{
            .w = nluaWrite,
            .q = nluaQuit,
            .wq = nluaWriteQuit,
            // .help = nluaHelp,
            // .tutor = nluaTutor,
        },
        .notify = nluaNotify,
        .print = nluaPrint,
        .treesitter = .{},
        // .schedule = nluaSchedule
    });
    luajitsys.lua_setglobal(L, "neomacs");

    // overwrite print implementation
    luajitsys.lua_pushcfunction(L, luaPrint);
    luajitsys.lua_setglobal(L, "print");

    // TODO: patch require(...) to a different function for profiling

    return L;
}

pub fn deinit(L: *LuaState) void {
    luajitsys.lua_close(L);
}

pub fn runInit(L: *LuaState) !void {
    root.log(@src(), .debug, "running lua state", .{});

    const sysinit = @embedFile("sysinit.lua");
    if (luajitsys.luaL_loadstring(L, sysinit) != 0)
        unreachable; // embeded file is always the same

    if (luajitsys.lua_pcall(L, 0, luajitsys.LUA_MULTRET, 0) != 0) {
        const c = luajitsys.lua_tolstring(L, -1, null);
        std.log.err("{s}", .{c});
        return error.LuaError;
    }
}

pub fn pushStruct(L: *LuaState, comptime value: anytype) void {
    const Value = @TypeOf(value);
    const typeInfo: std.builtin.Type = @typeInfo(Value);

    luajitsys.lua_newtable(L);

    // const v = Value{};
    inline for (typeInfo.Struct.fields) |field| {
        const f = @field(value, field.name);
        if (comptime std.mem.eql(u8, field.name, "__metatable")) {
            pushStruct(L, f);
            _ = luajitsys.lua_setmetatable(L, -2);
        } else {
            switch (@typeInfo(field.type)) {
                .ComptimeInt, .Int => luajitsys.lua_pushinteger(L, f),
                .Bool => luajitsys.lua_pushboolean(L, @intFromBool(f)),
                .Struct => pushStruct(L, f),
                .Fn => luajitsys.lua_pushcfunction(L, f),
                .Enum => {
                    const name = @tagName(f);
                    luajitsys.lua_pushlstring(L, name.ptr, name.len);
                },
                else => unreachable,
            }
            luajitsys.lua_setfield(L, -2, field.name);
        }
    }
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

fn stateWrite() void {
    root.log(@src(), .info, "[zig] Should write", .{});
}

fn nluaQuit(L: ?*LuaState) callconv(.C) c_int {
    Config.set(L, "QUIT", true);
    return 0;
}

fn nluaWrite(_: ?*LuaState) callconv(.C) c_int {
    stateWrite();
    return 0;
}

fn nluaWriteQuit(L: ?*LuaState) callconv(.C) c_int {
    stateWrite();
    Config.set(L, "QUIT", true);
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
    const nargs = luajitsys.lua_gettop(L);

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
        luajitsys.lua_pop(L, 1);
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
    const ty = luajitsys.lua_type(L, idx);

    switch (ty) {
        luajitsys.LUA_TNIL => try state.buf.appendSlice("nil"),
        luajitsys.LUA_TFUNCTION => {
            try std.fmt.format(state.buf.writer(), "<function {}>", .{state.functionCount});
            state.functionCount += 1;
        },
        luajitsys.LUA_TTABLE => {
            try state.buf.appendSlice("{");

            state.indent += 2;

            // iter the table
            var first = true;
            luajitsys.lua_pushnil(L); // first key
            while (luajitsys.lua_next(L, -2) != 0) {
                if (first) {
                    try state.buf.append('\n');
                    first = false;
                } else {
                    try state.buf.appendSlice(",\n");
                }

                // uses 'key' (at index -2) and 'value' (at index -1)
                const key = luajitsys.lua_tolstring(L, -2, null); // may not be a string
                //
                try state.buf.appendNTimes(' ', state.indent);

                try std.fmt.format(state.buf.writer(), "{s}: ", .{key});

                neomacsPrintInner(L, -1, state) catch unreachable;
                // removes 'value'; keeps 'key' for next iteration
                luajitsys.lua_pop(L, 1);
            }

            state.indent -= 2;

            if (!first) {
                try state.buf.append('\n');
                try state.buf.appendNTimes(' ', state.indent);
            }

            try state.buf.appendSlice("}");
        },
        luajitsys.LUA_TNUMBER => {
            const val = luajitsys.lua_tonumber(L, idx);
            const v: isize = @intFromFloat(val);
            try std.fmt.format(state.buf.writer(), "{}", .{v});
        },
        luajitsys.LUA_TBOOLEAN => {
            const val = luajitsys.lua_toboolean(L, idx);
            try std.fmt.format(state.buf.writer(), "{}", .{val != 0});
        },
        luajitsys.LUA_TNONE => {},
        else => unreachable,
    }
}

// Creates the language into the internal language map.
//
// Returns true if the language is correctly loaded in the language map
// int tslua_add_language(lua_State *L)
// {
//   const char *path = luaL_checkstring(L, 1);
//   const char *lang_name = luaL_checkstring(L, 2);
//   const char *symbol_name = lang_name;
//
//   if (lua_gettop(L) >= 3 && !lua_isnil(L, 3)) {
//     symbol_name = luaL_checkstring(L, 3);
//   }
//
//   if (pmap_has(cstr_t)(&langs, lang_name)) {
//     lua_pushboolean(L, true);
//     return 1;
//   }
//
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
// }
//
