const std = @import("std");
const thr = @import("thermit");

// when reading from files, what size chunck size should be used?
const BUFFER_SIZE = 2048;

fn forwardFile(i: std.fs.File, o: std.fs.File) !void {
    var buffer: [BUFFER_SIZE]u8 = undefined;
    while (true) {
        const read = try i.read(&buffer);
        if (read == 0) return;
        try o.writeAll(buffer[0..read]);
    }
}

fn readFile(f: std.fs.File, a: std.mem.Allocator) ![]const u8 {
    var buffer = std.ArrayList(u8).init(a);
    defer buffer.deinit();

    while (true) {
        var buf: [BUFFER_SIZE]u8 = undefined;
        const readsize = try f.read(&buf);
        if (readsize == 0) break;
        try buffer.appendSlice(buf[0..readsize]);
    }
    return buffer.toOwnedSlice();
}

const State = struct {
    const Pos = struct { x: usize, y: usize };

    tty: thr.Terminal,

    position: usize = 0,
    search: ?struct {
        term: []const u8,
        /// Currently highlighted position
        index: usize = 0,
        locations: []const Pos,

        pub fn deinit(search: @This(), a: std.mem.Allocator) void {
            a.free(search.locations);
            a.free(search.term);
        }
    } = null,
    repeat: ?usize = null,
    status: ?[]const u8 = null,
    a: std.mem.Allocator,

    // semi-constant feilds
    x: u16,
    y: u16,
    lines: []const []const u8,

    /// Creats the state of the application. `i` must remain valid for the
    /// lifetime of this struct as it borrows from it and `o` must remain open.
    fn init(i: []const u8, o: std.fs.File, a: std.mem.Allocator) !State {
        const lines = try blk: {
            var buffer = std.ArrayList([]const u8).init(a);
            var iter = std.mem.splitScalar(u8, i, '\n');
            while (iter.next()) |line| try buffer.append(line);
            break :blk buffer.toOwnedSlice();
        };
        var tty = try thr.Terminal.init(o);

        try tty.enableRawMode();
        try thr.enterAlternateScreen(tty.f);
        // const x, const y =
        const size = try thr.getWindowSize(tty.f.handle);

        return .{ .tty = tty, .a = a, .x = size.x, .y = size.y, .lines = lines };
    }

    fn deinit(state: *State) void {
        state.a.free(state.lines);

        if (state.search) |search| search.deinit(state.a);

        thr.leaveAlternateScreen(state.tty.f.writer()) catch {};
        state.tty.disableRawMode() catch {};

        state.tty.deinit();
    }
};

pub fn page(f: std.fs.File) !void {
    const tty = std.fs.File{ .handle = try std.posix.open("/dev/tty", .{ .ACCMODE = .RDWR }, 0) };
    defer tty.close();

    // if we are in a pipeline this is not the intended use case. Just pipe
    // through and move on with life.
    if (tty.isTty() == false) return try forwardFile(f, tty);

    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    const buffer = try readFile(f, a);
    defer a.free(buffer);

    var state = try State.init(buffer, tty, a);
    defer state.deinit();

    try mainLoop(&state);
}

fn clearSearch(state: *State) void {
    if (state.search) |search| { // esc
        search.deinit(state.a);
        state.search = null;
    }
}

// fn norm(comptime c: thr.KeyCharacter) u16 {
//     const keyev = thr.KeyEvent{
//         .character = c,
//         .modifiers = .{},
//     };
//     return @bitCast(keyev);
// }
//
// fn ctrl(comptime c: thr.KeyCharacter) u16 {
//     const keyev = thr.KeyEvent{
//         .character = c,
//         .modifiers = .{ .ctrl = true },
//     };
//     return @bitCast(keyev);
// }

const norm = thr.keys.norm;
const ctrl = thr.keys.ctrl;

fn mainLoop(state: *State) !void {
    // std.debug.print("{} - {}", .{ state.lines.len, state.y });
    const end = if (state.y > state.lines.len) 0 else state.lines.len - state.y;
    while (true) {
        try render(state);

        const ev = try state.tty.read(1000);

        const key = switch (ev) {
            .Key => |k| k,
            else => continue,
        };

        switch (thr.keys.bits(key)) {
            'q', ctrl('c') => break,

            norm('j'),
            // thr.evbits(.{.character = . }), // space
            norm(thr.KeySymbol.Return.toBits()),
            => {
                scrollDown(&state.position, state.repeat orelse 1, end);
                state.repeat = null;
            },
            norm('k') => {
                scrollUp(&state.position, state.repeat orelse 1);
                state.repeat = null;
            },
            norm('g') => {
                state.position = 0;
                state.repeat = null;
            },
            norm('G') => {
                state.position = end;
                state.repeat = null;
            },
            'S', // I dont know if this should be recomended
            '/',
            => if (!try searchRoutine(state)) {
                try thr.clear(state.tty.f.writer(), .CurrentLine);
                try thr.moveCol(state.tty.f.writer(), 0);
                state.status = "No Results";
            },
            ctrl('n') => {
                nextSearch(state, state.repeat orelse 1);
                state.repeat = null;
            },
            ctrl('d') => {
                scrollDown(&state.position, (state.repeat orelse 1) * 20, end);
                state.repeat = null;
            },
            ctrl('u') => {
                scrollDown(&state.position, (state.repeat orelse 1) * 20, end);
                state.repeat = null;
            },
            norm('0')...norm('9') => {
                const v = key.character - '0';
                std.debug.assert(v < 10);
                if (state.repeat) |*repeat| {
                    repeat.* *= 10;
                    repeat.* += v;
                } else {
                    state.repeat = v;
                }
            },
            // norm(.Tab) => {},
            norm(thr.KeySymbol.Esc.toBits()) => {
                clearSearch(state);
                state.repeat = 0;
                continue;
            },
            else => {},
        }
    }
}

