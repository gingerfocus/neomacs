const std = @import("std");
const root = @import("neomacs");
const zss = root.zss;

pub fn main() !void {
    // the file that data is read from
    const f = blk: {
        if (std.os.argv.len < 2) break :blk std.io.getStdIn();

        const file = std.mem.span(std.os.argv[1]);
        if (std.mem.eql(u8, file, "-")) break :blk std.io.getStdIn();
        break :blk try std.fs.cwd().openFile(file, .{});
    };
    defer if (f.handle != std.posix.STDIN_FILENO) f.close();

    try zss.page(f);
}
