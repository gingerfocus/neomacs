const std = @import("std");
const root = @import("../root.zig");
const Lua = root.Lua;

const FsStat = struct { size: u64, kind: []const u8 };

pub fn stat(L: ?*Lua.State) callconv(.c) c_int {
    const file = Lua.check(L, 1, []const u8) orelse return 0;
    const statres = std.Io.Dir.cwd().statFile(root.io, file, .{}) catch return 0;
    Lua.push(L, FsStat{
        .size = statres.size,
        .kind = @tagName(statres.kind),
    });
    return 1;
}
