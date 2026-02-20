const root = @import("root.zig");
const std = root.std;
const lib = root.lib;
const km = root.km;
const undo = @import("undo.zig");
const rope = @import("rope.zig");
const State = root.State;
const testing = std.testing;

const Buffer = @This();
pub const LineStructure = struct { beg: usize, end: usize };

alloc: std.mem.Allocator,

/// Unique id for this buffer, never changes once created
id: usize,

target: ?Visual = null,

content: *rope.Rope,
contentlines: std.ArrayListUnmanaged(LineStructure) = .{},

undos: undo.UndoHistory,
undoing: bool = false,

row: usize = 0,
col: usize = 0,

filename: []const u8,
hasbackingfile: bool,

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
    var roperlines = std.ArrayListUnmanaged(LineStructure){};
    var index: usize = 0;

    if (std.fs.cwd().openFile(filename, .{})) |file| {
        defer file.close();

        while (true) {
            const line = try file.reader().readUntilDelimiterOrEofAlloc(a, '\n', 128 * 1024) orelse break;

            try roper.append(line);
            try roperlines.append(a, .{ .beg = index, .end = index + line.len });
            index += line.len;
        }
    } else |err| root.log(@src(), .debug, "failed to open file: {}", .{err});

    if (roperlines.items.len == 0) {
        try roperlines.append(a, .{ .beg = 0, .end = 0 });
    }

    return Buffer{
        .id = idgen.next(),
        .filename = filename,
        .hasbackingfile = true,

        .content = roper,
        .contentlines = roperlines,

        .undos = undo.UndoHistory.init(a),
        .undoing = false,
        .global_keymap = keymaps,
        .local_keymap = km.Keymap.init(a),
        .alloc = a,
    };
}

// pub fn initString(
//     a: std.mem.Allocator,
//     global_keymap: *km.Keymap,
//     filename: []const u8,
//     content: []const u8,
// ) !Buffer {
//     const roper = try rope.Rope.create(a, "");
//     try roper.append(content);

//     var roperlines = std.ArrayListUnmanaged(LineStructure){};

//     try roperlines.append(a, .{ .beg = index, .end = index + line.len });

//     var lines = std.ArrayList(Line).init(a);

//     return Buffer{
//         .id = idgen.next(),
//         .filename = filename,
//         .hasbackingfile = true,

//         .lines = lines.moveToUnmanaged(),

//         .content = roper,
//         .contentlines = roperlines,

//         .undos = undo.UndoHistory.init(a),
//         .undoing = false,
//         .global_keymap = global_keymap,
//         .local_keymap = km.Keymap.init(a),
//         .alloc = a,
//     };
// }

pub fn deinit(buffer: *Buffer) void {
    buffer.content.destroy();
    buffer.contentlines.deinit(buffer.alloc);

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
    return buffer.contentlines.items.len;
}

pub fn lineCount(buffer: *const Buffer) usize {
    return @intCast(buffer.content.line_count());
}

pub fn getLine(buffer: *const Buffer, row: usize) !std.ArrayList(u8) {
    var result = std.ArrayList(u8).init(buffer.alloc);
    if (row >= buffer.contentlines.items.len) return result;
    const line = buffer.contentlines.items[row];
    const len = line.end - line.beg;
    if (len == 0) return result;
    var slice = buffer.content.chunks(line.beg, line.end);
    while (slice.next()) |chunk| {
        try result.appendSlice(chunk);
    }
    return result;
}

pub fn getLineLen(buffer: *const Buffer, row: usize) usize {
    if (row >= buffer.contentlines.items.len) return 0;
    const line = buffer.contentlines.items[row];
    return line.end - line.beg;
}

