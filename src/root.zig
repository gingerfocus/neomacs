const root = @This();

pub const std = @import("std");

pub const scu = @import("scured");
pub const trm = @import("thermit");
// pub const xev = @import("xev");

pub const Args = @import("Args.zig");
pub const Backend = @import("backend/Backend.zig");
pub const Buffer = @import("Buffer.zig");
pub const State = @import("State.zig");
// pub const Config = State.Config;

pub const km = @import("km/root.zig");
pub const lib = @import("lib/root.zig");
pub const lua = @import("lua.zig");
pub const zss = @import("zss.zig");
pub const keys = @import("keys/root.zig");
pub const alloc = @import("alloc.zig");
pub const render = @import("render/root.zig");

// pub const ts = @cImport({ @cInclude("tree_sitter/api.h"); });

fn logfn(
    comptime message_level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    if (scu.log.file) |_| {
        scu.log.toFile(message_level, scope, format, args);
    } else {
        std.log.defaultLog(message_level, scope, format, args);
    }
}
pub const std_options: std.Options = .{
    .logFn = logfn,
};

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

    // TODO: make an implementation that does that the src struct
    // @returnAddress()
    // var iter = std.debug.StackIterator.init(null, null);

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

//-----------------------------------------------------------------------------

pub fn main() u8 {
    alloc.init();

    defer if (scu.log.file) |file| file.close();

    neomacs() catch |err| {
        std.debug.print("Some unrecoverable error occorred. Check log file for details.\n", .{});
        root.log(@src(), .err, "Error: {}\n", .{err});
        if (@errorReturnTrace()) |stacktrace| {
            root.log(@src(), .err, "Stacktrace: {}\n", .{stacktrace});
        } else {
            root.log(@src(), .err, "Unable to Generate Stacktrace\n", .{});
        }
        return 1;
    };

    return switch (root.alloc.deinit()) {
        .leak => blk: {
            std.debug.print("leaked memory\n", .{});
            break :blk 1;
        },
        .ok => 0,
    };
}

//-----------------------------------------------------------------------------

fn neomacs() !void {
    const a = root.alloc.allocator();

    // root.log(@src(), .debug, "~~~~~~~=== starting (main void) =================~~~~~~~~~~~~~~~~~~~~~\n\n", .{});

    const args = try Args.parse(a, std.os.argv);
    defer args.deinit(a);

    // run just the terminal pager when comfigured to do so
    if (args.operation == .Page) {
        if (args.files.len != 1) return;

        const f = std.fs.File{ .handle = try std.posix.open(args.files[0], .{}, 0) };
        defer f.close();
        try zss.page(f);
        return;
    }

    const s = try a.create(State);
    defer a.destroy(s);
    setstate(s);

    s.* = try State.init(a, args);
    defer s.deinit();

    try s.setup();

    while (!s.config.QUIT) {
        try render.draw(s);

        const ev = s.backend.pollEvent(10000);

        switch (ev) {
            Backend.Event.Key => |ke| {
                if (trm.keys.bits(ke) == trm.keys.ctrl('q')) break;
                s.ch = ke; // used by bad events that reference state directly
                // std.debug.print("key: {any}\n", .{ke});
                try s.press(ke);
            },
            .End => s.config.QUIT = true,
            .Resize => s.resized = true,
            .Error => |fatal| s.config.QUIT = fatal,
            else => {},
        }
    }

    std.log.info("Quitting", .{});

    // const parser = treesitter.ts_parser_new();
    // treesitter.ts_parser_set_language(parser, tree_sitter_json());

    // const tree = treesitter.ts_parser_parse_string(
    //   parser,
    //   NULL,
    //   source_code,
    //   strlen(source_code)
    // );
    // _ = allocator.deinit();

}
