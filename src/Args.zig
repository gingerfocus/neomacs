const std = @import("std");
const mem = std.mem;
const options = @import("options");

const Args = @This();

operation: Operation,
backend: BackendType,
files: []const []const u8,

pub const BackendType = union(enum) {
    Wgpu,
    Wayland,
    GTK,
    Terminal,
    Snapshot: []const u8,
    Headless,
};
pub const Operation = enum { None, Page, Terminal };

const InputArgs = struct {
    progname: []const u8,
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

    /// Run with the WGPU backend
    wgpu: bool = options.usewgpu,

    /// The config file to load
    config: ?[]const u8 = null,
};

pub fn parse(a: std.mem.Allocator, init: std.process.Init) !Args {
    const argv = try init.minimal.args.toSlice(a);
    defer a.free(argv);
    var inputs = InputArgs{ .progname = argv[0] };

    var files: std.ArrayListUnmanaged([]const u8) = .{ .items = &.{}, .capacity = 0 };
    defer files.deinit(a);

    var i: usize = 1;
    while (i < argv.len) : (i += 1) {
        const arg = argv[i];

        if (arg.len == 0) continue;

        if (mem.eql(u8, arg, "-h")) {
            inputs.help = try getHelpPage(a, init, "tutor");
            continue;
        }

        if (mem.eql(u8, arg, "--help")) {
            if (i >= argv.len) {
                inputs.help = try getHelpPage(a, init, "tutor");
                continue;
            }
            inputs.help = try getHelpPage(a, init, argv[i]);
            i += 1;
            continue;
        }

        if (mem.eql(u8, arg, "-c") or mem.eql(u8, arg, "--config")) {
            if (i >= argv.len) continue;
            inputs.config = try a.dupe(u8, argv[i]);
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

        if (mem.eql(u8, arg, "--wgpu")) {
            inputs.wgpu = true;
            continue;
        }

        if (mem.eql(u8, arg, "-R") or mem.eql(u8, arg, "--render-to-file")) {
            if (i >= argv.len) continue;
            inputs.dosnapshot = try a.dupe(u8, argv[i]);
            i += 1;
            continue;
        }

        const narg = try a.dupe(u8, arg);
        // if it doesnt match an argument try to use it as a file
        try files.append(a, narg);
    }

    // -- Now Convert it to our output Args ----------------------------------

    // Arg 0 is used as presets for sets of flags
    // const args = arg0: {
    //     // TODO: login shell preset
    //     // if (inputs.progname[0] == '-') {}
    //
    //     if (mem.eql(u8, inputs.progname, "zss")) {
    //     }
    //
    //     break :arg0 Args
    //
    // };
    var operation: Operation = .Terminal;
    var backend: BackendType = .Terminal;

    if (inputs.config) |filename| a.free(filename);

    if (inputs.terminal) {
        backend = .Terminal;
    }
    if (options.usewayland and inputs.wayland) {
        backend = .Wayland;
    }
    if (inputs.wgpu) {
        backend = .Wgpu;
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
        try files.append(a, filename);
    }

    return Args{
        .operation = operation,
        .backend = backend,
        .files = try files.toOwnedSlice(a),
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

fn getHelpPage(a: std.mem.Allocator, init: std.process.Init, page: []const u8) ![]const u8 {
    const home = init.environ_map.get("HOME") orelse return error.NoHome;
    return try std.fmt.allocPrint(a, "{s}/.local/share/neomacs/help/{s}", .{ home, page });
}

// test "parse --terminal long option" {
//     const a = std.testing.allocator;
//     const args = try parse(a, &.{ "neomacs", "--terminal", "file.txt" });
//     defer args.deinit(a);
//
//     try std.testing.expect(args.terminal);
//     // try std.testing.expect(!args.pager);
//     try std.testing.expectEqualStrings("neomacs", std.mem.span(args.progname));
//     try std.testing.expectEqualStrings("file.txt", args.positionals[0]);
// }
//
// test "parse -T short option" {
//     const a = std.testing.allocator;
//     const args = try parse(a, &.{ "dear lord", "-T", "file.txt" });
//     defer args.deinit(a);
//
//     try std.testing.expect(args.terminal);
//     // try std.testing.expect(!args.pager);
//     try std.testing.expectEqualStrings("dear lord", std.mem.span(args.progname));
//     try std.testing.expectEqualStrings("file.txt", args.positionals[0]);
// }
//
// test "parse both --pager and --terminal" {
//     const a = std.testing.allocator;
//     const args = try parse(a, &.{ "neomacs", "--pager", "--terminal", "foo" });
//     defer args.deinit(a);
//
//     try std.testing.expect(args.terminal);
//     try std.testing.expect(args.pager);
//     try std.testing.expectEqualStrings("foo", args.positionals[0]);
// }
//
// test "parse no options, just positionals" {
//     const a = std.testing.allocator;
//     const args = try parse(a, &.{ "neomacs", "foo", "bar" });
//     defer args.deinit(a);
//
//     // try std.testing.expect(!args.terminal);
//     // try std.testing.expect(!args.pager);
//     try std.testing.expectEqualStrings("foo", args.positionals[0]);
//     try std.testing.expectEqualStrings("bar", args.positionals[1]);
// }
//
// test "parse unknown option stops at first positional" {
//     const a = std.testing.allocator;
//     const args = try parse(a, &.{ "neomacs", "--unknown", "foo" });
//     defer args.deinit(a);
//
//     // try std.testing.expect(!args.terminal);
//     // try std.testing.expect(!args.pager);
//     // try std.testing.expect(!args.pager);
//     try std.testing.expectEqualStrings("--unknown", args.positionals[0]);
//     try std.testing.expectEqualStrings("foo", args.positionals[1]);
// }
