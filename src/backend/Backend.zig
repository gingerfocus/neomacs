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

pub fn init(a: std.mem.Allocator, terminal: bool) !Self {
    if (options.windowing and !terminal) {
        if (BackendWayland.init(a)) |window| {
            return window.backend();
        } else |err| {
            root.log(@src(), .warn, "could not open wayland backend: {any}", .{err});
        }
    }

    const data = try BackendTerminal.init(a);
    return data.backend();
}

pub inline fn deinit(self: Self) void {
    self.vtable.deinit(self.dataptr);
}

pub inline fn draw(self: *Self, pos: lib.Vec2, node: Node) void {
    return self.vtable.draw(self.dataptr, pos, node);
}

pub inline fn pollEvent(self: *Self, timeout: i32) Event {
    return self.vtable.poll(self.dataptr, timeout);
}

pub inline fn render(self: *Self, mode: VTable.RenderMode) void {
    self.vtable.render(self.dataptr, mode);
}

pub const VTable = struct {
    pub const RenderMode = enum { begin, end };

    render: *const fn (self: *anyopaque, meathod: RenderMode) void,
    draw: *const fn (self: *anyopaque, position: lib.Vec2, node: Node) void,
    poll: *const fn (self: *anyopaque, timeout: i32) Event,
    deinit: *const fn (self: *anyopaque) void,
};

pub const Color = trm.Color;

pub const Node = struct {
    foreground: ?Color = null,
    background: ?Color = null,
    content: Node.Content = .None,

    /// TODO: convert this to generic api to allow setting images or other things
    /// in a node and just letting the backend of choice figure it out.
    pub const Content = union(enum) {
        Text: u8,
        Image: []const u8, // Placeholder for image data, could be a handle or struct
        None,
    };
};

pub const Event = union(enum) {
    Key: trm.KeyEvent,
    Resize,
    Timeout,
    End,
    Unknown,
    /// isFatal: bool,
    Error: bool,
};
