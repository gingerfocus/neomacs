const root = @import("root");
const lib = root.lib;
const std = @import("std");

const scu = @import("scured");

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
    fn queryNode(ptr: *anyopaque, pos: lib.Vec2) ?*Backend.Node {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        const row = @as(u16, @intCast(pos.row));
        const col = @as(u16, @intCast(pos.col));
        return self.terminal.getCell(row, col);
    }

    fn pollEvent(ptr: *anyopaque, timeout: i32) ?Backend.Event {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));
        return self.terminal.tty.read(timeout) catch return null;
    }

    fn deinit(ptr: *anyopaque) void {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        self.terminal.deinit();
        self.a.destroy(self);
    }
};

pub fn backend(terminal: *TerminalBackend) Backend {
    return Backend{
        .dataptr = terminal,
        .vtable = &Backend.VTable{
            .queryNode = thunk.queryNode,
            .pollEvent = thunk.pollEvent,
            .deinit = thunk.deinit,
        },
    };
}
