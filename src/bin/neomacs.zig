const root = @import("neomacs");
const std = root.std;
const scu = root.scu;

//-----------------------------------------------------------------------------

pub fn main() u8 {
    const logFile = std.fs.cwd().createFile("neomacs.log", .{}) catch null;
    defer if (logFile) |file| file.close();
    scu.log.file = logFile;

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

    root.log(@src(), .debug, "~~~~~~~=== starting (main void) =================~~~~~~~~~~~~~~~~~~~~~\n\n", .{});

    const args = try root.Args.parse(a, std.os.argv);
    defer args.deinit(a);

    const filename: ?[]const u8 = if (args.positionals.len > 0) std.mem.span(args.positionals[0]) else null;
    const file: ?[]const u8 = args.help orelse filename;

    // run just the terminal pager when comfigured to do so
    if (args.pager) {
        if (file) |pagerfile| {
            const f = std.fs.File{ .handle = try std.posix.open(pagerfile, .{}, 0) };
            defer f.close();
            try root.zss.page(f);
        }
        return;
    }

    root.static.state = try a.create(root.State);
    defer a.destroy(root.static.state);
    root.static.state.* = try root.State.init(a, file, args);
    defer root.static.state.deinit();

    const s = root.state();

    while (!s.config.QUIT) {
        try root.render.draw(s);

        const ev = s.backend.pollEvent(10000);

        switch (ev) {
            .Key => |ke| {
                if (root.trm.keys.bits(ke) == root.trm.keys.ctrl('q')) break;
                s.ch = ke; // used by bad events that reference state directly
                // std.debug.print("key: {any}\n", .{ke});
                try s.press(ke);
            },
            .End => s.config.QUIT = true,
            .Resize => s.resized = true,
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
