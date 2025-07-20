const root = @import("root.zig");
const std = root.std;
const lib = root.lib;
const km = root.km;

const State = root.State;

const Buffer = @This();

alloc: std.mem.Allocator,

/// Unique id for this buffer, never changes once created
id: usize,

// File mode
// mode: ModeId = ModeId.Normal,

/// Motion keys have two ways in which they select text, a region and a
/// point. A motion can set this structure to not null to indicate what it
/// wants. Then a selector runs using this data. The default one just sets the
/// cursor to target position. Some other common ones are `d` which deletes
/// text in the selection. The can also be user defined.
target: ?Visual = null,

/// literal data in the buffer
lines: std.ArrayListUnmanaged(Line),

row: usize = 0,
col: usize = 0,

// undos: Undo_Stack,
// redos: Undo_Stack,
// undo: Undo,

/// Row and Col in buffer
// cursor: lib.Vec2 = .{ .row = 0, .col = 0 },
// desired: lib.Vec2 = .{ .row = 0, .col = 0 },

/// Must be arena allocated, will not be freed
filename: []const u8,
hasbackingfile: bool,

/// Not owned, unless this is the scratch buffer
keymaps: *km.ModeToKeys,

curkeymap: ?*km.KeyMaps = null,

const Line = std.ArrayListUnmanaged(u8);

pub const Visual = struct {
    mode: VisualMode = .Range,
    start: lib.Vec2,
    end: lib.Vec2,
};
pub const VisualMode = enum {
    Range,
    Line,
    Block,
};

pub fn init(
    a: std.mem.Allocator,
    keymaps: *km.ModeToKeys,
    filename: []const u8,
) !Buffer {
    var lines = std.ArrayList(Line).init(a);

    if (std.fs.cwd().openFile(filename, .{})) |file| {
        defer file.close();

        while (true) {
            const line = try file.reader().readUntilDelimiterOrEofAlloc(a, '\n', 128 * 1024) orelse break;
            // if (line.len == 0) break;

            const l = Line.fromOwnedSlice(line);

            try lines.append(l);
        }
    } else |_| {}

    // not stable
    // const fid = std.hash.murmur.Murmur2_64.hash(filename);

    return Buffer{
        .id = idgen.next(),
        .filename = filename,
        .hasbackingfile = true,
        .lines = lines.moveToUnmanaged(),
        .keymaps = keymaps,
        .alloc = a,
    };
}

pub fn deinit(buffer: *Buffer) void {
    for (buffer.lines.items) |*line| {
        line.deinit(buffer.alloc);
    }
    buffer.lines.deinit(buffer.alloc);

    buffer.* = undefined;
}

pub fn getKeymap(buffer: *Buffer) *km.KeyMaps {
    return buffer.curkeymap orelse return buffer.keymaps.get(Buffer.ModeId.Normal).?;
}

pub fn setMode(buffer: *Buffer, mode: Buffer.ModeId) void {
    // buffer.mode = mode;
    const keymap = buffer.keymaps.get(mode) orelse {
        std.debug.print("no keymap for mode: {any}\n", .{mode});
        buffer.curkeymap = null;
        return;
    };
    // std.debug.print("set keymap for mode: {any}\n", .{mode});
    buffer.curkeymap = keymap;
}

pub fn updateTarget(buffer: *Buffer, mode: Buffer.VisualMode, start: lib.Vec2, end: lib.Vec2) void {
    if (buffer.target) |*t| {
        if (t.start.cmp(start) == .lt) t.start = start;
        t.end = end;
        t.mode = mode;
    } else {
        buffer.target = .{
            .mode = mode,
            .start = start,
            .end = end,
        };
    }
}

pub fn position(buffer: *Buffer) lib.Vec2 {
    if (buffer.target) |t| return t.end;

    return .{ .row = buffer.row, .col = buffer.col };
}

pub fn insertCharacter(buffer: *Buffer, ch: u8) !void {
    if (ch == '\n') {
        try buffer.newlineInsert(buffer.alloc);
        return;
    }

    var line = &buffer.lines.items[buffer.row];
    try line.insert(buffer.alloc, buffer.col, ch);
    // root.log(@src(), .debug, "inserted character {c} at row {d}, col {d}", .{ ch, buffer.row, buffer.col });
    buffer.col += 1;

    // state.cur_undo.end = buffer.cursor;
}

