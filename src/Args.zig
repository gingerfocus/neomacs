const std = @import("std");
const Args = @This();
const mem = std.mem;

progname: [*:0]const u8,
positionals: []const [*:0]const u8 = &.{},
help: ?[]const u8 = null,
dosnapshot: ?[]const u8 = null,

/// Run only the pager, no other functionality
pager: bool = false,

/// Run in the terminal, dont open a new window
terminal: bool = false,

/// Run with the GTK backend
gtk: bool = false,

/// TODO: std.process.args()
pub fn parse(a: std.mem.Allocator, args: [][*:0]u8) !Args {
    var i: usize = 0;

    var opts = Args{ .progname = args[i] };
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

        if (mem.eql(u8, arg, "-T") or mem.eql(u8, arg, "--terminal")) {
            i += 1;
            opts.terminal = true;
            continue;
        }

        if (mem.eql(u8, arg, "--gtk")) {
            i += 1;
            opts.gtk = true;
            continue;
        }

        if (mem.eql(u8, arg, "-R") or mem.eql(u8, arg, "--render-to-file")) {
            i += 1;
            if (i >= args.len) continue;
            opts.dosnapshot = try a.dupe(u8, std.mem.span(args[i]));
            i += 1;
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

test "parse --terminal long option" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "--terminal", "file.txt" });
    try std.testing.expect(args.terminal);
    try std.testing.expect(!args.pager);
    try std.testing.expectEqualStrings("neomacs", args.progname);
    try std.testing.expectEqualStrings("file.txt", args.positionals[0]);
}

test "parse -T short option" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "-T", "file.txt" });
    try std.testing.expect(args.terminal);
    try std.testing.expect(!args.pager);
    try std.testing.expectEqualStrings("neomacs", args.progname);
    try std.testing.expectEqualStrings("file.txt", args.positionals[0]);
}

test "parse both --pager and --terminal" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "--pager", "--terminal", "foo" });
    try std.testing.expect(args.terminal);
    try std.testing.expect(args.pager);
    try std.testing.expectEqualStrings("foo", args.positionals[0]);
}

test "parse no options, just positionals" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "foo", "bar" });
    try std.testing.expect(!args.terminal);
    try std.testing.expect(!args.pager);
    try std.testing.expectEqualStrings("foo", args.positionals[0]);
    try std.testing.expectEqualStrings("bar", args.positionals[1]);
}

test "parse unknown option stops at first positional" {
    const a = std.testing.allocator;
    const args = try parse(a, &.{ "neomacs", "--unknown", "foo" });
    try std.testing.expect(!args.terminal);
    try std.testing.expect(!args.pager);
    try std.testing.expectEqualStrings("--unknown", args.positionals[0]);
    try std.testing.expectEqualStrings("foo", args.positionals[1]);
}

// const options = .{
//     .pager = .{
//         .short = "-P",
//         .long = "--pager",
//         .type = bool,
//         .default = false,
//         .description = "Run as a pager, no other functionality, less replacement",
//     },
//     .help = .{
//         .short = "-h",
//         .long = "--help",
//         .type = []const u8,
//         .default = "tutor",
//         .description = "Show given help page in editor or the default",
//     },
//     .terminal = .{
//         .short = "-T",
//         .long = "--terminal",
//         .type = bool,
//         .default = false,
//         .description = "Run in the terminal, dont open a new window",
//     },
// };

// const emptyargs: []const []const u8 = &.{};

// pub fn ArgsFromOptions(comptime Options: anytype) type {
//     const OptionFields = @TypeOf(Options);
//     const fields = @typeInfo(OptionFields).@"struct".fields;

//     var field_list: []const std.builtin.Type.StructField = &.{
//         std.builtin.Type.StructField{
//             .name = "progname",
//             .type = [*:0]const u8,
//             .default_value_ptr = null,
//             .is_comptime = false,
//             .alignment = @alignOf([*:0]const u8),
//         },
//         .{
//             .name = "positionals",
//             .type = []const []const u8,
//             .default_value_ptr = @ptrCast(&emptyargs),
//             // .default_value_ptr = null,
//             .is_comptime = false,
//             .alignment = @alignOf([]const []const u8),
//         },
//     };

//     // Add option fields
//     comptime var i: usize = 0;
//     inline for (fields) |f| {
//         const field = @field(Options, f.name);
//         field_list = field_list ++ &[1]std.builtin.Type.StructField{
//             .{
//                 .name = f.name,
//                 .type = f.type,
//                 .default_value_ptr = if (@hasDecl(@TypeOf(field), "default")) &field.default else null,
//                 // .default_value_ptr = null,
//                 .is_comptime = false,
//                 .alignment = @alignOf(f.type),
//             },
//         };
//         i += 1;
//     }

//     return @Type(std.builtin.Type{ .@"struct" = std.builtin.Type.Struct{
//         .layout = .auto,
//         .fields = field_list,
//         .decls = &.{},
//         .is_tuple = false,
//     } });
// }
// // var opts = ArgsFromOptions(options){ .progname = args[i] };
