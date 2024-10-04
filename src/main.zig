const std = @import("std");
const mem = std.mem;

// const bf = @import("buffer.zig");
// const cgo = @import("cgetopt.zig");
// const clr = @import("colors.h.zig");
// const cmd = @import("commands.zig");
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

const State = defs.State;

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

    innermain() catch |err| {
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

fn innermain() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    log(@src(), .debug, "starting (int main)\n", .{});

    const args = try Args.parse(a, std.os.argv);
    defer args.deinit(a);

    const filename: []const u8 = if (args.positional.len < 1) "out.txt" else mem.span(args.positional[0]);

    var state = try State.init(a);
    defer state.deinit();

    // try tools.scanFiles(&state, ".");

    // try front.initFrontend(&state);
    // defer front.deinitFrontend(&state) catch {};

    const file = args.help orelse filename;
    log(@src(), .debug, "opening file ({s})\n", .{file});
    state.buffer = tools.loadBufferFromFile(a, file) catch |err| {
        log(@src(), .err, "File Not Found: {s}\n", .{file});
        return err;
    };

    // const syntax_filename: ?[*:0]u8 = null;
    // tools.load_config_from_file(a, &state, state.buffer, args.config, syntax_filename);

    // bf.buffer_calculate_rows(state.buffer);

    while (!state.config.QUIT and !(state.ch.modifiers.ctrl and state.ch.character.b() == 'q')) {
        try tools.handleCursorShape(&state);
        try front.render(&state);

        const ev = try state.term.tty.read(10000);
        switch (ev) {
            .Key => |ke| {
                state.ch = ke;
                try state.key_func[@intFromEnum(state.config.mode)](state.buffer.?, &state);
            },
            .End => state.config.QUIT = true,
            else => {},
        }
    }
}
