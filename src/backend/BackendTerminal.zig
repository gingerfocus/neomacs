const root = @import("../root.zig");
const lib = root.lib;
const std = @import("std");

const scu = @import("scured");
const trm = root.trm;

const Backend = @import("Backend.zig");

const TerminalBackend = @This();
// BackendTerminal
const Self = @This();

a: std.mem.Allocator,
terminal: scu.Term,

pub fn init(a: std.mem.Allocator) !*Self {
    const data = try a.create(TerminalBackend);

    const t = try scu.Term.init(a);
    data.* = .{
        .a = a,
        .terminal = t,
    };
    return data;
}

const thunk = struct {
    fn render(ptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        switch (mode) {
            .begin => {
                self.terminal.start(false) catch {};
            },
            .end => {
                self.terminal.finish() catch {};
            },
        }
    }

    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        const row = @as(u16, @intCast(pos.row));
        const col = @as(u16, @intCast(pos.col));

        // const cell = self.terminal.getCell(row, col) orelse return;
        const cell = self.terminal.getCell(col, row) orelse return;

        if (node.background) |bg| cell.bg = bg;
        if (node.foreground) |fg| cell.fg = fg;
        switch (node.content) {
            .Text => |ch| cell.symbol = ch,
            .Image => |_| {
                root.log(@src(), .warn, "cant draw images on terminal backend", .{});
                cell.symbol = '';
            },
            .Shader => |_| {},
            .None => {},
        }

        return;
    }

    fn pollEvent(ptr: *anyopaque, timeout: i32) Backend.Event {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));
        const event: trm.Event = self.terminal.tty.read(timeout) catch return .Timeout;
        switch (event) {
            .Key => |ke| {
                root.log(@src(), .debug, "Key: {any}", .{ke});
                return Backend.Event{ .Key = ke };
            },
            else => {
                return Backend.Event.Unknown;
            },
            // .Resize,
            // .Timeout,
            // .End,
            // .Unknown,
        }
    }

    fn getSize(ptr: *anyopaque) lib.Vec2 {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));
        return .{ .row = self.terminal.size.x, .col = self.terminal.size.y };
    }

    fn deinit(ptr: *anyopaque) void {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        self.terminal.deinit();
        self.a.destroy(self);
    }

    fn setCursor(ptr: *anyopaque, pos: lib.Vec2, ty: Backend.VTable.CursorType) void {
        // TODO: cache this and only do something if it changes

        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        scu.thermit.setCursorStyle(self.terminal.tty.f, ty) catch {};
        self.terminal.cursor = .{ .x = @intCast(pos.col), .y = @intCast(pos.row) };
    }
};

pub fn backend(terminal: *TerminalBackend) Backend {
    return Backend{
        .dataptr = terminal,
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