pub fn getChar(buffer: *const Buffer, row: usize, col: usize) ?u8 {
    if (row >= buffer.contentlines.items.len) return null;
    const line = buffer.contentlines.items[row];
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
    if (buffer.filename.len == 0) return;

    const f = try std.fs.cwd().createFile(buffer.filename, .{});
    defer f.close();

    var chunks = buffer.content.chunks(0, buffer.content.len());
    while (chunks.next()) |chunk| {
        try f.writeAll(chunk);
        try f.writer().writeByte('\n');
    }
}

pub fn text_insert(buffer: *Buffer, cursor: Cursor, text: []const u8) !void {
    const index = getIndex(buffer, cursor);
    buffer.content.insert(index, text);

    try recalculate_contentlines(buffer);
}

fn recalculate_contentlines(buffer: *Buffer) !void {
    buffer.contentlines.clearRetainingCapacity();

    if (buffer.content.len() == 0) {
        try buffer.contentlines.append(buffer.alloc, .{ .beg = 0, .end = 0 });
        return;
    }

    var byte_index: usize = 0;
    var line_beg: usize = 0;

    while (byte_index < buffer.content.len()) {
        const slice = buffer.content.get_scan(byte_index) orelse break;
        for (slice, 0..) |ch, i| {
            if (ch == '\n') {
                try buffer.contentlines.append(buffer.alloc, .{
                    .beg = line_beg,
                    .end = byte_index + i,
                });
                line_beg = byte_index + i + 1;
            }
        }
        byte_index += slice.len;
    }

    if (line_beg <= buffer.content.len()) {
        try buffer.contentlines.append(buffer.alloc, .{
            .beg = line_beg,
            .end = buffer.content.len(),
        });
    }

    if (buffer.contentlines.items.len == 0) {
        try buffer.contentlines.append(buffer.alloc, .{ .beg = 0, .end = 0 });
    }
}

/// This function is inclusive on the lower bound and exclusive on the upper
/// bound.
pub fn text_delete(buffer: *Buffer, target: Visual) !void {
    const targ = target.normalize();

    if (!buffer.undoing) {
        const text_to_delete = buffer.gettarget(target) catch {
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

    try recalculate_contentlines(buffer);

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

    try recalculate_contentlines(buffer);
}

pub fn text_change(buffer: *Buffer, target: Visual, text: []const u8) !void {
    _ = buffer;
    _ = target;
    _ = text;

    @compileError("NYI");
}

/// I dont like this function as it is too vague, I think proviing a yank
/// functionality might be it
pub fn gettarget(buffer: *Buffer, target: Visual) !std.ArrayList(u8) {
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
    if (buffer.contentlines.items.len == 0) return 0;

    if (cursor.row >= buffer.contentlines.items.len) {
        return buffer.content.len();
    }

    const line = buffer.contentlines.items[cursor.row];
    const col = @min(cursor.col, line.end - line.beg);
    return line.beg + col;
}

/// Helper function
fn shift_indices(buffer: *Buffer, cursor: Cursor, count: usize) void {
    buffer.contentlines.items[cursor.row].end += count;
    // TODO: use reactive programing to lazyily calculate the rows by just
    // making each subsequent row depend on the last
    for (buffer.contentlines.items[cursor.row + 1 ..]) |*r| {
        r.beg += count;
        r.end += count;
    }
}

test "buffer insert character at end" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello");

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("hello", line0.items);
}

test "buffer insert multiple characters" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "abc");
    try buffer.text_insert(.{ .row = 0, .col = 3 }, "def");

    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("abcdef", line0.items);
}

test "buffer insert newline" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello\nworld");

    try testing.expectEqual(@as(usize, 2), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("hello", line0.items);
    const line1 = try buffer.getLine(1);
    defer line1.deinit();
    try testing.expectEqualStrings("world", line1.items);
}

test "buffer insert newline in middle" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "helloworld");
    try buffer.text_insert(.{ .row = 0, .col = 5 }, "\n");

    try testing.expectEqual(@as(usize, 2), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("hello", line0.items);
    const line1 = try buffer.getLine(1);
    defer line1.deinit();
    try testing.expectEqualStrings("world", line1.items);
}

