const std = @import("std");
const mem = std.mem;

// #define CREATE_UNDO(t, p) do {    \
//     Undo undo = {0};         \
//     undo.type = (t);         \
//     undo.start = (p);        \
//     state->cur_undo = undo;   \
// } while(0)

// const bf = @import("buffer.zig");
const defs = @import("defs.zig");
const front = @import("frontend.zig");
// const keys = @import("keys.zig");
// const lex = @import("lex.zig");
const tools = @import("tools.zig");
const Args = @import("args.zig");

pub const scu = @import("scured");
pub const trm = scu.thermit;

// const treesitter = @cImport({
//     @cInclude("tree_sitter/api.h");
// });

pub const luajitsys = @cImport({
    @cInclude("lua.h");
    @cInclude("lualib.h");
    @cInclude("luajit.h");
    @cInclude("luajit-2.1/lauxlib.h");
});

const State = @import("State.zig");

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

fn neomacs() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    log(@src(), .debug, "starting (main void)", .{});

    const args = try Args.parse(a, std.os.argv);
    defer args.deinit(a);

    const filename: []const u8 = if (args.positional.len < 1) "out.txt" else mem.span(args.positional[0]);

    const file = args.help orelse filename;
    var state = try State.init(a, file);
    defer state.deinit();

    // try tools.scanFiles(&state, ".");

    // const syntax_filename: ?[*:0]u8 = null;
    // tools.load_config_from_file(a, &state, state.buffer, args.config, syntax_filename);

    while (!state.config.QUIT and !(state.ch.modifiers.ctrl and state.ch.character.b() == 'q')) {
        try tools.handleCursorShape(&state);
        front.render(&state) catch |err| {
            log(@src(), .err, "encountered error: {}", .{err});
            return err;
        };

        const ev = try state.term.tty.read(10000);
        switch (ev) {
            .Key => |ke| {
                state.ch = ke;
                try state.runKeymap();
            },
            .End => state.config.QUIT = true,
            else => {},
        }
    }
}
