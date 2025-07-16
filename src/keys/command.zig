const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;
const lua = root.lua;
const km = root.km;
const State = root.State;

// command.fallback = .{ .Native = command.insert };
pub fn init(a: std.mem.Allocator, maps: *km.KeyMaps) !void {
    maps.fallback = km.KeyFunction.initstate(thunk.append);

    try maps.put(
        a,
        trm.keys.norm(trm.KeySymbol.Backspace.toBits()),
        km.KeyFunction.initstate(thunk.delete),
    );

    try maps.put(
        a,
        trm.keys.norm(trm.KeySymbol.Esc.toBits()),
        km.KeyFunction.initstate(thunk.stop),
    );

    try maps.put(
        a,
        trm.keys.ctrl('c'),
        km.KeyFunction.initstate(thunk.stop),
    );

    try maps.put(
        a,
        trm.keys.norm('\n'),
        km.KeyFunction.initstate(thunk.run),
    );
}

const thunk = struct {
    fn append(state: *State, _: km.KeyFunctionDataValue) !void {
        if (state.ch.modifiers.bits() == 0)
            try state.commandbuffer.append(state.a, state.ch.character);
    }

    fn delete(state: *State, _: km.KeyFunctionDataValue) !void {
        _ = state.commandbuffer.pop();
    }

    fn stop(state: *State, _: km.KeyFunctionDataValue) !void {
        state.commandbuffer.clearRetainingCapacity();
        const buffer = state.getCurrentBuffer();
        buffer.setMode(km.ModeId.Normal);
    }

    fn run(state: *State, _: km.KeyFunctionDataValue) !void {
        const cmd = try state.commandbuffer.toOwnedSliceSentinel(state.a, 0);
        defer state.a.free(cmd);

        // vim.ui.prompt({}, function(args) end)

        std.log.debug("running command: {s}", .{cmd});

        lua.run(state.L, cmd) catch |err| {
            root.log(@src(), .err, "lua command line error: {}", .{err});
        };

        std.log.debug("running done: {s}", .{cmd});

        try thunk.stop(state, null);
    }
};
