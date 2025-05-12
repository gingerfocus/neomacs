const std = @import("std");

fn countInversions(L: []u8) !usize {
    // std.debug.print("s: {any}\n", .{L});
    // defer std.debug.print("e: {any}\n", .{L});
    if (L.len <= 1) return 0;

    // allocate buffer for merge sorted list
    const a = std.heap.page_allocator;
    var buf = try a.alloc(u8, L.len);
    defer a.free(buf);

    var sum: usize = 0;
    const half = L.len / 2;
    sum += try countInversions(L[0..half]);
    sum += try countInversions(L[half..]);

    var lhs: usize = 0;
    var rhs: usize = half;
    var ptr: usize = 0;
    while (lhs < half or rhs < L.len) { // while either side has more
        // if there is nothing on lhs or rhs is strictly greater
        if (rhs == L.len or L[lhs] > L[rhs]) {
            buf[ptr] = L[lhs];
            // std.debug.print("+{}, {d}, {any}\n", .{ L.len - rhs, L[lhs], L[rhs..] });
            sum += L.len - rhs; // add number of elements it is greater than
            lhs += 1;
        } else { // if right side is greater OR EQUAL
            buf[ptr] = L[rhs];
            rhs += 1;
        }
        ptr += 1;
    }

    // copy sorted list to input
    for (buf, 0..) |v, i| L[i] = v;

    return sum;
}

pub fn main() !void {
    var input: [6]u8 = .{ 2, 4, 8, 2, 5, 9 };
    try std.testing.expectEqual(3, try countInversions(&input));
}
