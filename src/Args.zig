const std = @import("std");
const mem = std.mem;
const options = @import("options");

const Args = @This();

operation: Operation,
backend: BackendType,
files: []const []const u8,

pub const BackendType = union(enum) {
    Wayland,
    GTK,
    Terminal,
    Snapshot: []const u8,
    Headless,
};
pub const Operation = enum { None, Page, Terminal };

const InputArgs = struct {
    // progname: [*:0]const u8,
    help: ?[]const u8 = null,
    dosnapshot: ?[]const u8 = null,

    /// Run only the pager, no other functionality
    pager: bool = false,

    /// Run in the terminal, dont open a new window
    terminal: bool = !options.usegtk,

    /// Run with the GTK backend
    gtk: bool = options.usegtk,

    /// Run with the Wayland backend
    wayland: bool = options.usewayland,

    /// The config file to load
    config: ?[]const u8 = null,
};

pub fn parse(a: std.mem.Allocator) !Args {
    // TODO: std.process.args()
    // const args = try std.process.argsAlloc(a);
    // defer std.process.argsFree(a, args);

    const args = std.os.argv;

    var i: usize = 0;

    var inputs = InputArgs{
        // .progname = args[i],
    };
    i += 1;

    var files = std.ArrayList([]const u8).init(a);
    defer files.deinit();

    while (i < args.len) {
        const arg = mem.span(args[i]);
        i += 1;

        if (arg.len == 0) continue;

        if (mem.eql(u8, arg, "-h")) {
            inputs.help = try getHelpPage(a, "tutor");
            continue;
        }

        if (mem.eql(u8, arg, "--help")) {
            if (i >= args.len) {
                inputs.help = try getHelpPage(a, "tutor");
                continue;
            }
            inputs.help = try getHelpPage(a, args[i]);
            i += 1;
            continue;
        }

        if (mem.eql(u8, arg, "-c") or mem.eql(u8, arg, "--config")) {
            if (i >= args.len) continue;
            inputs.config = try a.dupe(u8, std.mem.span(args[i]));
            i += 1;
            continue;
        }

        if (mem.eql(u8, arg, "-P") or mem.eql(u8, arg, "--pager")) {
            inputs.pager = true;
            continue;
        }

        if (mem.eql(u8, arg, "-T") or mem.eql(u8, arg, "--terminal")) {
            inputs.terminal = true;
            continue;
        }

        if (mem.eql(u8, arg, "-G") or mem.eql(u8, arg, "--gtk")) {
            inputs.gtk = true;
            continue;
        }

        if (mem.eql(u8, arg, "-W") or mem.eql(u8, arg, "--wayland")) {
            inputs.wayland = true;
            continue;
        }

        if (mem.eql(u8, arg, "-R") or mem.eql(u8, arg, "--render-to-file")) {
            if (i >= args.len) continue;
            inputs.dosnapshot = try a.dupe(u8, std.mem.span(args[i]));
            i += 1;
            continue;
        }

        const narg = try a.dupe(u8, arg);
        // if it doesnt match an argument try to use it as a file
        try files.append(narg);
    }

    // -- Now Convert it to our output Args ----------------------------------

    var operation: Operation = .Terminal;
    var backend: BackendType = .Terminal;

    if (inputs.config) |filename| a.free(filename);

    if (inputs.terminal) {
        backend = .Terminal;
    }
    if (options.usewayland and inputs.wayland) {
        backend = .Wayland;
    }
    if (options.usegtk and inputs.gtk) {
        backend = .GTK;
    }
    if (inputs.pager) {
        operation = .Page;
    }
    // do this last so it doesnt get overwritten and we lose the reference
    if (inputs.dosnapshot) |filename| {
        backend = .{ .Snapshot = filename };
    }

    if (inputs.help) |filename| {
        try files.append(filename);
    }

    return Args{
        .operation = operation,
        .backend = backend,
        .files = try files.toOwnedSlice(),
    };
}

pub fn deinit(self: Args, a: std.mem.Allocator) void {
    switch (self.backend) {
        .Snapshot => |path| a.free(path),
        else => {},
    }

    for (self.files) |file| a.free(file);
    a.free(self.files);
}

fn getHelpPage(a: std.mem.Allocator, page: [*:0]const u8) ![]const u8 {
    const env = std.posix.getenv("HOME") orelse return error.NoHome;

    const help_page = try std.fmt.allocPrint(a, "{s}/.local/share/neomacs/help/{s}", .{ env, page });

    return help_page;
}

test "parse --terminal long option" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "--terminal", "file.txt" });
    defer args.deinit(a);

    try std.testing.expect(args.terminal);
    // try std.testing.expect(!args.pager);
    try std.testing.expectEqualStrings("neomacs", std.mem.span(args.progname));
    try std.testing.expectEqualStrings("file.txt", args.positionals[0]);
}

test "parse -T short option" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "dear lord", "-T", "file.txt" });
    defer args.deinit(a);

    try std.testing.expect(args.terminal);
    // try std.testing.expect(!args.pager);
    try std.testing.expectEqualStrings("dear lord", std.mem.span(args.progname));
    try std.testing.expectEqualStrings("file.txt", args.positionals[0]);
}

test "parse both --pager and --terminal" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "--pager", "--terminal", "foo" });
    defer args.deinit(a);

    try std.testing.expect(args.terminal);
    try std.testing.expect(args.pager);
    try std.testing.expectEqualStrings("foo", args.positionals[0]);
}

test "parse no options, just positionals" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "foo", "bar" });
    defer args.deinit(a);

    // try std.testing.expect(!args.terminal);
    // try std.testing.expect(!args.pager);
    try std.testing.expectEqualStrings("foo", args.positionals[0]);
    try std.testing.expectEqualStrings("bar", args.positionals[1]);
}

test "parse unknown option stops at first positional" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "--unknown", "foo" });
    defer args.deinit(a);

    // try std.testing.expect(!args.terminal);
    // try std.testing.expect(!args.pager);
    // try std.testing.expect(!args.pager);
    try std.testing.expectEqualStrings("--unknown", args.positionals[0]);
    try std.testing.expectEqualStrings("foo", args.positionals[1]);
}
