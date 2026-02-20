const root = @import("../root.zig");
const Lua = root.Lua;
const std = @import("std");

pub fn del(L: ?*Lua.State) callconv(.C) c_int {
    root.log(@src(), .info, "neomacs.keymap.del not implemented", .{});
    // Lua.check();
    _ = L; // autofix
    return 0;
}

fn getFunction(L: ?*Lua.State, idx: c_int) void {
    if (Lua.sys.lua_type(L, idx) == Lua.sys.LUA_TFUNCTION) {
        // Lua.sys.lua_pushre
        return;
    } else {}
}

const km = root.km;

// vim.keyapi.set(mode, lhs, rhs, opts)
pub fn set(L: ?*Lua.State) callconv(.C) c_int {
    // root.log(@src(), .info, "neomacs.keymap.set not implemented", .{});

    const modestr = Lua.check(L, 1, []const u8) orelse {
        root.log(@src(), .err, "neomacs.keymap.set: expected mode", .{});
        return 0;
    };
    const lhs = Lua.check(L, 2, []const u8) orelse {
        root.log(@src(), .err, "neomacs.keymap.set: expected lhs", .{});
        return 0;
    };
    const rhs = root.km.KeyFunction.initlua(L, 3) catch |err| {
        root.log(@src(), .err, "neomacs.keymap.set: expected rhs", .{});
        std.debug.print("error: {any}\n", .{err});

        Lua.sys.lua_pushstring(L, "vim.schedule: expected function");
        return Lua.sys.lua_error(L);
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
