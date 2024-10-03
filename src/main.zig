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

pub const term = @import("thermit");
pub const scin = @import("scinee");

const State = defs.State;

pub const std_options: std.Options = .{
    .logFn = scin.log.logNull,
};

pub fn getHelpPage(a: std.mem.Allocator, page: [*:0]const u8) ![]const u8 {
    const env = std.posix.getenv("HOME") orelse return error.NoHome;

    const help_page = try std.fmt.allocPrint(a, "{s}/.local/share/neomacs/help/{s}", .{ env, page });

    return help_page;
}

const Args = struct {
    progname: [*:0]const u8,
    help: ?[]const u8,
    config: ?[*:0]const u8,
    positional: []const [*:0]const u8,
};

pub fn parseFlags(a: std.mem.Allocator) !Args {
    const args = std.os.argv;
    var i: usize = 0;

    var opts = Args{
        .progname = args[i],
        .help = null,
        .config = null,
        .positional = &.{},
    };
    i += 1;

    while (i < args.len) {
        if (args[i][0] != '-') break;

        const arg = mem.span(args[i]);

        if (mem.eql(u8, arg, "-h")) {
            i += 1;
            opts.help = try getHelpPage(a, "tutor");
            continue;
        }

        if (mem.eql(u8, arg, "--help")) {
            i += 1;
            if (i >= args.len) {
                opts.help = try getHelpPage(a, "tutor");
                continue;
            }
            opts.help = try getHelpPage(a, args[i]);
            i += 1;
            continue;
        }

        if (mem.eql(u8, arg, "-c") or mem.eql(u8, arg, "--config")) {
            i += 1;
            if (i >= args.len) continue;
            opts.config = args[i];
            i += 1;
            continue;
        }

        // if it doesnt match an argument try to use it as a file
        break;
    }
    opts.positional = args[i..];

    return opts;
}

// inline fn debug(msg: []const u8) void {
//     const s: std.builtin.SourceLocation = @src();
//     std.log.info("{s}:{}: {s}", .{ s.file, s.line, msg });
// }

// pub const std_options: std.Options = .{
//     // .logFn = std.log.defaultLog,
//     .logFn = logFn,
// };
//
// var logFile = std.fs.File{
//     .handle = std.posix.STDERR_FILENO,
// };
//
// fn logFn(
//     comptime message_level: std.log.Level,
//     comptime scope: @Type(.EnumLiteral),
//     comptime format: []const u8,
//     args: anytype,
// ) void {
//     _ = message_level; // autofix
//     _ = scope; // autofix
//     std.fmt.format(logFile.writer(), format, args) catch {};
// }

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    std.log.debug("starting (int main)", .{});

    const args = try parseFlags(a);

    const filename: []const u8 = if (args.positional.len < 1) "out.txt" else mem.span(args.positional[0]);

    std.log.debug("opening file ({s})", .{filename});

    var logs = std.ArrayList([]const u8).init(a);
    defer {
        for (logs.items) |log| {
            std.debug.print("err: {s}", .{log});
            a.free(log);
        }
        logs.deinit();
    }

    var state = try State.init(a);
    defer state.deinit();

    // try tools.scanFiles(&state, ".");

    // try front.initFrontend(&state);
    // defer front.deinitFrontend(&state) catch {};

    if (args.help) |helpfile| {
        defer state.a.free(helpfile);
        state.buffer = tools.loadBufferFromFile(a, helpfile) catch |err| {
            const msg = std.fmt.allocPrint(a, "File Not Found: {s}\n", .{helpfile}) catch return err;
            logs.append(msg) catch return err;
            return;
            // return err;
        };
    } else {
        state.buffer = try tools.loadBufferFromFile(a, filename);
    }

    // const syntax_filename: ?[*:0]u8 = null;
    // tools.load_config_from_file(a, &state, state.buffer, args.config, syntax_filename);

    // bf.buffer_calculate_rows(state.buffer);

    while (!state.config.QUIT and !(state.ch.modifiers.ctrl and state.ch.character.b() == 'q')) {
        tools.handleCursorShape(&state);
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
