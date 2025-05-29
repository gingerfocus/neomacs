const Args = @This();

progname: [*:0]const u8,
help: ?[]const u8,
// config: ?[*:0]const u8,
positionals: []const [*:0]const u8,

/// Run only the pager, no other functionality
pager: bool = false,

const std = @import("std");
const mem = std.mem;

pub fn parse(a: std.mem.Allocator, args: [][*:0]const u8) !Args {
    var i: usize = 0;

    var opts = Args{
        .progname = args[i],
        .help = null,
        // .config = null,
        .positionals = &.{},
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

        // if (mem.eql(u8, arg, "-c") or mem.eql(u8, arg, "--config")) {
        //     i += 1;
        //     if (i >= args.len) continue;
        //     opts.config = args[i];
        //     i += 1;
        //     continue;
        // }

        if (mem.eql(u8, arg, "-P") or mem.eql(u8, arg, "--pager")) {
            i += 1;
            opts.pager = true;
            continue;
        }

        // if it doesnt match an argument try to use it as a file
        break;
    }
    opts.positionals = args[i..];

    return opts;
}

pub fn deinit(self: Args, a: std.mem.Allocator) void {
    if (self.help) |filename| a.free(filename);
}

fn getHelpPage(a: std.mem.Allocator, page: [*:0]const u8) ![]const u8 {
    const env = std.posix.getenv("HOME") orelse return error.NoHome;

    const help_page = try std.fmt.allocPrint(a, "{s}/.local/share/neomacs/help/{s}", .{ env, page });

    return help_page;
}

test "arg parse" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "echo", "hello" });
    std.testing.expectEqual(args, Args{
        .progname = "echo",
        .positionals = &.{"hello"},
        .help = "hal",
    });
}
