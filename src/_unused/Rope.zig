//! https://en.wikipedia.org/wiki/Rope_(data_structure)
//!

const root = @import("../root.zig");
const std = root.std;

const WEIGHT = 128;

const Rope = @This();

data: []const u8,
/// The sum of data to the left of this string
leftindx: usize,
left: ?*Rope = null,
rigt: ?*Rope = null,

pub fn fromslice(a: std.mem.Allocator, buffer: []const u8) !Rope {
    if (buffer.len <= WEIGHT) {
        return Rope{
            .data = buffer,
            .leftindx = 0,
        };

        // } else if (buffer.len < WEIGHT * 2) {
        //     const left = try Rope.fromslice(a, buffer[0..WEIGHT]);
        //     _ = left;
        //     @panic("TODO");
    } else {
        const half = buffer.len / 2;
        const start = half - (WEIGHT / 2);
        const end = start + WEIGHT;

        const left = try a.create(Rope);
        left.* = try Rope.fromslice(a, buffer[0..start]);

        const rigt = try a.create(Rope);
        rigt.* = try Rope.fromslice(a, buffer[start + WEIGHT ..]);

        return Rope{
            .data = buffer[start..end],
            .leftindx = start,
            .left = left,
            .rigt = rigt,
        };
    }
}

pub fn deinit(rope: *Rope, a: std.mem.Allocator) void {
    a.free(rope.data);

    if (rope.left) |*left| {
        left.deinit();
        a.destroy(left);
    }

    if (rope.rigt) |*rigt| {
        rigt.deinit();
        a.destroy(rigt);
    }
}

pub fn debug(rope: *Rope, level: usize) !void {
    if (rope.left) |left| left.debug(level + 2);

    const io = std.io.getStdOut().writer();
    try io.writeByteNTimes(' ', level);
    try io.writeAll(rope.data);
    try io.writeByte('\n');

    if (rope.rigt) |rigt| rigt.debug(level + 2);
}
