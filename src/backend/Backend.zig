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

pub fn draw(self: *Self, pos: lib.Vec2, node: Node) void {
    return self.vtable.drawFn(self.dataptr, pos, node);
}

pub fn pollEvent(self: *Self, timeout: i32) Event {
    return self.vtable.pollEvent(self.dataptr, timeout);
}

pub fn render(self: *Self, mode: VTable.RenderMode) void {
    self.vtable.render(self.dataptr, mode);
}

pub const VTable = struct {
    pub const RenderMode = enum { begin, end };

    render: *const fn (self: *anyopaque, meathod: RenderMode) void,
    drawFn: *const fn (self: *anyopaque, position: lib.Vec2, node: Node) void,
    pollEvent: *const fn (self: *anyopaque, timeout: i32) Event,
    deinit: *const fn (self: *anyopaque) void,
};

pub const Node = struct {
    foreground: ?scu.Color = null,
    background: ?scu.Color = null,
    content: ?Node.Content,

    /// TODO: convert this to generic api to allow setting images or other things
    /// in a node and just letting the backend of choice figure it out.
    pub const Content = union(enum) {
        Text: u8,
        Image: []const u8, // Placeholder for image data, could be a handle or struct
    };
};

pub const Event = union(enum) {
    Key: trm.KeyEvent,
    // struct {
    //     ch: u8,
    //     mod: KeyModifiers,
    // },
    Resize,
    Timeout,
    End,
    Unknown,
    Error: bool,
};

// pub const Node = struct {
//     const VTable = struct {
//         setForeground: fn (self: *anyopaque, fg: scu.Cell) ?*Node,
//     };
//
//     vtable: *const VTable,
//     dataptr: *anyopaque,
// };
