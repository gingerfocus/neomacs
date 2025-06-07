const std = @import("std");
const root = @import("root");
const trm = root.trm;
const scu = root.scu;
const lib = root.lib;

pub const Renderer = struct {
    const Self = @This();

    pub fn query(self: *Self, pos: lib.Vec2) ?*Node {
        return self.vtable.queryNode(self.dataptr, pos);
    }

    const VTable = struct {
        queryNode: fn (self: *anyopaque, id: lib.Vec2) ?*Node,
    };

    vtable: *const VTable,
    dataptr: *anyopaque,
};

/// TODO: convert this to generic api to allow setting images or other things
/// in a node and just letting the backend of choice figure it out.
pub const Node = scu.Cell;

// pub const Node = struct {
//     const VTable = struct {
//         setForeground: fn (self: *anyopaque, fg: scu.Cell) ?*Node,
//     };
//
//     vtable: *const VTable,
//     dataptr: *anyopaque,
// };
