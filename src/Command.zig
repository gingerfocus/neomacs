//! There is no file I hate more than this one. It is at the top of the list
//! for every rewrite.
//!
const root = @import("root.zig");
const std = root.std;
const trm = root.trm;
const lua = root.lua;
const km = root.km;
const State = root.State;
const Buffer = root.Buffer;

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

    // TODO: have a colon commandline and a semicolon command line
    // the colon is the same as vim and the semi is a direct lua function
    fn run(state: *State) !void {
        const cmd = try state.command.buffer.toOwnedSliceSentinel(state.a, 0);
        defer state.a.free(cmd);

        std.log.debug("running command: {s}", .{cmd});

        // if (state.inputcallback) |h| {
        //     try h[1].notify();
        //     try state.loop.run(.once);
        //     std.log.debug("finish: {any}", .{h[0]});
        // }

        lua.run(state.L, cmd) catch |err| {
            root.log(@src(), .err, "lua command line error: {}", .{err});
        };

        state.command.is = false;

        const buffer = state.getCurrentBuffer() orelse return;
        buffer.setMode(Buffer.ModeId.Normal);
    }
};

pub fn init(a: std.mem.Allocator) !Command {
    var maps = km.KeyMaps{
        .keys = .{},
        .fallback = .{ .Native = thunk.append },
        .targeter = .{ .Native = km.action.none },
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
