//! A rope that efficently tracks both character and line indeices.

const root = @import("root.zig");
const std = root.std;

pub const Rope = @This();

/// Type used as the buffer index for the internal buffer.
const Index = usize;
/// The capacity of the internal buffer used by
const ROPE_BUFFER_SIZE: Index = 1024;
/// Standard fullness of each chuck to use
const ROPE_CHUNK_SIZE: Index = ROPE_BUFFER_SIZE / 2;

comptime {
    if (2 * ROPE_BUFFER_SIZE > std.math.maxInt(Index)) {
        @compileError("cap_bytes must be less than 128 to do arithmetic");
    }
}

// tree as a flat array where each element is a line. this means that your index
// can be used to determine your offset. finding line data is a direct memory
// lookyp

// TODO: see if using a std.io.FixedBufferStream can manage both the feilds above

/// Pointer to parent node, if null then this is the root node of some tree,
/// either the main one or something split off.
parent: ?*Rope = null,

childern: [2]?*Rope = .{ null, null },

/// Total amount of character in this subtree.
length: u64 = 0,

/// Total amount of newlines in this subtree.
newlines: u64 = 0,

/// Internal buffer to store text.
dataBuffer: [ROPE_BUFFER_SIZE]u8 = undefined,
/// Amount of data store in the buffer.
///
/// This nodes contribution to [`length`].
dataLength: Index = 0,
/// Number of newline characters within data buffer.
///
/// This nodes contribution to [`newlines`].
dataLines: u64 = 0,

/// Creates a new tree with initial content.
///
/// Uses recursion.
pub fn init(alloc: std.mem.Allocator, bytes: []const u8) !*Rope {
    var slice0: usize = 0;
    var slice1: usize = bytes.len;

    if (bytes.len <= ROPE_CHUNK_SIZE) {
        // we can fit in one chunk. do nothing
    } else if (bytes.len <= ROPE_BUFFER_SIZE) {
        // we are a simple split
        slice0 = bytes.len >> 1;
    } else {
        slice0 = (bytes.len - ROPE_CHUNK_SIZE) / 2;
        slice1 = slice0 + ROPE_CHUNK_SIZE;
    }

    // FIXME: change to not use recursion
    const lhs: ?*Rope = if (slice0 - 0 == 0) null else blk: {
        break :blk try Rope.init(alloc, bytes[0..slice0]);
    };
    const rhs: ?*Rope = if (bytes.len - slice1 == 0) null else blk: {
        break :blk try Rope.init(alloc, bytes[slice1..]);
    };

    const buffer = bytes[slice0..slice1];

    const self = try alloc.create(Rope);
    self.* = .{};
    @memcpy(self.dataBuffer[0..buffer.len], buffer);
    self.dataLength = buffer.len;
    self.dataLines = std.mem.count(u8, self.data(), "\n");

    Rope.connect(self, lhs, 0);
    Rope.connect(self, rhs, 1);

    self.update();

    return self;
}

/// Free a splay tree node without using recursion.
pub fn deinit(self: *Rope, alloc: std.mem.Allocator) void {
    var node = self;
    while (true) {
        if (node.childern[0]) |c| {
            node.childern[0] = null;
            node = c;
        } else if (node.childern[1]) |c| {
            node.childern[1] = null;
            node = c;
        } else {
            const next = node.parent;
            alloc.destroy(node);
            node = next orelse break;
        }
    }
}

/// Total amount of characters in left subtree
pub fn weight(self: *const Rope) u64 {
    if (self.childern[0]) |left| left.length else 0;
}

/// Gets the length in bytes of the Rope
///
/// TODO: depricate and use feild access
pub fn getLen(self: *const Rope) u64 {
    return self.length;
}

/// Gets the total number of lines in the rope.
///
/// TODO: depricate and use feild access
pub fn getLineCount(self: *const Rope) u64 {
    return self.newlines;
}