pub fn bufferDelete(buffer: *Buffer, a: std.mem.Allocator) !void {
    if (buffer.col == 0 and buffer.row == 0) {
        // nothing to delete
        return;
    }

    if (buffer.col == 0) {
        // get the coluimn now before its length changes
        buffer.col = buffer.lines.items[buffer.row - 1].items.len;

        // delete the last character of the previous line
        const line = &buffer.lines.items[buffer.row];
        const prev = &buffer.lines.items[buffer.row - 1];
        try prev.appendSlice(a, line.items);

        var oldline = buffer.lines.orderedRemove(buffer.row);
        oldline.deinit(a);

        buffer.row -= 1;
    } else {
        // delete the character before the cursor
        buffer.col -= 1;

        var line = &buffer.lines.items[buffer.row];
        _ = line.orderedRemove(buffer.col);
    }
}

// pub fn buffer_delete_ch(buffer: *Buffer, state: *State) void {
//     _ = buffer; // autofix
//     _ = state; // autofix
//     var undo = Undo{ };
//     undo.type = .INSERT_CHARS;
//     undo.start = buffer.cursor;
//     state.cur_undo = undo;
//     reset_command(state.*.clipboard.str, &state.*.clipboard.len);
//     buffer_yank_char(buffer, state);
//     buffer_delete_char(buffer, state);
//     state.*.cur_undo.end = buffer.*.cursor;
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }

// pub fn buffer_replace_ch(state: *State) void {
//     state.*.ch = frontend_getch(state.*.main_win);
//     buffer.*.data.data[buffer.*.cursor] = @as(u8, @bitCast(@as(i8, @truncate(state.*.ch))));
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }

// pub fn bufferDeleteSelection(buffer: *EditBuffer, selection: Tar) !void {
//     var start = arg_start;
//     _ = &start;
//     var end = arg_end;
//     _ = &end;
//     buffer_yank_selection(buffer, state, start, end);
//     var size: usize = end -% start;
//     _ = &size;
//     if (size >= buffer.*.data.count) {
//         size = buffer.*.data.count;
//     }
//     buffer.*.cursor = start;
//     if ((buffer.*.cursor +% size) > buffer.*.data.count) return;
//     if (state.*.cur_undo.data.capacity < size) {
//         state.*.cur_undo.data.capacity = size;
//         state.*.cur_undo.data.data = @as(*u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.cur_undo.data.data)), @sizeOf(u8) *% size))));
//         while (true) {
//             if (!(state.*.cur_undo.data.data != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//                 frontend_end();
//                 _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 166));
//                 _ = fprintf(stderr, "could not alloc");
//                 _ = fprintf(stderr, "\n");
//                 exit(@as(c_int, 1));
//             }
//             if (!false) break;
//         }
//     }
//     _ = strncpy(state.*.cur_undo.data.data, &buffer.*.data.data[buffer.*.cursor], size);
//     state.*.cur_undo.data.count = size;
//     _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% size])), buffer.*.data.count -% end);
//     buffer.*.data.count -%= size;
//     buffer_calculate_rows(buffer);
// }

// pub fn buffer_insert_selection(arg_buffer: *Buffer, arg_selection: *Data, arg_start: usize) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var selection = arg_selection;
//     _ = &selection;
//     var start = arg_start;
//     _ = &start;
//     buffer.*.cursor = start;
//     var size: usize = selection.*.count;
//     _ = &size;
//     if ((buffer.*.data.count +% size) >= buffer.*.data.capacity) {
//         buffer.*.data.capacity +%= size *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
//         buffer.*.data.data = @as(*u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(buffer.*.data.data)), (@sizeOf(u8) *% buffer.*.data.capacity) +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
//         while (true) {
//             if (!(buffer.*.data.data != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//                 frontend_end();
//                 _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 187));
//                 _ = fprintf(stderr, "could not alloc");
//                 _ = fprintf(stderr, "\n");
//                 exit(@as(c_int, 1));
//             }
//             if (!false) break;
//         }
//  }
//     _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% size])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), buffer.*.data.count -% buffer.*.cursor);
//     _ = strncpy(&buffer.*.data.data[buffer.*.cursor], selection.*.data, size);
//     buffer.*.data.count +%= size;
//     buffer_calculate_rows(buffer);
// }

