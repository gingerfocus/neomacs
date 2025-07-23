const std = @import("std");

const ROPE_SPLIT_LENGTH = 128;

const RopeString = @This();

data: []const u8,
indx: usize, // the start index of the string
left: ?*RopeString = null,
rigt: ?*RopeString = null,

pub fn fromslice(a: std.mem.Allocator, buffer: []const u8) !RopeString {
    _ = a; // autofix
    var remaining = buffer;
    var root = RopeString{
        .data = "",
        .indx = 0,
    };
    var curr = &root;

    while (remaining.len > ROPE_SPLIT_LENGTH) {
        curr.data = remaining[0..ROPE_SPLIT_LENGTH];
    }
    curr.data = remaining;
    return root;
}
