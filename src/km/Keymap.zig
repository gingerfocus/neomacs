const std = @import("std");
const KeyFunction = @import("KeyFunction.zig");
const KeySequence = @import("KeySequence.zig");

const Keymap = @This();
const km = @import("root.zig");

const Storage = struct { keys: KeySequence, func: KeyFunction };
pub const StorageList = std.MultiArrayList(Storage);

/// TODO: make this unmanaged
bindings: StorageList,
fallbacks: StorageList,
targeters: StorageList,
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

pub fn put(self: *Keymap, a: std.mem.Allocator, keyseq: KeySequence, value: KeyFunction) !void {
    try self.bindings.append(a, .{ .keys = keyseq, .func = value });
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

    pub fn put(self: *Appender, a: std.mem.Allocator, key: u16, value: KeyFunction) !void {
        var newprefix = self.curprefix;
        try newprefix.append(key);

        try self.keymap.bindings.append(a, .{ .keys = newprefix, .func = value });
    }

    pub fn fallback(self: *Appender, value: KeyFunction) void {
        self.keymap.fallbacks.append(self.keymap.alloc, .{ .keys = self.curprefix, .func = value }) catch unreachable;
    }

    pub fn targeter(self: *Appender, value: KeyFunction) void {
        // TODO: check duplicate
        self.keymap.targeters.append(self.keymap.alloc, .{ .keys = self.curprefix, .func = value }) catch unreachable;
    }
};
