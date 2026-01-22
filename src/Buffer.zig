const root = @import("root.zig");
const std = root.std;
const lib = root.lib;
const km = root.km;
const undo = @import("undo.zig");
const rope = @import("rope.zig");

const State = root.State;

const Buffer = @This();
const LineStructure = struct { beg: usize, end: usize };

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

/// As a long term pivot strategy I will try to manage both the rope and the
/// lines structure until I can remove one
content: *rope.Rope,
contentlines: std.ArrayListUnmanaged(LineStructure) = .{},

undos: undo.UndoHistory,
undoing: bool = false,

row: usize = 0,
col: usize = 0,

// undos: Undo_Stack,
// redos: Undo_Stack,
// undo: Undo,

/// Row and Col in buffer
// cursor: Cursor,
// desired: lib.Vec2 = .{ .row = 0, .col = 0 },

filename: []const u8,
hasbackingfile: bool,

global_keymap: *km.Keymap,
local_keymap: km.Keymap,

input_state: km.KeySequence = .{
    // TODO: make this always be in sync with the buffer mode
    .mode = km.ModeId.Normal,
},
mode: km.ModeId = km.ModeId.Normal,

repeating: Repeating = .{},

pub const Line = std.ArrayListUnmanaged(u8);

/// This, alongside [`Visual`] should be the main way to interact with the
/// buffer and hopefully be largely opaque structures to allow me to change the
/// api over time
const Cursor = lib.Vec2; // @Vector(2, usize)

