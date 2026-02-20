//! A Backend that logs all data it is passed for debug purposes. Also records
//! much of its state and makes it accessable for tests to do integration testing.

const root = @import("../root.zig");
const lib = root.lib;
const std = root.std;

const Backend = @import("Backend.zig");

const Self = @This();

const WIDTH: usize = 80;
const HEIGHT: usize = 24;

a: std.mem.Allocator,
buffer: *[WIDTH * HEIGHT]u8,
config: Config,

pub const Config = struct {
    /// How many frames accept before closing. Used in testing if you want to
    /// test how something reacts to the backend closing.
    frames: ?usize = null,
};

pub fn init(a: std.mem.Allocator, config: Config) !*Self {
    const data = try a.create(Self);

    const buffer = try a.create([WIDTH * HEIGHT]u8);
    data.* = .{
        .a = a,
        .buffer = buffer,
        .config = config,
    };
    return data;
}

/// For testing purposes.
///
/// Gets the internal state of the render buffer.
pub fn getBuffer(self: *Self) []u8 {
    return self.buffer[0..];
}

const thunk = struct {
    fn render(ptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
        const self = @as(*Self, @ptrCast(@alignCast(ptr)));

        switch (mode) {
            .begin => {
                @memset(self.buffer, ' ');
            },
            .end => {
                // decriment frame counter if needed
                if (self.config.frames) |*fr| fr -= 1;
            },
        }
    }

    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        const self = @as(*Self, @ptrCast(@alignCast(ptr)));

        if (pos.row >= HEIGHT or pos.col >= WIDTH) return;

        switch (node.content) {
            .Text => |ch| {
                self.buffer[pos.row * WIDTH + pos.col] = ch;
            },
            .Image => |_| {},
            .Shader => |_| {},
            .None => {},
        }
    }

    fn pollEvent(ptr: *anyopaque, timeout: i32) Backend.Event {
        const self = @as(*Self, @ptrCast(@alignCast(ptr)));

        if (self.config.frames) |frm|
            if (frm == 0) return Backend.Event.End;

        std.time.sleep(timeout * 1000);
        return Backend.Event.None;
    }

    fn getSize(ptr: *anyopaque) lib.Vec2 {
        _ = ptr;
        return .{ .row = HEIGHT, .col = WIDTH };
    }

    fn setCursor(ptr: *anyopaque, pos: lib.Vec2, ty: Backend.VTable.CursorType) void {
        _ = ptr;
        _ = pos;
        _ = ty;
    }

    fn deinit(ptr: *anyopaque) void {
        const self = @as(*Self, @ptrCast(@alignCast(ptr)));
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
            .setCursor = thunk.setCursor,
        },
        .stdout = true,
    };
}
