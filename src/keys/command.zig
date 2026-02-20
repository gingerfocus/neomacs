const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;
const Lua = root.Lua;
const km = root.km;
const State = root.State;

const norm = trm.keys.norm;
const ctrl = trm.keys.ctrl;

pub fn init(a: std.mem.Allocator, modes: *km.Keymap, lua_enabled: bool) !void {
    if (!lua_enabled) return;

    var normal = modes.appender(km.ModeId.Normal);
    try normal.put(a, norm(':'), .initsetmod(km.ModeId.Command));

    var command = modes.appender(km.ModeId.Command);
    command.fallback(.initstate(commandline.append));

    try command.put(a, norm(trm.KeySymbol.Backspace.toBits()), .initstate(commandline.delete));
    try command.put(a, norm(trm.KeySymbol.Esc.toBits()), .initstate(commandline.stop));
    try command.put(a, norm('\n'), .initstate(commandline.run));
    try command.put(a, ctrl('c'), .initstate(commandline.stop));
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

    fn run(state: *State, ctx: km.KeyFunctionDataValue) !void {
        const cmd = try state.commandbuffer.toOwnedSliceSentinel(state.a, 0);
        defer state.a.free(cmd);

        // vim.ui.prompt({}, function(args) end)

        std.log.debug("running command: {s}", .{cmd});

        if (state.L.enabled) {
            if (comptime Lua.compiled_in) {
                Lua.run(state.L.state, cmd) catch |err| {
                    root.log(@src(), .err, "lua command line error: {}", .{err});
                };
            }
        }

        std.log.debug("running done: {s}", .{cmd});

        try commandline.stop(state, ctx);
    }
};
