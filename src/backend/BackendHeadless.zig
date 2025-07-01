const root = @import("../root.zig");
const lib = root.lib;
const std = @import("std");

const Backend = @import("Backend.zig");

// const HeadlessBackend = @This();
const Self = @This();

a: std.mem.Allocator,

pub fn init(a: std.mem.Allocator) !*Self {
    const data = try a.create(Self);
    data.* = .{ .a = a };
    return data;
}

const thunk = struct {
    fn render(ptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
        _ = ptr;
        _ = mode;
    }

    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        _ = ptr;
        _ = pos;
        _ = node;
    }

    fn pollEvent(ptr: *anyopaque, timeout: i32) Backend.Event {
        _ = ptr;

        std.time.sleep(@as(u64, @intCast(timeout)) * std.time.ns_per_ms);

        return Backend.Event.Timeout;
    }

    fn getSize(ptr: *anyopaque) lib.Vec2 {
        _ = ptr;

        const WIDTH: usize = 80;
        const HEIGHT: usize = 24;
        return .{ .row = HEIGHT, .col = WIDTH };
    }

    fn deinit(ptr: *anyopaque) void {
        const self = @as(*Self, @ptrCast(@alignCast(ptr)));
        self.a.destroy(self);
    }

    fn setCursor(ptr: *anyopaque, pos: lib.Vec2) void {
        _ = ptr;
        _ = pos;
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
            .setCursor = thunk.setCursor,
        },
    };
}
