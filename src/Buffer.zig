const root = @import("root.zig");
const std = root.std;
const lib = root.lib;
const km = root.km;
const undo = @import("undo.zig");
const rope = @import("rope.zig");
const State = root.State;
const testing = std.testing;

const Buffer = @This();

alloc: std.mem.Allocator,

/// Unique id for this buffer, never changes once created
id: usize,

target: ?Visual = null,

content: *rope.Rope,

undos: undo.UndoHistory,
undoing: bool = false,

row: usize = 0,
col: usize = 0,

filename: ?[]const u8,

global_keymap: *km.Keymap,
local_keymap: km.Keymap,

input_state: km.KeySequence = .{
    .mode = km.ModeId.Normal,
},
mode: km.ModeId = km.ModeId.Normal,

repeating: Repeating = .{},

/// This, alongside [`Visual`] should be the main way to interact with the
/// buffer and hopefully be largely opaque structures to allow me to change the
/// api over time
pub const Cursor = lib.Vec2;

pub const VisualMode = Visual.Mode;
pub const Visual = struct {
    pub const Mode = enum { Range, Line, Block };

    mode: Visual.Mode = .Range,
    beg: lib.Vec2,
    end: lib.Vec2,

    /// often called by consumers to not have to deal with inversted selections
    pub fn normalize(target: Visual) Visual {
        var beg = target.beg;
        var end = target.end;

        if (end.cmp(beg) == .lt) std.mem.swap(lib.Vec2, &beg, &end);

        const targ = Visual{ .mode = target.mode, .beg = beg, .end = end };

        std.debug.assert(targ.beg.row <= targ.end.row);
        if (targ.beg.row == targ.end.row) std.debug.assert(targ.beg.col <= targ.end.col);

        return targ;
    }
};

pub const Repeating = struct {
    is: bool = false,
    count: usize = 0,

    pub inline fn reset(self: *Repeating) void {
        self.is = false;
        self.count = 0;
    }

    pub inline fn take(self: *Repeating) usize {
        const count = self.some() orelse 1;
        std.debug.assert(count != 0);

        self.reset();
        return count;
    }

    pub inline fn some(self: *Repeating) ?usize {
        if (self.is) return self.count;
        return null;
    }
};

pub fn init(
    a: std.mem.Allocator,
    keymaps: *km.Keymap,
    filename: []const u8,
) !Buffer {
    const roper = try rope.Rope.create(a, "");

    if (std.fs.cwd().openFile(filename, .{})) |file| {
        defer file.close();

        while (true) {
            const line = try file.reader().readUntilDelimiterOrEofAlloc(a, '\n', 128 * 1024) orelse break;
            try roper.append(line);
            try roper.append("\n");
        }
    } else |err| root.log(@src(), .debug, "failed to open file: {}", .{err});

    return Buffer{
        .id = idgen.next(),
        .filename = filename,

        .content = roper,

        .undos = undo.UndoHistory.init(a),
        .undoing = false,
        .global_keymap = keymaps,
        .local_keymap = km.Keymap.init(a),
        .alloc = a,
    };
}

/// Creates a new buffer from a string. There is no backing file set on
/// initialization.
pub fn initString(
    a: std.mem.Allocator,
    keymaps: *km.Keymap,
    content: []const u8,
) !Buffer {
    const roper = try rope.Rope.create(a, content);

    return Buffer{
        .id = idgen.next(),
        .filename = null,

        .content = roper,

        .undos = undo.UndoHistory.init(a),
        .undoing = false,
        .global_keymap = keymaps,
        .local_keymap = km.Keymap.init(a),
        .alloc = a,
    };
}

pub fn deinit(buffer: *Buffer) void {
    buffer.content.destroy();

    buffer.undos.deinit();
    buffer.local_keymap.deinit();

    buffer.* = undefined;
}

pub fn position(buffer: *Buffer) lib.Vec2 {
    if (buffer.target) |t| return t.end;
    return .{ .row = buffer.row, .col = buffer.col };
}

pub fn setMode(buffer: *Buffer, mode: km.ModeId) void {
    buffer.mode = mode;
    buffer.input_state.mode = mode;

    // is this correct?
    buffer.input_state.len = 0;

    buffer.target = null;
}

pub fn updateTarget(buffer: *Buffer, mode: Visual.Mode, beg: lib.Vec2, end: lib.Vec2) void {
    if (buffer.target) |*t| {
        // if (beg.cmp(t.beg) == .lt) t.beg = beg;

        t.end = end;
        t.mode = mode;
    } else {
        buffer.target = .{
            .mode = mode,
            .beg = beg,
            .end = end,
        };
    }
}

