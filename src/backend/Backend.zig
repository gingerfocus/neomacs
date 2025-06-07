const std = @import("std");
const root = @import("root");
const trm = root.trm;
const scu = root.scu;
const lib = root.lib;

const options = @import("options");

const BackendTerminal = @import("BackendTerminal.zig");
const BackendWayland = @import("BackendWayland.zig");

// arena: std.heap.ArenaAllocator,
vtable: *const VTable,
dataptr: *anyopaque,

const Self = @This();

pub fn init(a: std.mem.Allocator) !Self {
    if (options.windows) {
        if (BackendWayland.init(a)) |window| {
            return window.backend();
        } else |err| {
            root.log(@src(), .warn, "could not open wayland backend: {any}", .{err});
        }
    }

    const data = try BackendTerminal.init(a);
    return data.backend();
}

pub fn deinit(self: Self) void {
    self.vtable.deinit(self.dataptr);
}

pub fn query(self: *Self, pos: lib.Vec2) ?*Node {
    return self.vtable.queryNode(self.dataptr, pos);
}

pub fn pollEvent(self: *Self, timeout: i32) ?Event {
    return self.vtable.pollEvent(self.dataptr, timeout);
}

pub const VTable = struct {
    // render: *const fn (self: *anyopaque, func: enum { begin, end }) void,
    queryNode: *const fn (self: *anyopaque, id: lib.Vec2) ?*Node,
    pollEvent: *const fn (self: *anyopaque, timeout: i32) ?Event,
    deinit: *const fn (self: *anyopaque) void,
};

/// TODO: convert this to generic api to allow setting images or other things
/// in a node and just letting the backend of choice figure it out.
pub const Node = scu.Cell;
pub const Event = trm.Event;

// pub const Node = struct {
//     const VTable = struct {
//         setForeground: fn (self: *anyopaque, fg: scu.Cell) ?*Node,
//     };
//
//     vtable: *const VTable,
//     dataptr: *anyopaque,
// };