/// Takes a point `start` and moves it right `count` units in the buffers space
pub fn moveRight(buffer: *Buffer, start: lib.Vec2, count: usize) lib.Vec2 {
    var end = start;

    var c = count;
    while (c > 0) {
        if (end.row >= buffer.lines.items.len) break;
        if (end.col + c >= buffer.lines.items[end.row].items.len) {
            c -= buffer.lines.items[end.row].items.len - end.col;
            if (end.row < buffer.lines.items.len - 1) {
                end.col = 0;
                end.row += 1;
            } else {
                // no where left to go
                end.col = buffer.lines.items[end.row].items.len - 1;
                break;
            }
        } else {
            end.col += c;
            c = 0;
        }
    }

    return end;
}

pub fn moveLeft(buffer: *Buffer, start: lib.Vec2, count: usize) lib.Vec2 {
    var end = start;

    var c = count;
    while (c > 0) {
        if (end.col >= c) {
            end.col -= c;
            c = 0;
        } else {
            c -= end.col + 1;
            if (end.row > 0) {
                end.row -= 1;
                end.col = buffer.lines.items[end.row].items.len;
            } else {
                end.col = 0; // can't go left anymore
                c = 0;
            }
        }
    }
    // buffer.desired = end;

    return end;
}

pub fn newlineInsert(buffer: *Buffer, a: std.mem.Allocator) !void {
    var line = &buffer.lines.items[buffer.row];

    const after = try a.dupe(u8, line.items[buffer.col..]);

    line.items.len = buffer.col;

    const nl = Line{ .items = after, .capacity = after.len };

    buffer.row += 1;
    buffer.col = 0;

    try buffer.lines.insert(a, buffer.row, nl);

    // TODO: indent the cursor
}

pub fn save(buffer: *Buffer) !void {
    if (buffer.filename.len == 0) return;

    const f = try std.fs.cwd().createFile(buffer.filename, .{});
    defer f.close();

    for (buffer.lines.items) |line| {
        try f.writeAll(line.items);
        try f.writer().writeByte('\n');
    }
}

/// using static for id assignment
pub const idgen = struct {
    var count: usize = 0;
    pub fn next() usize {
        count += 1;
        return count;
    }
};

// const Target = struct {
//     down: ?isize = null,
//     left: ?isize = null,
// };

pub const ModeId = struct {
    _: usize,

    pub fn from(str: []const u8) ModeId {
        var bytes: usize = 0;
        @memcpy(std.mem.asBytes(&bytes)[0..str.len], str);

        return .{ ._ = bytes };
    }

    pub const new = @compileError("TODO: walk the states maps and find the next a tag greater than 65535");

    pub fn toString(self: ModeId) []const u8 {
        return switch (self._) {
            0 => "NULL",
            'n' => "NORMAL",
            'i' => "INSERT",
            'v' => "VISUAL",
            'c' => "COMMAND",
            else => "UNKNOWN",
        };
    }

    pub fn chain(self: ModeId, next: u16) ModeId {
        // TODO: check for uniquness and overflow
        return .{ ._ = self._ + next };
    }

    // const static = struct {
    //     const id: usize = 65535;
    // };

    pub const Null: ModeId = .{ ._ = 0 };
    pub const Normal: ModeId = .{ ._ = 'n' };
    pub const Visual: ModeId = .{ ._ = 'v' };
    pub const Insert: ModeId = .{ ._ = 'i' };
    pub const Command: ModeId = .{ ._ = 'c' };

    test "MapId.from" {
        // I would be interested to see if these work on little endian machines
        try std.testing.expectEqual(ModeId.Normal, ModeId.from("n"));
        try std.testing.expectEqual(ModeId.Visual, ModeId.from("v"));
        try std.testing.expectEqual(ModeId.Insert, ModeId.from("i"));
    }

    test "ModeId comptime" {
        try std.testing.expectEqualStrings("NORMAL", comptime ModeId.from("n").toString());
        try std.testing.expectEqualStrings("VISUAL", comptime ModeId.from("v").toString());
        try std.testing.expectEqualStrings("INSERT", comptime ModeId.from("i").toString());

        try std.testing.expectEqualStrings("UNKNOWN", comptime ModeId.from("x").toString());
    }
};
