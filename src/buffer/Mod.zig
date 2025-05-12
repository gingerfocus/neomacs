const std = @import("std");

const root = @import("root");
const State = root.State;

const Buffer = @This();

pub const Edit = @import("EditBuffer.zig");
pub const Empty = @import("EmptyBuffer.zig");

pub const Mode = enum(u8) {
    normal = 0,
    insert = 1,
    search = 2,
    visual = 3,
    // comand = 4,

    pub const COUNT = @typeInfo(Mode).Enum.fields.len;

    pub fn toString(self: Mode) []const u8 {
        return switch (self) {
            .normal => "NORMAL",
            .insert => "INSERT",
            .search => "SEARCH",
            // .comand => "COMMAND",
            .visual => "VISUAL",
        };
    }
};

/// Unique id for this buffer, never changes once created
id: usize,

data: union(enum) {
    Edit: Edit,
    Empty: void,
    Custom: struct {
        edit: Edit,
        changes: void,
    },
} = .{ .Empty = {} },
mode: Mode = .normal,

const id = struct {
    var count: usize = 0;
    fn next() usize {
        count += 1;
        return count;
    }
};

pub fn edit(a: std.mem.Allocator, file: []const u8) !Buffer {
    return .{
        .id = id.next(),
        .data = .{ .Edit = try Edit.init(a, file) },
        .mode = .normal,
    };
}

pub fn empty() Buffer {
    return Buffer{
        .id = id.next(),
    };
}

pub fn deinit(buffer: *Buffer, a: std.mem.Allocator) void {
    switch (buffer.data) {
        .Edit => |*ed| ed.deinit(a),
        .Empty => {},
        .Custom => |*custom| {
            custom.edit.deinit(a);
        },
    }
}

// const Target = struct {
//     down: ?isize = null,
//     left: ?isize = null,
// };

// pub const BufferVtable = struct {
//     /// Function called for all buffers, when this returns true that means the
//     /// key was handled, it doesnt need to have done anything just agknowledged.
//     /// When returning false the caller will then resolve global key mappings
//     /// if possible. This could be used for implementing local buffer key maps
//     press: *const fn (*anyopaque, u8) bool,
//
//     move: *const fn (*anyopaque, Target) void,
//     edit: *const fn (*anyopaque, u8) void,
//
//     pub fn nullMove(_: *anyopaque, _: Target) void {}
//     pub fn nullEdit(_: *anyopaque, _: u8) void {}
// };

// dataptr: *anyopaque,
// vtable: *const BufferVtable,

// pub inline fn move(self: Self, target: Target) void {
//     self.vtable.move(self.dataptr, target);
// }
//
// pub inline fn edit(self: Self, ch: u8) void {
//     self.vtable.edit(self.dataptr, ch);
// }
