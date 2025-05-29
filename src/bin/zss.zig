const std = @import("std");
const lib = @import("zss");

pub fn main() !void {
    // the file that data is read from
    const f = std.fs.File{ .handle = blk: {
        if (std.os.argv.len < 2) break :blk std.posix.STDIN_FILENO;

        const file = std.mem.span(std.os.argv[1]);
        if (std.mem.eql(u8, file, "-")) break :blk std.posix.STDIN_FILENO;
        break :blk try std.posix.open(file, .{}, 0);
    } };
    defer if (f.handle != std.posix.STDIN_FILENO) std.posix.close(f.handle);

    try lib.page(f);
}
