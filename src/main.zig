const std = @import("std");
const mem = std.mem;

pub const scu = @import("scured");
pub const trm = scu.thermit;

const front = @import("frontend.zig");
const tools = @import("tools.zig");
const lua = @import("lua.zig");
const alloc = @import("alloc.zig");

pub const Buffer = @import("buffer/Mod.zig");

pub const State = @import("State.zig");

pub const treesitter = @cImport({
    @cInclude("tree_sitter/api.h");
});

//-----------------------------------------------------------------------------

const Args = @import("Args.zig");

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
    var state: State = undefined;
};

pub inline fn state() *State {
    return &static.state;
}

pub fn main() u8 {
    const logFile = std.fs.cwd().createFile("neomacs.log", .{}) catch null;
    defer if (logFile) |file| file.close();
    scu.log.setFile(logFile);

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
    alloc.init();
    defer alloc.deinit();
    const a = alloc.allocator();

    log(@src(), .debug, "~~~~~~~=== starting (main void) =================~~~~~~~~~~~~~~~~~~~~~\n\n", .{});

    const args = try Args.parse(a, std.os.argv);
    defer args.deinit(a);

    const filename: ?[]const u8 = if (args.positionals.len > 0) mem.span(args.positionals[0]) else null;

    const file: ?[]const u8 = args.help orelse filename;

    static.state = try State.init(a, file);
    const s = state();
    defer s.deinit();

    while (!(trm.keys.bits(s.ch) == trm.keys.ctrl('q')) and !s.config.QUIT) {
        try tools.handleCursorShape(s);
        try front.render(s);

        const ev = try s.term.tty.read(10000);
        switch (ev) {
            .Key => |ke| {
                s.ch = ke;
                try s.press();
            },
            .End => s.config.QUIT = true,
            .Resize => s.resized = true,
            else => {},
        }
    }

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