fn searchRoutine(state: *State) !bool {
    try thr.clear(state.tty.f.writer(), .CurrentLine);
    try thr.moveCol(state.tty.f.writer(), 0);
    if (try state.tty.f.write("/") == 0) return error.EEOF;

    var termbuilder = std.ArrayList(u8).init(state.a);
    defer termbuilder.deinit();

    while (true) {
        var c: [1]u8 = undefined;
        if (try state.tty.f.read(&c) == 0) return error.EEOF;
        if (c[0] == '\r') break; // newline
        //

        if (c[0] == '\x7F') {
            if (termbuilder.items.len != 0) {
                _ = termbuilder.pop();
                try thr.moveLeft(state.tty.f.writer(), 1);
                try thr.clear(state.tty.f.writer(), .UntilNewLine);
            }
            continue;
        }

        try termbuilder.append(c[0]);
        if (try state.tty.f.write(&c) == 0) return error.EEOF;
    }

    if (termbuilder.items.len == 0) return false;

    const term = try termbuilder.toOwnedSlice();

    var loc = std.ArrayList(State.Pos).init(state.a);
    defer loc.deinit();

    for (state.lines, 0..) |line, y| {
        if (line.len < term.len) continue;

        // std.mem.tokenizeSequence;
        for (0..line.len - term.len) |x| {
            if (std.mem.eql(u8, line[x .. x + term.len], term)) {
                try loc.append(.{ .x = x, .y = y });
            }
        }
    }

    if (loc.items.len == 0) {
        state.a.free(term);
        return false;
    } else {
        // clear the privous search term if any
        if (state.search) |search| search.deinit(state.a);
        state.search = .{ .term = term, .locations = try loc.toOwnedSlice() };
        state.position = state.search.?.locations[0].y;
        return true;
    }
}

pub fn nextSearch(state: *State, count: usize) void {
    if (state.search) |*search| {
        search.index += count;
        search.index %= search.locations.len;
        state.position = search.locations[search.index].y;
    }
}

/// Scrolls the position down respecting a given maxiumum. Returns true if the
/// position changed, false otherwise.
fn scrollDown(position: *usize, amount: usize, maxiumum: usize) void {
    if (position.* == maxiumum) return;
    position.* = @min(position.* + amount, maxiumum);
}

/// Scrolls the position up without underflow. Returns true if the position
/// changed, false otherwise.
fn scrollUp(position: *usize, amount: usize) void {
    if (position.* == 0) return;
    position.* = if (position.* < amount) 0 else position.* - amount;
}

fn render(state: *State) !void {
    var screenbuffer = std.ArrayList(u8).init(state.a);
    defer screenbuffer.deinit();

    var writer = screenbuffer.writer();

    try thr.moveTo(writer, 0, 0);
    try thr.clear(writer, .All);

    var locindex: usize = 0;
    for (0..state.y - 1) |ln| {
        const y = ln + state.position;
        if (y >= state.lines.len) {
            try writer.writeAll("~");
            try thr.nextLine(writer, 1);
            continue;
        }
        const line = state.lines[y];

        // trim the line with no wrapping
        const bytes = if (line.len < state.x) line else line[0 .. state.x - 1];

        if (state.search) |search| {
            // if there are any terms that were cut by line wrap skip them here
            while (locindex < search.locations.len and search.locations[locindex].y < y) locindex += 1;

            var skipuntil: usize = 0;
            for (bytes, 0..) |byte, x| {
                if (x < skipuntil) continue;

                if (locindex < search.locations.len and search.locations[locindex].y == y and search.locations[locindex].x == x) {
                    // fg = 38; color | reset = 39
                    // bg = 48; color | reset = 49
                    // ul = 58; color | reset = 59
                    //
                    // colors:
                    // - 5;[1-15]
                    // user defined colors
                    // - 2;{r};{g};{b}

                    // set color -        esc code   set bg     color11   color cmd
                    try writer.writeAll("\x1B[" ++ "48;" ++ "5;11" ++ "m");

                    // just write the term and skip it
                    try writer.writeAll(search.term);
                    skipuntil = x + search.term.len;

                    // reset color -      esc code  reset bg  color cmd
                    try writer.writeAll("\x1B[" ++ "49" ++ "m");
                } else {
                    try writer.writeByte(byte);
                }
            }
        } else {
            try writer.writeAll(bytes);
        }
        try thr.nextLine(writer, 1);
    }

    if (state.status) |status| {
        try writer.writeAll(status);
        // state.a.free(status);
        state.status = null;
    } else if (state.repeat) |repeat| {
        try std.fmt.format(writer, "{}", .{repeat});
    }
    try writer.writeAll(":");

    try state.tty.f.writeAll(screenbuffer.items);

    // flush file
    try std.posix.syncfs(state.tty.f.handle);
}
