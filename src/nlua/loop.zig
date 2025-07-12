const std = @import("std");
const lua = @import("../lua.zig");

const FsStat = struct { size: u64, kind: []const u8 };

pub fn stat(L: ?*lua.State) callconv(.C) c_int {
    const file = lua.check(L, 1, []const u8) orelse return 0;
    const statres = std.fs.cwd().statFile(file) catch return 0;
    lua.push(L, FsStat{
        .size = statres.size,
        .kind = @tagName(statres.kind),
    });
    return 1;
}
