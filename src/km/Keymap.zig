const std = @import("std");
const KeyFunction = @import("KeyFunction.zig");
const KeySequence = @import("KeySequence.zig");

const Keymap = @This();
const km = @import("root.zig");

/// TODO: make this unmanaged
bindings: std.AutoArrayHashMapUnmanaged(KeySequence, KeyFunction),
fallbacks: std.AutoArrayHashMapUnmanaged(KeySequence, KeyFunction),
targeters: std.AutoArrayHashMapUnmanaged(KeySequence, KeyFunction),
alloc: std.mem.Allocator,

pub fn init(alloc: std.mem.Allocator) Keymap {
    return Keymap{
        .bindings = .{},
        .fallbacks = .{},
        .targeters = .{},
        .alloc = alloc,
    };
}

pub fn deinit(self: *Keymap) void {
    // TODO: deinit keyfunctions
    self.bindings.deinit(self.alloc);
    self.fallbacks.deinit(self.alloc);
    self.targeters.deinit(self.alloc);

    self.* = undefined;
}

pub fn appender(self: *Keymap, mode: km.ModeId) Keymap.Appender {
    return .{
        .keymap = self,
        .curprefix = KeySequence{ .mode = mode },
    };
}

/// A nice API for building keymaps
pub const Appender = struct {
    keymap: *Keymap,
    curprefix: KeySequence,

    pub fn then(self: *Appender, key: u16) !Keymap.Appender {
        var newprefix = self.curprefix;
        try newprefix.append(key);

        return .{
            .keymap = self.keymap,
            .curprefix = newprefix,
        };
    }

    pub fn put(self: *Appender, key: u16, value: KeyFunction) !void {
        var newprefix = self.curprefix;
        try newprefix.append(key);

        try self.keymap.bindings.put(self.keymap.alloc, newprefix, value);
    }

    pub fn fallback(self: *Appender, value: KeyFunction) void {
        self.keymap.fallbacks.put(self.keymap.alloc, self.curprefix, value) catch unreachable;
    }

    pub fn targeter(self: *Appender, value: KeyFunction) void {
        self.keymap.targeters.put(self.keymap.alloc, self.curprefix, value) catch unreachable;
    }
};