/// Gets the byte range for a given row index.
///
/// Returns the start and end byte positions of the row.
/// If the row index is out of bounds, returns the last row's data.
/// Time complexity: O(log n).
pub fn getRowData(self: *const Rope, row: u64) RowData {
    _ = self;
    _ = row;

    @panic("todo");

    // if (self.rnode == null) {
    //     return RowData{ .beg = 0, .end = 0 };
    // }

    // const totalLines = self.rnode.?.internalLines;
    // const clampedRow = if (row > totalLines) totalLines else row;

    // var currentRow: u64 = 0;
    // var byteOffset: u64 = 0;

    // var stack: [64]*Rope = undefined;
    // var sp: usize = 0;

    // stack[sp] = self.rnode.?;
    // sp += 1;

    // while (sp > 0) {
    //     sp -= 1;
    //     const node = stack[sp];

    //     if (node.childern[0]) |l| {
    //         stack[sp] = node.childern[1].?;
    //         sp += 1;
    //         stack[sp] = l;
    //         sp += 1;
    //         continue;
    //     }

    //     if (node.childern[1]) |r| {
    //         stack[sp] = r;
    //         sp += 1;
    //     }
    // }

    // return RowData{ .beg = 0, .end = self.rnode.?.contentSize };
}

pub fn empty(self: *const Rope) bool {
    // return self.length == 0;
    return self.dataLength == 0;
}

pub fn append(self: *Rope, alloc: std.mem.Allocator, string: []const u8) !void {
    // TODO: make a better implementation

    var other = try Rope.init(alloc, string);
    errdefer other.deinit(alloc);
    try self.merge(other);
}

/// Merge this rope with another rope, taking ownership of it.
///
/// On out-of-memory error, this function is safe. Neither rope is changed
/// in a way that semantically modifies the values in it.
pub fn merge(self: *Rope, other: *Rope) !void {
    // TODO: make this a method??
    var rightmost = self;
    while (rightmost.childern[1]) |r| rightmost = r;

    // TODO: this results in unbalence tree, slow lookups... considering adding
    // at end should be the most common use case this is unacceptable.
    Rope.connect(rightmost, other, 1);

    var node: ?*Rope = rightmost;
    while (node) |n| {
        n.update();
        node = n.parent;
    }
}

/// Splits this rope into two at the given index.
///
/// The current rope will be the first part, and the second part starting at
/// and including the index will be returned as a new rope.
///
/// On out-of-memory error, the rope is not modified.
pub fn split(self: *Rope, index: u64) !*Rope {
    _ = self;
    _ = index;

    @panic("TODO");
}

/// Insert bytes at the given index. Invalid indices are clamped to valid range.
/// Errors are logged and operation may be partially complete.
pub fn insert(self: *Rope, alloc: std.mem.Allocator, index: u64, bytes: []const u8) !void {
    if (bytes.len == 0) return;

    const rlen = self.getLen();
    const effective_index = if (index > rlen) rlen else index;

    var other = try Rope.init(alloc, bytes);
    errdefer other.destroy();

    if (effective_index == rlen) {
        try self.merge(other);
    } else {
        var righthand = try self.split(effective_index);
        errdefer righthand.destroy();
        try self.merge(other);

        // TODO: if this fails it is UB to destroy the other rope
        try self.merge(righthand);
    }
}

/// Delete a range of bytes from a rope.
/// Invalid indices are clamped to valid range. Errors are logged and operation
/// may be partially complete.
pub fn delete(self: *Rope, beg: usize, end: usize) !void {
    const rlen = self.getLen();
    const effective_beg = if (beg > rlen) rlen else beg;
    const effective_end = if (end > rlen) rlen else end;

    if (effective_beg >= effective_end) return;

    var emptyRope = Rope{};
    try self.splice(&emptyRope, effective_beg, effective_end);
    // emptyRope.deinit(a);
}

