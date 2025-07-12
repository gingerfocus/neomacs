pub const buf = @import("buf.zig");
pub const keymap = @import("keymap.zig");
pub const loop = @import("loop.zig");
pub const api = @import("api.zig");

// TODO: this file should have an event pipe to the main state and then it
// sends its requests back. Managing a global state is hard. :<

const root = @import("../root.zig");

const std = @import("std");
const mem = std.mem;

const lua = @import("../lua.zig");

/// Bindins to the Lua C API, either static or dynamic. This module abstracts
/// away the differences between the two.
pub const sys = @import("syslua");

// --- Lua Functions ---------------------------------------------------------

// if (lua.lua_type(L, 1) != lua.LUA_TFUNCTION) {
//     const msg = "vim.schedule: expected function";
//     lua.lua_pushlstring(L, msg.ptr, msg.len);
//     // makes a lua error
//     return lua.lua_error(L);
// }

fn nluaHelp(L: ?*lua.State) callconv(.C) c_int {
    sys.lua_getglobal(L, "neon");
    std.debug.assert(sys.lua_istable(L, -1));

    sys.lua_getfield(L, -1, "cmd");
    std.debug.assert(sys.lua_istable(L, -1));

    root.log(@src(), .info, "[zig] globals:", .{});

    sys.lua_pushnil(L); // first key
    while (sys.lua_next(L, -2) != 0) {
        // uses 'key' (at index -2) and 'value' (at index -1)
        const key = sys.lua_tolstring(L, -2, null); // may not be a string
        const val = sys.lua_typename(L, sys.lua_type(L, -1));

        std.log.info("\t- {s}: {s}", .{ mem.span(key), mem.span(val) });
        // removes 'value'; keeps 'key' for next iteration
        sys.lua_pop(L, 1);
    }
    return 0;
}

fn nluaNotify(L: ?*lua.State) callconv(.C) c_int {
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

// Creates the language into the internal language map.
//
// Returns true if the language is correctly loaded in the language map
// int tslua_add_language(lua_State *L)
fn tsLuaAddLanguage(L: ?*lua.State) callconv(.C) c_int {
    const path = lua.check(L, 1, []const u8) orelse return 0;
    const lang_name = lua.check(L, 2, []const u8) orelse return 0;
    const symbol_name = lua.check(L, 3, []const u8) orelse return 0;

    _ = path; // autofix
    _ = symbol_name; // autofix

    const state = root.state();

    for (state.tsmap) |*lang| {
        if (std.mem.eql(u8, lang.name, lang_name)) {
            root.log(@src(), .info, "language already loaded: {s}", .{lang_name});

            lua.check(L, true);
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

// if (!luajitsys.lua_isboolean(L, VAL_INDEX)) return 0;
// const val = luajitsys.lua_toboolean(L, VAL_INDEX);

// if (luajitsys.lua_isnumber(L, VAL_INDEX) != 0) return 0;
// const val = luajitsys.lua_tonumber(L, VAL_INDEX); // val

pub fn optNewIndex(L: ?*lua.State) callconv(.C) c_int {
    // const TBL = 1;
    const KEY = 2;
    const VAL = 3;

    var len: usize = undefined;
    const ptr = sys.lua_tolstring(L, KEY, &len);
    const key = ptr[0..len];

    inline for (@typeInfo(root.Config).@"struct".fields) |field| {
        if (std.mem.eql(u8, field.name, key)) {
            const val = lua.check(L, VAL, field.type) orelse return 0;

            @field(root.state().config, field.name) = val;

            const fmt = if (field.type == []const u8) "set({s}={s})" else "set({s}={any})";
            root.log(@src(), .debug, fmt, .{ field.name, val });

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

pub fn optIndex(L: ?*lua.State) callconv(.C) c_int {
    // const TBL = 1;
    const KEY = 2; // key

    var len: usize = undefined;
    const ptr = sys.lua_tolstring(L, KEY, &len);
    const key = ptr[0..len];

    root.log(@src(), .debug, "get(\"{s}\")", .{key});

    inline for (@typeInfo(root.Config).@"struct".fields) |field| {
        if (std.mem.eql(u8, field.name, key)) {
            const val = @field(root.state().config, field.name);
            lua.push(L.?, val);
            return 1;
        }
    }

    // nothing found
    return 0;
}

// const xev = root.xev;
// fn callback(
//     ud: ?*void,
//     l: *xev.Loop,
//     c: *xev.Completion,
//     r: xev.Async.WaitError!void,
// ) xev.CallbackAction {
//     _ = ud;
//     _ = l;
//     _ = c;
//     r catch {};
//
//     root.log(@src(), .warn, "callback", .{});
//     return xev.CallbackAction.disarm;
// }
// fn nluaUiInput(L: ?*lua.State) callconv(.C) c_int {
//     root.log(@src(), .debug, "ui.input", .{});
//
//     const s = root.state();
//     const as = xev.Async.init() catch unreachable;
//
//     // xev.Stream.initFd()
//
//     const c = s.a.create(xev.Completion) catch unreachable;
//     as.wait(&s.loop, c, void, null, callback);
//
//     s.inputcallback = .{ c, as };
//     _ = L;
//
//     return 0;
// }

fn nluaWinOpen(L: ?*lua.State) callconv(.C) c_int {
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

// luajitsys.lua_touserdata();
// luajitsys.lua_newuserdata();

/// Unpretty print, emulates default print function but just changes output
pub fn print(L: ?*lua.State) callconv(.C) c_int {
    const nargs = sys.lua_gettop(L);

    const a = std.heap.c_allocator;
    var nbuf = std.ArrayList(u8).initCapacity(a, 80) catch unreachable;
    defer nbuf.deinit();

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

        nbuf.appendSlice(s[0..len]) catch unreachable;
        if (curargidx < nargs) {
            nbuf.append(' ') catch unreachable;
        }
        sys.lua_pop(L, 1);
    }

    std.log.info("[lua] {s}", .{nbuf.items});
    return 0;
}

fn printError(L: ?*lua.State, idx: c_int, msg: []const u8) c_int {
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

fn nluaKeymapDel(L: ?*lua.State) callconv(.C) c_int {
    root.log(@src(), .info, "neomacs.keymap.del not implemented", .{});
    _ = L; // autofix
    return 0;
}

fn nluaKeymapSet(L: ?*lua.State) callconv(.C) c_int {
    root.log(@src(), .info, "neomacs.keymap.set not implemented", .{});
    _ = L; // autofix
    return 0;
}

/// Pretty print
/// vim.print
pub fn prettyPrint(L: ?*lua.State) callconv(.C) c_int {
    const nargs = sys.lua_gettop(L);

    const a = std.heap.c_allocator;

    var nbuf = std.ArrayList(u8).initCapacity(a, 80) catch unreachable;
    defer nbuf.deinit();

    var state = PrintState{
        .buf = &nbuf,
        .indent = 0,
        .functionCount = 0,
    };

    var idx: c_int = 1;
    while (idx <= nargs) : (idx += 1) {
        neomacsPrintInner(L, idx, &state) catch return 0;
        sys.lua_pop(L, 1);
    }

    std.log.info("print: \n{s}", .{nbuf.items});
    return 0;
}

const PrintState = struct {
    indent: usize,
    buf: *std.ArrayList(u8),
    functionCount: usize,
};

fn neomacsPrintInner(L: ?*lua.State, idx: c_int, state: *PrintState) !void {
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
