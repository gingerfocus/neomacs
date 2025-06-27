const std = @import("std");
const root = @import("root");

const State = root.State;
const trm = root.trm;
const km = root.km;
const lua = root.lua;

// command.fallback = .{ .Native = command.insert };
pub fn init(a: std.mem.Allocator, maps: *km.KeyMaps) !void {
    maps.fallback = .{ .Native = thunk.append };

    // TODO: fix this
    maps.targeter = km.action.none;

    try maps.put(a, trm.keys.norm(trm.KeySymbol.Backspace.toBits()), .{ .Native = thunk.delete });

    try maps.put(a, trm.keys.norm(trm.KeySymbol.Esc.toBits()), .{
        .Native = thunk.gotoNormal,
    });
    try maps.put(a, trm.keys.ctrl('c'), .{
        .Native = thunk.gotoNormal,
    });

    try maps.put(a, trm.keys.norm('\n'), .{ .Native = thunk.run });
}


const thunk = struct {
    fn append(state: *State) !void {
        if (state.ch.modifiers.bits() == 0)
            try state.command.append(state.a, state.ch.character);
    }

    fn delete(state: *State) !void {
        _ = state.command.pop();
    }

    fn gotoNormal(state: *State) !void {
        state.command.clearRetainingCapacity();
        state.currentKeyMap = null;
    }

    fn run(state: *State) !void {
        const cmd = try state.command.toOwnedSliceSentinel(state.a, 0);
        defer state.a.free(cmd);

        // vim.ui.prompt({}, function(args) end)

        std.log.debug("running command: {s}", .{cmd});

        lua.runCommand(state.L, cmd) catch |err| {
            root.log(@src(), .err, "lua command line error: {}", .{err});
        };

        std.log.debug("running done: {s}", .{cmd});

        state.currentKeyMap = null;
        // state.buffer.mode = .normal;
    }
};
