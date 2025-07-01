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

pub const std_options: std.Options = .{
    .logFn = scu.log.toFile,
};

pub fn log(
    comptime srcloc: std.builtin.SourceLocation,
    comptime level: std.log.Level,
    comptime format: []const u8,
    args: anytype,
) void {
    const scope = .default;

    if (comptime !std.log.logEnabled(level, scope)) return;

    const fmt = std.fmt.comptimePrint("{s}:{}: ", .{ srcloc.file, srcloc.line });
    std.options.logFn(level, scope, fmt ++ format, args);
}

const static = struct {
    var state: *State = undefined;
};

pub inline fn state() *State {
    return static.state;
}

pub fn main() u8 {
    const logFile = std.fs.cwd().createFile("neomacs.log", .{}) catch null;
    defer if (logFile) |file| file.close();
    scu.log.file = logFile;

    neomacs() catch |err| {
        std.debug.print("Some unrecoverable error occorred. Check log file for details.\n", .{});
        log(@src(), .err, "Error: {}\n", .{err});
        if (@errorReturnTrace()) |stacktrace| {
            log(@src(), .err, "Stacktrace: {}\n", .{stacktrace});
        } else {
            log(@src(), .err, "Unable to Generate Stacktrace\n", .{});
        }
        return 1;
    };
    return 0;
}

//-----------------------------------------------------------------------------

fn neomacs() !void {
    var endtime: i64 = undefined;
    defer {
        const end = std.time.microTimestamp();
        std.debug.print("Close taken: {} us\n", .{end - endtime});
    }

    var alloc = std.heap.GeneralPurposeAllocator(.{}){}; // alloc.init();
    defer _ = alloc.deinit();
    const a = alloc.allocator();

    log(@src(), .debug, "~~~~~~~=== starting (main void) =================~~~~~~~~~~~~~~~~~~~~~\n\n", .{});

    const args = try Args.parse(a, std.os.argv);
    defer args.deinit(a);

    const filename: ?[]const u8 = if (args.positionals.len > 0) std.mem.span(args.positionals[0]) else null;
    const file: ?[]const u8 = args.help orelse filename;

    // run just the terminal pager when comfigured to do so
    if (args.pager) {
        if (file) |pagerfile| {
            const f = std.fs.File{ .handle = try std.posix.open(pagerfile, .{}, 0) };
            defer f.close();
            try zss.page(f);
        }
        return;
    }

    static.state = try a.create(State);
    static.state.* = try State.init(a, file, args);
    defer a.destroy(static.state);

    const s = state();
    defer static.state.deinit();

    while (!s.config.QUIT) {
        try render.draw(s);

        const ev = s.backend.pollEvent(10000);

        switch (ev) {
            .Key => |ke| {
                if (trm.keys.bits(ke) == trm.keys.ctrl('q')) break;
                s.ch = ke; // used by bad events that reference state directly
                std.debug.print("key: {any}\n", .{ke});

                // std.debug.print("key: {any}\n", .{ke});
                try s.press(ke);
            },
            .End => s.config.QUIT = true,
            // .Resize => s.resized = true,
            // .Error => |fatal| { if (fatal) break; },
            else => {},
        }
    }

    std.log.info("Quitting", .{});
    endtime = std.time.microTimestamp();

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

test "all" {
    _ = std.testing.refAllDecls(@This());
}
