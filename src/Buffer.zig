const root = @import("root.zig");
const std = root.std;
const lib = root.lib;
const km = root.km;
const undo = @import("undo.zig");
const rope = @import("rope.zig");

const State = root.State;

const Buffer = @This();
const Cursor = lib.Vec2;

const LineStructure = struct { beg: usize, end: usize };
const usenewthinger = false;

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

pub fn setMode(buffer: *Buffer, mode: km.ModeId) void {
    buffer.mode = mode;

    buffer.input_state.mode = mode;
    // is this corrent?
    buffer.input_state.len = 0;

    buffer.target = null;
}

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
    } else |_| {}

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

pub fn updateTarget(buffer: *Buffer, mode: Visual.Mode, start: lib.Vec2, end: lib.Vec2) void {
    if (buffer.target) |*t| {
        // if (t.start.cmp(start) == .gt) t.start = start;
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

/// Convertes a cursor into and index into the rope buffer.
fn getIndex(buffer: *const Buffer, cursor: Cursor) usize {
    _ = buffer;
    _ = cursor;

    unreachable;
}

pub fn insertCharacter(buffer: *Buffer, ch: u8) !void {
    if (usenewthinger) {
        const index = getIndex(buffer, buffer.position());
        try buffer.content.insert(index, &.{ch});

        // split the line
        if (ch == '\n') {
            const row = &buffer.contentlines.items[buffer.row];

            const end = row.end;
            row.end = row.beg + buffer.col;

            try buffer.contentlines.insert(buffer.alloc, buffer.row, .{ .beg = row.end, .end = end });
        }

        buffer.contentlines.items[buffer.row].end += 1;
        // TODO: use reactive programing to lazyily calculate the rows by just making each subsequent row depend on the last
        for (buffer.contentlines.items[buffer.row + 1 ..]) |*r| {
            r.beg += 1;
            r.end += 1;
        }
    }

    if (!buffer.undoing) {
        try buffer.undos.recordInsert(buffer.position(), &.{ch});
    }
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

pub fn delete_character(buffer: *Buffer, a: std.mem.Allocator) !void {
    if (buffer.col == 0 and buffer.row == 0) {
        // nothing to delete
        return;
    }

    if (buffer.col == 0) {
        // get the coluimn now before its length changes
        if (!buffer.undoing) {
            const deleted_text = &.{'\n'};
            try buffer.undos.recordDelete(buffer.position(), buffer.position(), deleted_text);
        }
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
        if (!buffer.undoing) {
            const deleted_char = buffer.lines.items[buffer.row].items[buffer.col - 1];
            try buffer.undos.recordDelete(buffer.position(), buffer.position(), &.{deleted_char});
        }

        buffer.col -= 1;

        var line = &buffer.lines.items[buffer.row];
        _ = line.orderedRemove(buffer.col);
    }
}

pub fn insertText(buffer: *Buffer, text: []const u8, location: Cursor) !void {
    _ = buffer;
    _ = text;
    _ = location;

    @panic("TODO");
}

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

pub fn replace(buffer: *Buffer, target: Visual, ch: u8) !void {
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

pub fn delete(buffer: *Buffer, target: Visual) !void {
    if (!buffer.undoing) {
        const text_to_delete = buffer.gettarget(target) catch {
            // TODO: handle error, for now just don't record undo
            return;
        };
        defer text_to_delete.deinit();
        const normalized_target = target.normalize();
        buffer.undos.recordDelete(normalized_target.start, normalized_target.end, text_to_delete.items) catch {}; // TODO: handle error
    }
    const targ = target.normalize();

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
            line.replaceRange(a, start, end - start, &.{}) catch unreachable; // never allocates
        }
    }

    if (remove_range_begin) |rrange| {
        buffer.lines.replaceRange(a, rrange, remove_range_len, &.{}) catch unreachable; // never allocates
    }

    buffer.movecursor(targ.start);
}

pub fn movecursor(buffer: *Buffer, pos: lib.Vec2) void {
    // TODO: set desired and compute from their
    buffer.row = pos.row;
    buffer.col = pos.col;
}

pub fn getchar(buffer: *Buffer, pos: lib.Vec2) ?u8 {
    if (pos.row >= buffer.lines.items.len) return null;

    const line = &buffer.lines.items[pos.row];
    if (pos.col >= line.items.len) return null;

    return line.items[pos.col];
}

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
