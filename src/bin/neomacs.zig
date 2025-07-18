const root = @import("neomacs");
const std = root.std;
const scu = root.scu;

pub const std_options: std.Options = .{
    .logFn = scu.log.toFile,
};

//-----------------------------------------------------------------------------

pub fn main() u8 {
    const logFile = std.fs.cwd().createFile("neomacs.log", .{}) catch null;
    defer if (logFile) |file| file.close();
    scu.log.file = logFile;

    root.alloc.init();

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

    return switch (root.alloc.deinit()) {
        .leak => blk: {
            std.debug.print("leaked memory\n", .{});
            break :blk 1;
        },
        .ok => 0,
    };
}

//-----------------------------------------------------------------------------

fn neomacs() !void {
    const a = root.alloc.allocator();

    // root.log(@src(), .debug, "~~~~~~~=== starting (main void) =================~~~~~~~~~~~~~~~~~~~~~\n\n", .{});

    const args = try root.Args.parse(a, std.os.argv);
    defer args.deinit(a);

    // run just the terminal pager when comfigured to do so
    if (args.operation == .Page) {
        if (args.files.len != 1) return;

        const f = std.fs.File{ .handle = try std.posix.open(args.files[0], .{}, 0) };
        defer f.close();
        try root.zss.page(f);
        return;
    }

    const state = try a.create(root.State);
    defer a.destroy(state);
    root.setstate(state);

    state.* = try root.State.init(a, args);
    defer state.deinit();

    while (!state.config.QUIT) {
        try root.render.draw(state);

        const ev = state.backend.pollEvent(10000);

        switch (ev) {
            .Key => |ke| {
                if (root.trm.keys.bits(ke) == root.trm.keys.ctrl('q')) break;
                state.ch = ke; // used by bad events that reference state directly
                // std.debug.print("key: {any}\n", .{ke});
                try state.press(ke);
            },
            .End => state.config.QUIT = true,
            .Resize => state.resized = true,
            // .Error => |fatal| { if (fatal) break; },
            else => {},
        }
    }

    std.log.info("Quitting", .{});

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