pub fn numLines(buffer: *const Buffer) usize {
    const len = buffer.content.len();
    if (len == 0) return 1; // Empty buffer has one empty line
    const newlines = buffer.content.getLineCount();
    return newlines + 1;
}

pub fn lineCount(buffer: *const Buffer) usize {
    return buffer.numLines();
}

/// Gets the byte range for a given row.
/// If row is out of bounds, returns the last row's data.
pub fn getRowData(buffer: *const Buffer, row: usize) rope.Rope.RowData {
    return buffer.content.getRowData(@intCast(row));
}

pub fn getLine(buffer: *const Buffer, row: usize) !std.ArrayList(u8) {
    var result = std.ArrayList(u8).init(buffer.alloc);
    const line = buffer.getRowData(row);
    const len = line.end - line.beg;
    if (len == 0) return result;
    var slice = buffer.content.chunks(line.beg, line.end);
    while (slice.next()) |chunk| {
        try result.appendSlice(chunk);
    }
    return result;
}

pub fn getLineLen(buffer: *const Buffer, row: usize) usize {
    const line = buffer.getRowData(row);
    return line.end - line.beg;
}

pub fn getChar(buffer: *const Buffer, row: usize, col: usize) ?u8 {
    const line = buffer.getRowData(row);
    if (col >= line.end - line.beg) return null;
    const index = line.beg + col;
    return buffer.content.get(index);
}

/// Takes a point `beg` and moves it right `count` units in the buffers space
pub fn moveRight(buffer: *const Buffer, beg: Cursor, count: usize) lib.Vec2 {
    var end = beg;

    var c = count;
    while (c > 0) {
        const num_lines = buffer.numLines();
        if (end.row >= num_lines) break;
        const line_len = buffer.getLineLen(end.row);
        if (end.col + c >= line_len) {
            c -= line_len - end.col;
            if (end.row < num_lines - 1) {
                end.col = 0;
                end.row += 1;
            } else {
                end.col = if (line_len > 0) line_len - 1 else 0;
                break;
            }
        } else {
            end.col += c;
            c = 0;
        }
    }

    return end;
}

pub fn moveLeft(buffer: *const Buffer, beg: lib.Vec2, count: usize) lib.Vec2 {
    var end = beg;

    var c = count;
    while (c > 0) {
        if (end.col >= c) {
            end.col -= c;
            c = 0;
        } else {
            c -= end.col + 1;
            if (end.row > 0) {
                end.row -= 1;
                end.col = buffer.getLineLen(end.row);
            } else {
                end.col = 0;
                c = 0;
            }
        }
    }

    return end;
}

pub fn save(buffer: *Buffer) !void {
    const filename = buffer.filename orelse return;

    const f = try std.fs.cwd().createFile(filename, .{});
    defer f.close();

    var chunks = buffer.content.chunks(0, buffer.content.len());
    while (chunks.next()) |chunk| {
        try f.writeAll(chunk);
        try f.writer().writeByte('\n');
    }
}

pub fn textInsert(buffer: *Buffer, cursor: Cursor, text: []const u8) !void {
    const index = getIndex(buffer, cursor);
    buffer.content.insert(index, text);
}

/// This function is inclusive on the lower bound and exclusive on the upper
/// bound.
pub fn text_delete(buffer: *Buffer, target: Visual) !void {
    const targ = target.normalize();

    if (!buffer.undoing) {
        const text_to_delete = buffer.getTarget(target) catch {
            return;
        };
        defer text_to_delete.deinit();
        buffer.undos.recordDelete(targ.beg, targ.end, text_to_delete.items) catch {};
    }

    var del_beg = targ.beg;
    var del_end = targ.end;

    switch (targ.mode) {
        .Range => {
            std.debug.assert(del_beg.row <= del_end.row);
            if (del_beg.row == del_end.row) std.debug.assert(del_beg.col <= del_end.col);
            const beg_index = getIndex(buffer, del_beg);
            const end_index = getIndex(buffer, del_end);
            buffer.content.delete_range(beg_index, end_index);
        },
        .Line => {
            del_beg = .{ .row = del_beg.row, .col = 0 };
            del_end = .{ .row = del_end.row + 1, .col = 0 };
            const beg_index = getIndex(buffer, del_beg);
            const end_index = getIndex(buffer, del_end);
            buffer.content.delete_range(beg_index, end_index);
        },
        .Block => {
            const start_col = @min(del_beg.col, del_end.col);
            const end_col = @max(del_beg.col, del_end.col);
            const start_row = @min(del_beg.row, del_end.row);
            const end_row = @max(del_beg.row, del_end.row);

            if (start_row == end_row) {
                const line_len = buffer.getLineLen(start_row);
                const sc = @min(start_col, line_len);
                const ec = @min(end_col, line_len);
                if (sc < ec) {
                    const beg_idx = getIndex(buffer, .{ .row = start_row, .col = sc });
                    const end_idx = getIndex(buffer, .{ .row = start_row, .col = ec });
                    buffer.content.delete_range(beg_idx, end_idx);
                }
            } else {
                var row = end_row;
                while (row > start_row) : (row -= 1) {
                    const line_len = buffer.getLineLen(row);
                    const sc = @min(start_col, line_len);
                    const ec = @min(end_col, line_len);
                    if (sc < ec) {
                        const beg_idx = getIndex(buffer, .{ .row = row, .col = sc });
                        const end_idx = getIndex(buffer, .{ .row = row, .col = ec });
                        buffer.content.delete_range(beg_idx, end_idx);
                    }
                }
                {
                    const line_len = buffer.getLineLen(start_row);
                    const sc = @min(start_col, line_len);
                    const ec = @min(end_col, line_len);
                    if (sc < ec) {
                        const beg_idx = getIndex(buffer, .{ .row = start_row, .col = sc });
                        const end_idx = getIndex(buffer, .{ .row = start_row, .col = ec });
                        buffer.content.delete_range(beg_idx, end_idx);
                    }
                }
            }
            del_beg = .{ .row = start_row, .col = start_col };
        },
    }

    buffer.movecursor(del_beg);
}

