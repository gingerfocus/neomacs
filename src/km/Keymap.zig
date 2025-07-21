const std = @import("std");
const KeyFunction = @import("KeyFunction.zig");
const KeySequence = @import("KeySequence.zig");

const Keymap = @This();

/// TODO: make this unmanaged
bindings: std.AutoArrayHashMapUnmanaged(KeySequence, KeyFunction),
fallbacks: std.AutoArrayHashMapUnmanaged(KeySequence, KeyFunction),
targeters: std.AutoArrayHashMapUnmanaged(KeySequence, KeyFunction),

pub fn init(alloc: std.mem.Allocator) Keymap {
    _ = alloc;

    return Keymap{
        .bindings = .{},
        .fallbacks = .{},
        .targeters = .{},
    };
}

pub fn deinit(self: *Keymap, gpa: std.mem.Allocator) void {
    // TODO: deinit keyfunctions
    self.bindings.deinit(gpa);
    self.fallbacks.deinit(gpa);
    self.targeters.deinit(gpa);
}

pub fn isPrefix(self: Keymap, seq: KeySequence) bool {
    _ = self;
    _ = seq;
    // var it = self.bindings.keyIterator();
    //
    // while (it.next()) |key| {
    //     if (seq.isPrefix(key.*)) {
    //         return true;
    //     }
    // }
    return false;
}

