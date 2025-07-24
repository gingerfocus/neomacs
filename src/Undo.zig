const root = @import("root.zig");
const std = root.std;
const lib = root.lib;
const Buffer = root.Buffer;

pub const UndoAction = struct {
    /// An action to be preformed after as part of the same undo group.
    next: ?*UndoAction = null,
    /// The type of action to preform.
    data: union(enum) {
        insert: struct {
            position: lib.Vec2,
            text: []const u8,
        },
        delete: struct {
            start: lib.Vec2,
            end: lib.Vec2,
            deleted_text: []const u8,
        },
    },

    pub fn apply_to_buffer(undoaction: *UndoAction, buffer: *Buffer) void {
        _ = undoaction;
        _ = buffer;

        unreachable; // unimplemented
    }
};

pub const UndoHistory = struct {
    allocator: std.mem.Allocator,
    undos: std.ArrayListUnmanaged(UndoAction),
    redos: std.ArrayListUnmanaged(UndoAction),

    pub fn init(allocator: std.mem.Allocator) UndoHistory {
        return UndoHistory{
            .allocator = allocator,
            .undos = std.ArrayListUnmanaged(UndoAction){},
            .redos = std.ArrayListUnmanaged(UndoAction){},
        };
    }

    pub fn deinit(self: *UndoHistory) void {
        for (self.undos.items) |*action| {
            switch (action.data) {
                .insert => |*insert| self.allocator.free(insert.text),
                .delete => |*delete| self.allocator.free(delete.deleted_text),
            }
        }
        self.undos.deinit(self.allocator);
    }

    pub fn recordInsert(self: *UndoHistory, position: lib.Vec2, text: []const u8) !void {
        const action = UndoAction{
            .data = .{ .insert = .{
                .position = position,
                .text = try self.allocator.dupe(u8, text),
            } },
        };
        try self.undos.append(self.allocator, action);
    }

    pub fn recordDelete(self: *UndoHistory, start: lib.Vec2, end: lib.Vec2, deleted_text: []const u8) !void {
        const action = UndoAction{
            .data = .{ .delete = .{
                .start = start,
                .end = end,
                .deleted_text = try self.allocator.dupe(u8, deleted_text),
            } },
        };
        try self.undos.append(self.allocator, action);
    }
};