pub fn text_replace(buffer: *Buffer, target: Visual, ch: u8) !void {
    const targ = target.normalize();

    const start_index = getIndex(buffer, targ.beg);
    const end_index = getIndex(buffer, .{ .row = targ.end.row, .col = targ.end.col + 1 });

    var chunks = buffer.content.chunks(start_index, end_index);
    var buf: [256]u8 = undefined;
    var offset: usize = 0;
    while (chunks.next()) |chunk| {
        const copy_len = @min(chunk.len, buf.len - offset);
        @memset(buf[offset .. offset + copy_len], ch);
        offset += copy_len;
    }

    buffer.content.delete_range(start_index, end_index);
    const replacement = buf[0..offset];
    buffer.content.insert(start_index, replacement);
}

pub fn text_change(buffer: *Buffer, target: Visual, text: []const u8) !void {
    _ = buffer;
    _ = target;
    _ = text;

    @compileError("NYI");
}

/// I dont like this function as it is too vague, I think proviing a yank
/// functionality might be it
pub fn getTarget(buffer: *Buffer, target: Visual) !std.ArrayList(u8) {
    const targ = target.normalize();

    var buf = std.ArrayList(u8).init(buffer.alloc);

    switch (targ.mode) {
        .Range => {
            const start_index = getIndex(buffer, targ.beg);
            const end_index = getIndex(buffer, targ.end);
            var chunks = buffer.content.chunks(start_index, end_index);
            while (chunks.next()) |chunk| {
                try buf.appendSlice(chunk);
            }
        },
        .Line => {
            for (targ.beg.row..targ.end.row + 1) |row| {
                if (row > targ.beg.row) try buf.append('\n');
                const line = try buffer.getLine(row);
                defer line.deinit();
                try buf.appendSlice(line.items);
            }
        },
        .Block => {
            for (targ.beg.row..targ.end.row + 1) |row| {
                if (row > targ.beg.row) try buf.append('\n');
                const line = try buffer.getLine(row);
                defer line.deinit();
                const start = @min(targ.beg.col, line.items.len);
                const end = @min(targ.end.col, line.items.len);
                if (start < end) try buf.appendSlice(line.items[start..end]);
            }
        },
    }

    return buf;
}

pub fn movecursor(buffer: *Buffer, cursor: Cursor) void {
    // TODO: set desired and compute from there
    buffer.row = cursor.row;
    buffer.col = cursor.col;
}

/// No consumers so far
pub fn get(buffer: *Buffer, cursor: Cursor) ?u8 {
    const index = buffer.getIndex(cursor);
    return buffer.content.get(index);
}

/// using static for id assignment
pub const idgen = struct {
    var count: usize = 0;
    pub fn next() usize {
        count += 1;
        return count;
    }
};

// ----------------------------------------------------------------------------

/// Convertes a cursor into an index into the rope buffer.
fn getIndex(buffer: *const Buffer, cursor: Cursor) usize {
    const line = buffer.getRowData(cursor.row);
    if (line.beg == 0 and line.end == 0 and buffer.content.len() == 0) {
        return 0;
    }

    const col = @min(cursor.col, line.end - line.beg);
    return line.beg + col;
}

// ------------------------ Testing -----------------------

