const lua = @import("../lua.zig");
const root = @import("../root.zig");
const std = @import("std");

pub fn del(L: ?*lua.State) callconv(.C) c_int {
    root.log(@src(), .info, "neomacs.keymap.del not implemented", .{});
    // lua.check();
    _ = L; // autofix
    return 0;
}

fn getFunction(L: ?*lua.State, idx: c_int) void {
    if (lua.sys.lua_type(L, idx) == lua.sys.LUA_TFUNCTION) {
        // lua.sys.lua_pushre
        return;
    } else {}
}

    const km = root.km;

// vim.keyapi.set(mode, lhs, rhs, opts)
pub fn set(L: ?*lua.State) callconv(.C) c_int {
    // root.log(@src(), .info, "neomacs.keymap.set not implemented", .{});

    const modestr = lua.check(L, 1, []const u8) orelse {
        root.log(@src(), .err, "neomacs.keymap.set: expected mode", .{});
        return 0;
    };
    const lhs = lua.check(L, 2, []const u8) orelse {
        root.log(@src(), .err, "neomacs.keymap.set: expected lhs", .{});
        return 0;
    };
    const rhs = root.km.KeyFunction.initlua(L, 3) catch |err| {
        root.log(@src(), .err, "neomacs.keymap.set: expected rhs", .{});
        std.debug.print("error: {any}\n", .{err});

        lua.sys.lua_pushstring(L, "vim.schedule: expected function");
        return lua.sys.lua_error(L);
        // return 0; // 1?
    };

    // TODO: get opts

    const state = root.state();
    const mode = root.km.ModeId.from(modestr);

    const keyseq = km.KeySequence.init(mode, lhs);
    state.global_keymap.put(state.a, keyseq, rhs) catch {};
    root.log(@src(), .debug, "neomacs.keymap.set: mode {s} lhs {s} rhs {any}", .{ modestr, lhs, rhs });

    return 0;
}
