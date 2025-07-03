pub const std = @import("std");
pub const scu = @import("scured");
pub const trm = @import("thermit"); // scu.thermit;
pub const lib = @import("lib.zig");
pub const xev = @import("xev");
pub const km = @import("keymaps.zig");

pub const render = @import("render/root.zig");

pub const Buffer = @import("Buffer.zig");
pub const State = @import("State.zig");
pub const Args = @import("Args.zig");

pub const zss = @import("zss.zig");
pub const lua = @import("lua.zig");
// const alloc = @import("alloc.zig");
// pub const ts = @cImport({ @cInclude("tree_sitter/api.h"); });

//-----------------------------------------------------------------------------

/// Log a message with the given format string and arguments using the source
/// location of the caller as the log message prefix.
pub fn log(
    comptime srcloc: std.builtin.SourceLocation,
    comptime level: std.log.Level,
    comptime format: []const u8,
    args: anytype,
) void {
    const scope = .default;

    if (comptime !std.log.logEnabled(level, scope)) return;

    const fmt = std.fmt.comptimePrint("[{s}:{d}]: ", .{ srcloc.file, srcloc.line });
    std.options.logFn(level, scope, fmt ++ format, args);
}

const static = struct {
    var hasstate: bool = false;
    var state: *State = undefined;
};

pub inline fn state() *State {
    std.debug.assert(static.hasstate);
    return static.state;
}
pub fn setstate(s: *State) void {
    static.hasstate = true;
    static.state = s;
}

test "all" {
    _ = std.testing.refAllDecls(@This());
}