/// Static constants for testing using shims
const testvalues = struct {
    var keymaps: km.Keymap = .{
        .fallbacks = .{},
        .targeters = .{},
        .alloc = testing.allocator,
        .bindings = .{},
    };
};

test "buffer insert character at end" {
    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "");
    defer buffer.deinit();

    try buffer.textInsert(.{ .row = 0, .col = 0 }, "hello");

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("hello", line0.items);
}

test "buffer insert multiple lines" {
    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "");
    defer buffer.deinit();

    try buffer.textInsert(.{ .row = 0, .col = 0 }, "line1\nline2\nline3");
    try testing.expectEqual(@as(usize, 3), buffer.numLines());

    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("line1", l0.items);

    const l1 = try buffer.getLine(1);
    defer l1.deinit();
    try testing.expectEqualStrings("line2", l1.items);

    const l2 = try buffer.getLine(2);
    defer l2.deinit();
    try testing.expectEqualStrings("line3", l2.items);
}

test "buffer delete line mode multiple lines" {
    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "");
    defer buffer.deinit();

    try buffer.textInsert(.{ .row = 0, .col = 0 }, "line1\nline2\nline3");

    // Delete lines 0-1 in Line mode
    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 0 }, .end = .{ .row = 1, .col = 0 }, .mode = .Line });

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
}

test "buffer delete block mode multiple lines" {
    if (true) return error.SkipZigTest;

    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "");
    defer buffer.deinit();

    try buffer.textInsert(.{ .row = 0, .col = 0 }, "aaa\nbbb\nccc");
    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 0 }, .end = .{ .row = 2, .col = 2 }, .mode = .Block });

    try testing.expectEqual(@as(usize, 3), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("a", line0.items);
    const line1 = try buffer.getLine(1);
    defer line1.deinit();
    try testing.expectEqualStrings("b", line1.items);
    const line2 = try buffer.getLine(2);
    defer line2.deinit();
    try testing.expectEqualStrings("c", line2.items);
}

test "buffer line count" {
    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "");
    defer buffer.deinit();

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    try buffer.textInsert(.{ .row = 0, .col = 0 }, "line1\nline2");
    try testing.expectEqual(@as(usize, 2), buffer.numLines());
}

test "buffer getLineLen" {
    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "");
    defer buffer.deinit();

    try buffer.textInsert(.{ .row = 0, .col = 0 }, "hello");
    try testing.expectEqual(@as(usize, 5), buffer.getLineLen(0));

    try buffer.textInsert(.{ .row = 0, .col = 3 }, "s\nworld");
    try testing.expectEqual(@as(usize, 4), buffer.getLineLen(0));
    try testing.expectEqual(@as(usize, 7), buffer.getLineLen(1));
}

test "buffer multiple inserts preserve lines" {
    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "");
    defer buffer.deinit();

    try buffer.textInsert(.{ .row = 0, .col = 0 }, "line1\n");
    try buffer.textInsert(.{ .row = 1, .col = 0 }, "line2\n");
    try buffer.textInsert(.{ .row = 2, .col = 0 }, "line3");

    try testing.expectEqual(@as(usize, 3), buffer.numLines());

    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("line1", l0.items);
    const l1 = try buffer.getLine(1);
    defer l1.deinit();
    try testing.expectEqualStrings("line2", l1.items);
    const l2 = try buffer.getLine(2);
    defer l2.deinit();
    try testing.expectEqualStrings("line3", l2.items);
}

test "buffer consecutive deletes" {
    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "");
    defer buffer.deinit();

    try buffer.textInsert(.{ .row = 0, .col = 0 }, "abc\ndef\nghi");

    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 0 }, .end = .{ .row = 0, .col = 3 }, .mode = .Range });
    try testing.expectEqual(@as(usize, 3), buffer.numLines());
    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("", l0.items);

    try buffer.text_delete(.{ .beg = .{ .row = 1, .col = 0 }, .end = .{ .row = 1, .col = 3 }, .mode = .Range });
    try testing.expectEqual(@as(usize, 3), buffer.numLines());
    const l1 = try buffer.getLine(1);
    defer l1.deinit();
    try testing.expectEqualStrings("", l1.items);
}

test "buffer length adding newlines" {
    const a = testing.allocator;
    var buffer = try Buffer.initString(a, &testvalues.keymaps, "hello");
    defer buffer.deinit();

    try testing.expectEqual(@as(u64, 5), buffer.content.len());
    try buffer.textInsert(.{ .row = 0, .col = 5 }, "\nwonderful\nworld");
    try testing.expectEqual(@as(u64, 21), buffer.content.len());
    // getLineCount returns newline count, not line count
    try testing.expectEqual(@as(u64, 2), buffer.content.getLineCount());
}
