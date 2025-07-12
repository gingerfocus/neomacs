const std = @import("std");
const root = @import("../root.zig");
const trm = root.trm;
const scu = root.scu;
const lib = root.lib;

const options = @import("options");

const BackendTerminal = @import("BackendTerminal.zig");
const BackendWayland = @import("BackendWayland.zig");
const BackendGtk = @import("BackendGtk.zig");
const BackendFile = @import("BackendFile.zig");
const BackendHeadless = @import("BackendHeadless.zig");

// arena: std.heap.ArenaAllocator,
vtable: *const VTable,
dataptr: *anyopaque,

const Self = @This();
const Args = root.Args;

pub fn init(a: std.mem.Allocator, args: Args) !Self {
    if (args.dosnapshot) |render_path| {
        // this path must always converge
        const file = try BackendFile.init(a, render_path);
        return file.backend();
    }

    if (options.windowing) {
        if (args.gtk) {
            if (BackendGtk.init(a)) |window| {
                return window.backend();
            } else |err| {
                root.log(@src(), .warn, "could not open gtk backend: {any}", .{err});
            }
        }

        if (BackendWayland.init(a)) |window| {
            return window.backend();
        } else |err| {
            root.log(@src(), .warn, "could not open wayland backend: {any}", .{err});
        }
    }

    if (BackendTerminal.init(a)) |term| {
        return term.backend();
    } else |err| {
        std.log.err("could not open terminal backend: {any}", .{err});
    }

    std.log.err("could not open any backend, falling back to headless backend", .{});
    std.log.err("close with TODO", .{});

    const headless = try BackendHeadless.init(a);
    return headless.backend();
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

pub inline fn getSize(self: *Self) lib.Vec2 {
    return self.vtable.getSize(self.dataptr);
}

pub inline fn setCursor(self: *Self, pos: lib.Vec2) void {
    return self.vtable.setCursor(self.dataptr, pos);
}

pub const VTable = struct {
    pub const RenderMode = enum { begin, end };
    // pub const DataFetch = enum { width, height };

    render: *const fn (self: *anyopaque, meathod: RenderMode) void,
    draw: *const fn (self: *anyopaque, position: lib.Vec2, node: Node) void,
    getSize: *const fn (self: *anyopaque) lib.Vec2,
    setCursor: *const fn (self: *anyopaque, position: lib.Vec2) void,
    poll: *const fn (self: *anyopaque, timeout: i32) Event,
    deinit: *const fn (self: *anyopaque) void,
};

pub const Color = trm.Color;

pub const Node = struct {
    foreground: ?Color = null,
    background: ?Color = null,
    content: Node.Content = .None,

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
    // isFatal: bool,
    Error: bool,
};