pub const VisualMode = Visual.Mode;
pub const Visual = struct {
    pub const Mode = enum { Range, Line, Block };

    mode: Visual.Mode = .Range,
    start: lib.Vec2,
    end: lib.Vec2,

    /// often called by consumers to not have to deal with inversted selections
    pub fn normalize(target: Visual) Visual {
        var start = target.start;
        var end = target.end;

        if (end.cmp(start) == .lt) std.mem.swap(lib.Vec2, &start, &end);

        const targ = Visual{ .mode = target.mode, .start = start, .end = end };

        std.debug.assert(targ.start.row <= targ.end.row);
        if (targ.start.row == targ.end.row) std.debug.assert(targ.start.col <= targ.end.col);

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
    global_keymap: *km.Keymap,
    filename: []const u8,
) !Buffer {
    const roper = try rope.Rope.create(a, "");
    var roperlines = std.ArrayListUnmanaged(LineStructure){};
    var index: usize = 0;

    var lines = std.ArrayList(Line).init(a);

    if (std.fs.cwd().openFile(filename, .{})) |file| {
        defer file.close();

        while (true) {
            const line = try file.reader().readUntilDelimiterOrEofAlloc(a, '\n', 128 * 1024) orelse break;
            // if (line.len == 0) break;

            const l = Line.fromOwnedSlice(line);
            try lines.append(l);

            try roper.append(line);
            try roperlines.append(a, .{ .beg = index, .end = index + line.len });
            index += line.len;
        }
    } else |err| root.log(@src(), .debug, "failed to open file: {}", .{err});

    return Buffer{
        .id = idgen.next(),
        .filename = filename,
        .hasbackingfile = true,

        .lines = lines.moveToUnmanaged(),

        .content = roper,
        .contentlines = roperlines,

        .undos = undo.UndoHistory.init(a),
        .undoing = false,
        .global_keymap = global_keymap,
        .local_keymap = km.Keymap.init(a),
        .alloc = a,
    };
}

pub fn deinit(buffer: *Buffer) void {
    for (buffer.lines.items) |*line| {
        line.deinit(buffer.alloc);
    }
    buffer.lines.deinit(buffer.alloc);
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

pub fn updateTarget(buffer: *Buffer, mode: Visual.Mode, start: lib.Vec2, end: lib.Vec2) void {
    if (buffer.target) |*t| {
        // if (start.cmp(t.start) == .lt) t.start = start;

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

/// Takes a point `start` and moves it right `count` units in the buffers space
pub fn moveRight(buffer: *const Buffer, start: Cursor, count: usize) lib.Vec2 {
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

pub fn moveLeft(buffer: *const Buffer, start: lib.Vec2, count: usize) lib.Vec2 {
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

pub fn save(buffer: *Buffer) !void {
    if (buffer.filename.len == 0) return;

    const f = try std.fs.cwd().createFile(buffer.filename, .{});
    defer f.close();

    for (buffer.lines.items) |line| {
        try f.writeAll(line.items);
        try f.writer().writeByte('\n');
    }
}

pub fn text_insert(buffer: *Buffer, cursor: Cursor, text: []const u8) !void {
    var hasnewline: bool = false;
    for (text) |ch| {
        hasnewline = hasnewline or (ch == '\n');

        // compat while switching to rope
        try buffer.__old_lines_insert_character(cursor, ch);
    }

    const index = getIndex(buffer, cursor);
    try buffer.content.insert(index, text);

    if (hasnewline) {
        root.log(@src(), .warn, "NYI", .{});

        // pub fn recalculate_rows(buffer: *Buffer) !void {
        //     buffer.contentlines.clearRetainingCapacity();
        //     var chunks = buffer.content.chunks(0, buffer.content.len());
        //     var index: usize = 0;
        //     while (chunks.next()) |chunk| {
        //         var lines = std.mem.splitScalar(u8, chunk, '\n');
        //         while (lines.next()) |line| {
        //             try buffer.contentlines.append(buffer.alloc, .{ .beg = index, .end = index + line.len });
        //             index += line.len;
        //         }
        //     }
        // }
    } else {
        shift_indices(buffer, cursor, text.len);
    }
}

/// TODO: there is problem when you hvae
/// ```
///  afa
/// |aaf
/// ```
/// the cursor moves but the lines arnt combined
///
pub fn text_delete(buffer: *Buffer, target: Visual) !void {
    root.log(@src(), .warn, "TODO: rope support", .{});
    const targ = target.normalize();

    if (!buffer.undoing) {
        const text_to_delete = buffer.gettarget(target) catch {
            // TODO: handle error, for now just don't record undo
            return;
        };
        defer text_to_delete.deinit();
        buffer.undos.recordDelete(targ.start, targ.end, text_to_delete.items) catch {}; // TODO: handle error
    }

    std.debug.assert(targ.start.row <= targ.end.row);
    if (targ.start.row == targ.end.row) std.debug.assert(targ.start.col <= targ.end.col);

    const a = buffer.alloc;
    root.log(@src(), .debug, "delete motion", .{});

    var remove_range_begin: ?usize = null;
    var remove_range_len: usize = 0;

    std.log.info("delete motion, target: {any}", .{targ});
    var row: usize = targ.start.row;
    while (row <= targ.end.row) : (row += 1) {
        const line: *Buffer.Line = &buffer.lines.items[row];

        var start = switch (targ.mode) {
            .Line => 0,
            .Range => if (row == targ.start.row) targ.start.col else 0,
            .Block => targ.start.col,
        };
        start = @min(start, line.items.len);

        const end = switch (targ.mode) {
            .Line => line.items.len,
            .Range => if (row == targ.end.row) @min(targ.end.col, line.items.len) else line.items.len,
            .Block => targ.end.col,
        };

        const iswholeline = switch (targ.mode) {
            .Line => true,
            // its not the only row and its the whole row
            .Range => (targ.start.row != targ.end.row) and start == 0 and end == line.items.len,
            .Block => false,
        };

        std.log.info("row: {d}, start: {d}, end: {d}, iswholeline: {}", .{ row, start, end, iswholeline });

        if (iswholeline) {
            if (remove_range_begin) |_| {
                remove_range_len += 1;
            } else {
                remove_range_begin = row;
                remove_range_len = 1;
            }
            line.deinit(a);
        } else {
            line.replaceRangeAssumeCapacity(a, start, end - start, &.{}); // never allocates
        }
    }

    if (remove_range_begin) |rrange| {
        buffer.lines.replaceRangeAssumeCapacity(a, rrange, remove_range_len, &.{}); // never allocates
    }

    buffer.movecursor(targ.start);
}

pub fn text_replace(buffer: *Buffer, target: Visual, ch: u8) !void {
    const targ = target.normalize();

    var row: usize = targ.start.row;
    while (row <= targ.end.row) : (row += 1) {
        const line: *Buffer.Line = &buffer.lines.items[row];

        var start = switch (targ.mode) {
            .Line => 0,
            .Range => if (row == targ.start.row) targ.start.col else 0,
            .Block => targ.start.col,
        };
        start = @min(start, line.items.len);

        const end = switch (targ.mode) {
            .Line => line.items.len,
            .Range => if (row == targ.end.row) @min(targ.end.col, line.items.len) else line.items.len,
            .Block => targ.end.col,
        };

        for (line.items[start..end]) |*och| {
            och.* = ch;
        }
    }
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

    var row: usize = targ.start.row;
    while (row <= targ.end.row) : (row += 1) {
        if (row != targ.start.row) try buf.append('\n');

        const line: *Buffer.Line = &buffer.lines.items[row];

        var start = switch (targ.mode) {
            .Line => 0,
            .Range => if (row == targ.start.row) targ.start.col else 0,
            .Block => targ.start.col,
        };
        start = @min(start, line.items.len);

        const end = switch (targ.mode) {
            .Line => line.items.len,
            .Range => if (row == targ.end.row) @min(targ.end.col, line.items.len) else line.items.len,
            .Block => targ.end.col,
        };

        try buf.appendSlice(line.items[start..end]);
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

/// Convertes a cursor into and index into the rope buffer.
fn getIndex(buffer: *const Buffer, cursor: Cursor) usize {
    // std.debug.assert(cursor.row < buffer.contentlines.items.len);
    const line = buffer.contentlines.items[cursor.row];
    // std.debug.assert(line.beg + cursor.col < line.end);
    return line.beg + cursor.col;
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

/// DEPRICATED: just insert the text
fn __old_lines_insert_newline(buffer: *Buffer, a: std.mem.Allocator) !void {
    var line = &buffer.lines.items[buffer.row];

    const after = try a.dupe(u8, line.items[buffer.col..]);

    line.items.len = buffer.col;

    const nl = Line{ .items = after, .capacity = after.len };

    buffer.row += 1;
    buffer.col = 0;

    try buffer.lines.insert(a, buffer.row, nl);

    // TODO: indent the cursor
}

/// DEPRICATED: see text_insert
fn __old_lines_insert_character(buffer: *Buffer, cursor: Cursor, ch: u8) !void {
    if (ch == '\n') {
        root.log(@src(), .warn, "`insert_character` should not be used for newlines", .{});
        try buffer.__old_lines_insert_newline(buffer.alloc);
        return;
    }

    if (!buffer.undoing) {
        try buffer.undos.recordInsert(buffer.position(), &.{ch});
    }

    var line = &buffer.lines.items[cursor.row];
    try line.insert(buffer.alloc, cursor.col, ch);
    buffer.col += 1;

    // state.cur_undo.end = buffer.cursor;
}
