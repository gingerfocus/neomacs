const trm = @import("thermit");
const std = @import("std");
pub fn main() !void {
    var term = try trm.Terminal.init(std.io.getStdOut());
    defer term.deinit();

    try term.enableRawMode();

    var bytes: [8]u8 = .{0} ** 8;
    const readsize = try term.f.read(&bytes);
    // const ev = term.read(-1);

    try term.disableRawMode();

    std.debug.print("\nev: {any}\n", .{bytes[0..readsize]});
    // std.debug.print("\nev: {any}\n", .{ev});
}