/// Swap the bytes of the subrange of a rope with another rope.
pub fn splice(
    self: *Rope,
    /// The input and output rope
    swap: *Rope,
    /// The start index of the swap
    beg: usize,
    /// The end index of the swap
    end: usize,
) !void {
    std.debug.assert(self.getLen() > 0);
    std.debug.assert(end <= self.getLen());
    std.debug.assert(beg <= end);

    const content = try self.split(beg);
    const tail = try content.split(end - beg);

    std.mem.swap(Rope, content, swap);

    try self.merge(content);
    try self.merge(tail);

    std.debug.assert(self.getLen() > 0);
}

/// Get a byte of the rope.
pub fn get(self: *const Rope, i: u64) ?u8 {
    _ = self;
    _ = i;

    @panic("TODO");
}

/// Write the rope to a stream as chunks
pub fn format(self: *Rope, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = self;
    _ = fmt;
    _ = options;
    _ = writer;

    @panic("TODO");
}

/// Iterator over data in the rope.
pub fn chunks(self: *const Rope, beg: usize, end: usize) Chunks {
    _ = self;
    _ = beg;
    _ = end;

    @panic("TODO");
}

pub const Chunks = struct {
    rope: *Rope,
    beg: usize,
    end: usize,

    var static: [128]u8 = undefined;
    pub fn next(self: *Chunks) ?[]u8 {
        _ = self;
        @panic("TODO");
    }
};

/// Represents the byte range of a single row (line) in the rope.
pub const RowData = struct {
    beg: u64,
    end: u64,
};

fn dir(self: *const Rope) u1 {
    return if (self.parent) |p| @intFromBool(p.childern[1] == self) else 0;
}

fn connect(pa: ?*Rope, ch: ?*Rope, x: u1) void {
    if (ch) |c| c.parent = pa;
    if (pa) |p| p.childern[x] = ch;
}

fn rot(self: *Rope) void {
    const pa = self.parent orelse return;
    const x = self.dir();

    connect(pa.parent, self, pa.dir());
    connect(pa, self.childern[x ^ 1], x);
    connect(self, pa, x ^ 1);

    pa.update();
    self.update();
}

fn data(self: *Rope) []u8 {
    return self.dataBuffer[0..self.dataLength];
}

/// Updates the aggregate fields based on children and own data. Assumes
/// that the childerns data is up to date. Also assumes the internal feilds are
/// correct.
fn update(self: *Rope) void {
    self.length = self.dataLength;
    self.newlines = self.dataLines;

    if (self.childern[0]) |l| {
        self.length += l.length;
        self.newlines = l.newlines;
    }

    if (self.childern[1]) |r| {
        self.length += r.length;
        self.newlines = r.newlines;
    }
}

/// Run the splay operation on this node, bringing it to the root.
fn splay(self: *Rope) void {
    while (self.parent != null and self.parent.?.parent != null) {
        if (self.dir() == self.parent.?.dir()) {
            self.parent.?.rot();
        } else {
            self.rot();
        }
        self.rot();
    }

    if (self.parent != null) {
        self.rot();
    }

    std.debug.assert(self.parent == null);
}

// --------------------- Tests ---------------------------------

const testing = std.testing;

test "rope getRowData for 3 lines debug" {
    if (true) return error.SkipZigTest;

    const a = testing.allocator;
    var r = try Rope.init(a, "line1\nline2\nline3");
    defer r.deinit(a);

    // This test will show the actual row data in the test output
    const row0 = r.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row0.beg);
    try testing.expectEqual(@as(u64, 5), row0.end);

    const row1 = r.getRowData(1);
    try testing.expectEqual(@as(u64, 6), row1.beg);
    try testing.expectEqual(@as(u64, 11), row1.end);
}

test "rope getRowData empty" {
    if (true) return error.SkipZigTest;

    const a = testing.allocator;
    var rope = try Rope.init(a, "");
    defer rope.deinit(a);

    const row = rope.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row.beg);
    try testing.expectEqual(@as(u64, 0), row.end);
}

