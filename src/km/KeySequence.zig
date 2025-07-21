const std = @import("std");

pub const KeySequence = @This();

// TODO: make some better allignment for this and find a good size for the keys

mode: u16 = 0,
keys: [8]u16 = .{0} ** 8,
len: u8 = 0,

pub fn isPrefix(self: KeySequence, other: KeySequence) bool {
    if (self.len >= other.len) return false;
    return std.mem.eql(u16, &self.keys[0..self.len], &other.keys[0..self.len]);
}

pub fn append(self: *KeySequence, key: u16) !void {
    if (self.len >= self.keys.len) return error.SequenceTooLong;
    self.keys[self.len] = key;
    self.len += 1;
}