test "buffer delete single character" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello");
    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 1 }, .end = .{ .row = 0, .col = 2 }, .mode = .Range });

    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("hllo", line0.items);
}

test "linewise delete works" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello\nworld");
    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 0 }, .end = .{ .row = 0, .col = 5 }, .mode = .Line });

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("world", line0.items);
}

test "buffer delete across lines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello\nworld");
    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 3 }, .end = .{ .row = 1, .col = 3 }, .mode = .Range });

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("helld", line0.items);
}

test "buffer delete line mode multiple lines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "line1\nline2\nline3");
    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 0 }, .end = .{ .row = 1, .col = 0 }, .mode = .Line });

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("line3", line0.items);
}

test "buffer delete block mode single line" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "abcdef");
    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 1 }, .end = .{ .row = 0, .col = 3 }, .mode = .Block });

    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("adef", line0.items);
}

test "buffer delete block mode multiple lines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "aaa\nbbb\nccc");
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
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try testing.expectEqual(@as(usize, 1), buffer.numLines());

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "line1\nline2");
    try testing.expectEqual(@as(usize, 2), buffer.numLines());
}

test "buffer getLineLen" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello");
    try testing.expectEqual(@as(usize, 5), buffer.getLineLen(0));

    try buffer.text_insert(.{ .row = 0, .col = 5 }, "\nworld");
    try testing.expectEqual(@as(usize, 5), buffer.getLineLen(0));
    try testing.expectEqual(@as(usize, 5), buffer.getLineLen(1));
}

test "buffer multiple inserts preserve lines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "line1\n");
    try buffer.text_insert(.{ .row = 1, .col = 0 }, "line2\n");
    try buffer.text_insert(.{ .row = 2, .col = 0 }, "line3");

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

test "buffer insert in middle of content" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "abc");
    try buffer.text_insert(.{ .row = 0, .col = 1 }, "X");

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("aXbc", l0.items);
}

test "buffer insert newline in middle preserves lines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "abcdef");
    try buffer.text_insert(.{ .row = 0, .col = 3 }, "\n");

    try testing.expectEqual(@as(usize, 2), buffer.numLines());
    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("abc", l0.items);
    const l1 = try buffer.getLine(1);
    defer l1.deinit();
    try testing.expectEqualStrings("def", l1.items);
}

test "buffer delete line then insert" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "line1\nline2\nline3");
    try buffer.text_delete(.{ .beg = .{ .row = 1, .col = 0 }, .end = .{ .row = 1, .col = 5 }, .mode = .Line });

    try testing.expectEqual(@as(usize, 2), buffer.numLines());
    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("line1", l0.items);
    const l1 = try buffer.getLine(1);
    defer l1.deinit();
    try testing.expectEqualStrings("line3", l1.items);
}

test "buffer delete preserves remaining lines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "a\nb\nc");
    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 0 }, .end = .{ .row = 0, .col = 1 }, .mode = .Range });

    try testing.expectEqual(@as(usize, 3), buffer.numLines());
    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("", l0.items);
    const l1 = try buffer.getLine(1);
    defer l1.deinit();
    try testing.expectEqualStrings("b", l1.items);
    const l2 = try buffer.getLine(2);
    defer l2.deinit();
    try testing.expectEqualStrings("c", l2.items);
}

test "buffer complex delete operations" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello\nworld\ntest");

    try buffer.text_delete(.{ .beg = .{ .row = 0, .col = 5 }, .end = .{ .row = 1, .col = 0 }, .mode = .Range });

    try testing.expectEqual(@as(usize, 2), buffer.numLines());
    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("helloworld", l0.items);
    const l1 = try buffer.getLine(1);
    defer l1.deinit();
    try testing.expectEqualStrings("test", l1.items);
}

