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
            text: []const u8,
        },
    },

    pub fn apply_to_buffer(undoaction: *const UndoAction, buffer: *Buffer) void {
        buffer.undoing = true;
        defer buffer.undoing = false;

        switch (undoaction.data) {
            .insert => |*insert| {
                buffer.movecursor(insert.position);
                for (insert.text) |char| {
                    buffer.insertCharacter(char) catch {}; // TODO: handle error
                }
            },
            .delete => |*delete| {
                buffer.delete(.{ .start = delete.start, .end = delete.end }) catch {}; // TODO: handle error
            },
        }
    }

    fn invert(undoaction: UndoAction) UndoAction {
        return switch (undoaction.data) {
            .insert => |*insert| .{
                .data = .{ .delete = .{
                    .start = insert.position,
                    .end = .{
                        .row = insert.position.row,
                        .col = insert.position.col + insert.text.len,
                    },
                    .text = insert.text,
                } },
            },
            .delete => |*delete| .{
                .data = .{ .insert = .{
                    .position = delete.start,
                    .text = delete.text,
                } },
            },
        };
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
        for (self.redos.items) |*action| {
            switch (action.data) {
                .insert => |*insert| self.allocator.free(insert.text),
                .delete => |*delete| self.allocator.free(delete.text),
            }
        }
        self.redos.deinit(self.allocator);

        for (self.undos.items) |*action| {
            switch (action.data) {
                .insert => |*insert| self.allocator.free(insert.text),
                .delete => |*delete| self.allocator.free(delete.text),
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
                .text = try self.allocator.dupe(u8, deleted_text),
            } },
        };
        try self.undos.append(self.allocator, action);
    }

    pub fn undo(self: *UndoHistory, buffer: *Buffer) void {
        if (self.undos.pop()) |action| {
            action.apply_to_buffer(buffer);

            const redoer = action.invert();
            self.redos.append(self.allocator, redoer) catch {}; // TODO: handle error
        }
    }

    pub fn redo(self: *UndoHistory, buffer: *Buffer) void {
        if (self.redos.pop()) |paction| {
            var action = paction;
            action.apply_to_buffer(buffer);

            // TODO: create a branch here
            const undoer = action.invert();
            self.undos.append(self.allocator, undoer) catch {}; // TODO: handle error
        }
    }
};
