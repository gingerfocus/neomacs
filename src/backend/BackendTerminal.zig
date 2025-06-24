const root = @import("root");
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
    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        const row = @as(u16, @intCast(pos.row));
        const col = @as(u16, @intCast(pos.col));

        const cell = self.terminal.getCell(row, col) orelse return;

        if (node.background) |bg| cell.bg = bg;
        if (node.foreground) |fg| cell.fg = fg;
        switch (node.content) {
            .Text => |ch| cell.symbol = ch,
            .Image => |_| {
                root.log(@src(), .warn, "cant draw images on terminal backend", .{});
                cell.symbol = '';
            },
            .None => {},
        }

        return;
    }

    fn pollEvent(ptr: *anyopaque, timeout: i32) Backend.Event {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));
        const event: trm.Event = self.terminal.tty.read(timeout) catch return .{ .Error = true };
        switch (event) {
            .Key => |ke| return Backend.Event{ .Key = ke },
            else => {
                return Backend.Event.Unknown;
            },
            // .Resize,
            // .Timeout,
            // .End,
            // .Unknown,
        }
    }

    fn deinit(ptr: *anyopaque) void {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        self.terminal.deinit();
        self.a.destroy(self);
    }

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
};

pub fn backend(terminal: *TerminalBackend) Backend {
    return Backend{
        .dataptr = terminal,
        .vtable = &Backend.VTable{
            .draw = thunk.draw,
            .poll = thunk.pollEvent,
            .deinit = thunk.deinit,
            .render = thunk.render,
        },
    };
}
