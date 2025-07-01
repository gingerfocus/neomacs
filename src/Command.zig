const std = @import("std");
const root = @import("root");

const trm = root.trm;
const km = @import("keymaps.zig");
const lua = @import("lua.zig");

const State = @import("State.zig");

const Command = @This();

is: bool = false,
buffer: std.ArrayListUnmanaged(u8) = .{},
maps: km.KeyMaps,

const thunk = struct {
    fn append(state: *State) !void {
        if (state.ch.modifiers.bits() == 0)
            try state.command.buffer.append(state.a, state.ch.character);
    }

    fn delete(state: *State) !void {
        _ = state.command.buffer.pop();
    }

    fn gotoNormal(state: *State) !void {
        state.command.buffer.clearRetainingCapacity();
        state.command.is = false;
    }

    fn run(state: *State) !void {
        const cmd = try state.command.buffer.toOwnedSliceSentinel(state.a, 0);
        defer state.a.free(cmd);

        std.log.debug("running command: {s}", .{cmd});

        if (state.inputcallback) |h| {
            try h[1].notify();
            try state.loop.run(.once);
            std.log.debug("finish: {any}", .{h[0]});
        }

        lua.runCommand(state.L, cmd) catch |err| {
            root.log(@src(), .err, "lua command line error: {}", .{err});
        };

        state.command.is = false;
        // state.buffer.mode = .normal;
    }
};

pub fn init(a: std.mem.Allocator) !Command {
    var maps = km.KeyMaps{
        .keys = .{},
        .fallback = .{ .Native = thunk.append },
        .targeter = km.action.none,
    };

    try maps.put(a, trm.keys.norm(trm.KeySymbol.Backspace.toBits()), .{ .Native = thunk.delete });

    try maps.put(a, trm.keys.norm(trm.KeySymbol.Esc.toBits()), .{
        .Native = thunk.gotoNormal,
    });
    try maps.put(a, trm.keys.ctrl('c'), .{
        .Native = thunk.gotoNormal,
    });

    try maps.put(a, trm.keys.norm('\n'), .{ .Native = thunk.run });

    return Command{ .maps = maps };
}

pub fn deinit(self: *Command, a: std.mem.Allocator) void {
    self.buffer.deinit(a);
    self.maps.deinit(a);
}