test "buffer empty line handling" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "\n");

    try testing.expectEqual(@as(usize, 2), buffer.numLines());
    const l0 = try buffer.getLine(0);
    defer l0.deinit();
    try testing.expectEqualStrings("", l0.items);
    const l1 = try buffer.getLine(1);
    defer l1.deinit();
    try testing.expectEqualStrings("", l1.items);
}

test "buffer consecutive deletes" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "abc\ndef\nghi");

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

test "buffer moveRight at line end" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello");

    const end = buffer.moveRight(.{ .row = 0, .col = 3 }, 10);
    try testing.expectEqual(@as(usize, 0), end.row);
    try testing.expectEqual(@as(usize, 4), end.col);
}

test "buffer moveRight across lines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "ab\ncd");

    const end = buffer.moveRight(.{ .row = 0, .col = 0 }, 5);
    try testing.expectEqual(@as(usize, 1), end.row);
    try testing.expectEqual(@as(usize, 1), end.col);
}

test "buffer moveLeft at line beg" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello");

    const end = buffer.moveLeft(.{ .row = 0, .col = 3 }, 5);
    try testing.expectEqual(@as(usize, 0), end.row);
    try testing.expectEqual(@as(usize, 0), end.col);
}

test "buffer moveLeft across lines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "ab\ncd");

    const end = buffer.moveLeft(.{ .row = 1, .col = 1 }, 3);
    try testing.expectEqual(@as(usize, 0), end.row);
    try testing.expectEqual(@as(usize, 1), end.col);
}

test "buffer empty buffer" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    try testing.expectEqual(@as(usize, 0), buffer.getLineLen(0));
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("", line0.items);
}

test "buffer single char buffer" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "a");

    try testing.expectEqual(@as(usize, 1), buffer.numLines());
    try testing.expectEqual(@as(usize, 1), buffer.getLineLen(0));
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("a", line0.items);
}

test "buffer many newlines" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "a\nb\nc\nd\ne");

    try testing.expectEqual(@as(usize, 5), buffer.numLines());
    const line0 = try buffer.getLine(0);
    defer line0.deinit();
    try testing.expectEqualStrings("a", line0.items);
    const line1 = try buffer.getLine(1);
    defer line1.deinit();
    try testing.expectEqualStrings("b", line1.items);
    const line2 = try buffer.getLine(2);
    defer line2.deinit();
    try testing.expectEqualStrings("c", line2.items);
    const line3 = try buffer.getLine(3);
    defer line3.deinit();
    try testing.expectEqualStrings("d", line3.items);
    const line4 = try buffer.getLine(4);
    defer line4.deinit();
    try testing.expectEqualStrings("e", line4.items);
}

test "buffer gettarget single line" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello world");

    const target = try buffer.gettarget(.{ .beg = .{ .row = 0, .col = 0 }, .end = .{ .row = 0, .col = 5 }, .mode = .Range });
    defer target.deinit();

    try testing.expectEqualStrings("hello", target.items);
}

test "buffer gettarget multi line" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello\nworld");

    const target = try buffer.gettarget(.{ .beg = .{ .row = 0, .col = 0 }, .end = .{ .row = 1, .col = 5 }, .mode = .Range });
    defer target.deinit();

    try testing.expectEqualStrings("hello\nworld", target.items);
}

test "buffer rope len" {
    const a = testing.allocator;
    const global_keymap = try a.create(km.Keymap);
    defer a.destroy(global_keymap);
    global_keymap.* = km.Keymap.init(a);
    defer global_keymap.deinit();

    var buffer = try Buffer.init(a, global_keymap, "/dev/null");
    defer buffer.deinit();

    try buffer.text_insert(.{ .row = 0, .col = 0 }, "hello");
    try testing.expectEqual(@as(u64, 5), buffer.content.len());

    try buffer.text_insert(.{ .row = 0, .col = 5 }, " world");
    try testing.expectEqual(@as(u64, 11), buffer.content.len());
}
