const root = @import("root");
const lib = root.lib;
const std = @import("std");

const Backend = @import("Backend.zig");

const FileBackend = @This();
const Self = @This();

const WIDTH: usize = 80;
const HEIGHT: usize = 24;

a: std.mem.Allocator,
file: std.fs.File,
buffer: *[WIDTH * HEIGHT]u8,

pub fn init(a: std.mem.Allocator, path: []const u8) !*Self {
    const data = try a.create(Self);

    const file = try std.fs.cwd().createFile(path, .{ .truncate = true });

    const buffer = try a.create([WIDTH * HEIGHT]u8);
    data.* = .{
        .a = a,
        .file = file,
        .buffer = buffer,
    };
    return data;
}

const thunk = struct {
    fn render(ptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
        const self = @as(*Self, @ptrCast(@alignCast(ptr)));

        switch (mode) {
            .begin => {
                @memset(self.buffer, ' ');
            },
            .end => {
                for (0..HEIGHT) |row| {
                    self.file.writeAll(self.buffer[row * WIDTH .. row * WIDTH + WIDTH]) catch {};
                    self.file.writeAll("\n") catch {};
                }
                // Add a separator for the next frame
                self.file.writeAll("--- FRAME ---\n") catch {};
            },
        }
    }

    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        const self = @as(*Self, @ptrCast(@alignCast(ptr)));

        if (pos.row >= HEIGHT or pos.col >= WIDTH) return;

        // Simple text-based drawing for now.
        switch (node.content) {
            .Text => |ch| {
                self.buffer[pos.row * WIDTH + pos.col] = ch;
            },
            .Image => |_| {
                // Images not supported in this backend
            },
            .None => {},
        }
    }

    fn pollEvent(ptr: *anyopaque, timeout: i32) Backend.Event {
        _ = ptr;
        _ = timeout;
        // This backend is not interactive, so we don't poll for events.
        // For now, we can return an error to signal we are done.
        return Backend.Event.End;
    }

    fn getSize(ptr: *anyopaque) lib.Vec2 {
        _ = ptr;
        return .{ .row = HEIGHT, .col = WIDTH };
    }

    fn deinit(ptr: *anyopaque) void {
        const self = @as(*Self, @ptrCast(@alignCast(ptr)));
        self.file.close();
        self.a.destroy(self.buffer);
        self.a.destroy(self);
    }
};

pub fn backend(self: *Self) Backend {
    return Backend{
        .dataptr = self,
        .vtable = &Backend.VTable{
            .draw = thunk.draw,
            .poll = thunk.pollEvent,
            .deinit = thunk.deinit,
            .render = thunk.render,
            .getSize = thunk.getSize,
        },
    };
}
