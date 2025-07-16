const std = @import("std");

const root = @import("../root.zig");
const lua = root.lua;

pub fn quit(_: ?*lua.State) callconv(.C) c_int {
    std.log.debug("quitting", .{});
    root.state().config.QUIT = true;
    return 0;
}