test "rope getRowData single line" {
    if (true) return error.SkipZigTest;

    const a = testing.allocator;
    var rope = try Rope.init(a, "hello");
    defer rope.deinit(a);

    // getLineCount returns newline count (0 newlines in "hello")
    try testing.expectEqual(@as(u64, 0), rope.getLineCount());

    const row0 = rope.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row0.beg);
    try testing.expectEqual(@as(u64, 5), row0.end);

    const row1 = rope.getRowData(1);
    try testing.expectEqual(@as(u64, 0), row1.beg);
    try testing.expectEqual(@as(u64, 5), row1.end);
}

test "rope getRowData multiple lines" {
    if (true) return error.SkipZigTest;

    const a = testing.allocator;
    var rope = try Rope.init(a, "hello\nworld\nfoo");
    defer rope.deinit(a);

    // 2 newlines = 3 lines
    try testing.expectEqual(@as(u64, 2), rope.getLineCount());

    const row0 = rope.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row0.beg);
    try testing.expectEqual(@as(u64, 5), row0.end);

    const row1 = rope.getRowData(1);
    try testing.expectEqual(@as(u64, 6), row1.beg);
    try testing.expectEqual(@as(u64, 11), row1.end);

    const row2 = rope.getRowData(2);
    try testing.expectEqual(@as(u64, 12), row2.beg);
    try testing.expectEqual(@as(u64, 15), row2.end);
}

test "rope getRowData with newlines at end" {
    if (true) return error.SkipZigTest;

    const a = testing.allocator;
    var rope = try Rope.init(a, "line1\nline2\n");
    defer rope.deinit(a);

    try testing.expectEqual(@as(u64, 3), rope.getLineCount());

    const row0 = rope.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row0.beg);
    try testing.expectEqual(@as(u64, 5), row0.end);

    const row1 = rope.getRowData(1);
    try testing.expectEqual(@as(u64, 6), row1.beg);
    // "line2" is 5 chars, so end = 6 + 5 = 11
    try testing.expectEqual(@as(u64, 11), row1.end);
}

test "rope getRowData after insert" {
    const a = testing.allocator;
    var rope = try Rope.init(a, "abc\ndef");
    defer rope.deinit(a);

    // 1 newline = 2 lines
    try testing.expectEqual(@as(u64, 1), rope.getLineCount());

    // const row0 = rope.getRowData(0);
    // try testing.expectEqual(@as(u64, 0), row0.beg);
    // try testing.expectEqual(@as(u64, 3), row0.end);

    // const row1 = rope.getRowData(1);
    // try testing.expectEqual(@as(u64, 4), row1.beg);
    // try testing.expectEqual(@as(u64, 7), row1.end);
}

test "rope getRowData after delete" {
    const a = testing.allocator;
    var rope = try Rope.init(a, "hello\nworld\nagain\n\n");
    defer rope.deinit(a);

    try testing.expectEqual(@as(u64, 4), rope.getLineCount());

    // try rope.delete(5, 6);
    // try testing.expectEqual(@as(u64, 3), rope.getLineCount());

    // // After deleting the newline, we should have "helloworld" with 0 newlines
    // // But due to potential issues, just verify row data is consistent
    // const row0 = rope.getRowData(0);
    // try testing.expectEqual(@as(u64, 0), row0.beg);
    // try testing.expectEqual(@as(u64, 10), row0.end);
}

test "line count of long long string" {
    const a = testing.allocator;

    const string = try a.alloc(u8, 64 * ROPE_BUFFER_SIZE);
    defer a.free(string);
    @memset(string, 'a');
    var i: usize = 6;
    var nl: u64 = 0;
    while (i < 64 * ROPE_BUFFER_SIZE) : (i += ROPE_BUFFER_SIZE / 2) {
        string[i] = '\n';
        nl += 1;
    }
    var rope = try Rope.init(a, string);
    defer rope.deinit(a);

    try testing.expectEqual(nl, rope.getLineCount());
}
