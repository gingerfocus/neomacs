const std = @import("std");

const root = @import("../root.zig");
const Lua = root.Lua;

pub fn quit(_: ?*Lua.State) callconv(.C) c_int {
    std.log.debug("quitting", .{});
    root.state().config.QUIT = true;
    return 0;
}
