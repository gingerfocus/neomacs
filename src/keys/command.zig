const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;
const lua = root.lua;
const km = root.km;
const State = root.State;

pub fn init(a: std.mem.Allocator, modes: *km.ModeToKeys) !void {

    const res = try modes.getOrPut(a, km.ModeId.Command);
    if (!res.found_existing) {
        std.log.debug("creating new command map", .{});
        res.value_ptr.* = try a.create(km.KeyMaps);
    }

    const map = res.value_ptr.*;
    map.* = km.KeyMaps{
        .modeid = km.ModeId.Command,
        .fallback = km.KeyFunction.initstate(commandline.append),
        .targeter = null,
    };

    try map.put(
        a,
        trm.keys.norm(trm.KeySymbol.Backspace.toBits()),
        km.KeyFunction.initstate(commandline.delete),
    );

    try map.put(
        a,
        trm.keys.norm(trm.KeySymbol.Esc.toBits()),
        km.KeyFunction.initstate(commandline.stop),
    );

    try map.put(
        a,
        trm.keys.ctrl('c'),
        km.KeyFunction.initstate(commandline.stop),
    );

    try map.put(
        a,
        trm.keys.norm('\n'),
        km.KeyFunction.initstate(commandline.run),
    );
}

const commandline = struct {
    fn append(state: *State, _: km.KeyFunctionDataValue) !void {
        // std.debug.print("appending {d}\n", .{state.ch.character});
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

        try commandline.stop(state, null);
    }
};
