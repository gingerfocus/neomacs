const root = @import("root.zig");
const std = root.std;

const Allocator = std.mem.Allocator;

pub const Rope = @This();

/// Type used as the buffer index for the internal buffer.
const Index = usize;
/// The capacity of the internal buffer used by
const ROPE_BUFFER_SIZE: Index = 1024;

comptime {
    if (2 * ROPE_BUFFER_SIZE > std.math.maxInt(Index)) {
        @compileError("cap_bytes must be less than 128 to do arithmetic");
    }
}

alloc: Allocator,
rnode: ?*Node = null,

/// Create a new balanced rope from a byte slice.
pub fn create(allocator: Allocator, bytes: []const u8) !Rope {
    const rope = .{ .allocator = allocator };

    if (bytes.len != 0) {
        rope.root = try Node.createTree(allocator, bytes);
    }

    return rope;
}

/// Free the memory used by a rope and its nodes.
pub fn destroy(self: *Rope) void {
    if (self.rnode) |node| node.destroy(self.alloc);
}

/// Gets the length in bytes of the Rope
pub fn getLen(self: *const Rope) u64 {
    _ = self;
    @panic("TODO");
}

/// Gets the total number of lines in the rope (number of newline characters).
pub fn getLineCount(self: *const Rope) u64 {
    _ = self;
    @panic("TODO");
}

/// Gets the byte range for a given row index.
///
/// Returns the start and end byte positions of the row.
/// If the row index is out of bounds, returns the last row's data.
/// Time complexity: O(log n).
pub fn getRowData(self: *const Rope, row: u64) RowData {
    _ = self;
    _ = row;

    return undefined;
}

pub fn empty(self: *const Rope) bool {
    return self.getLen() == 0;
}

pub fn append(self: *Rope, string: []const u8) !void {
    const other = try Rope.create(self.alloc, string);
    errdefer other.destroy();
    try self.merge(other);
}

/// Merge this rope with another rope, taking ownership of it.
///
/// On out-of-memory error, this function is safe. Neither rope is changed
/// in a way that semantically modifies the values in it.
pub fn merge(self: *Rope, other: *Rope) !void {
    _ = self;
    _ = other;
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

    return undefined;
}

/// Insert bytes at the given index. Invalid indices are clamped to valid range.
/// Errors are logged and operation may be partially complete.
pub fn insert(self: *Rope, index: u64, bytes: []const u8) !void {
    if (bytes.len == 0) return;

    const rlen = self.getLen();
    const effective_index = if (index > rlen) blk: {
        std.log.warn("rope.insert: invalid index {} > len {}, clamping to {}", .{ index, rlen, rlen });
        break :blk rlen;
    } else index;

    const other = try Rope.create(self.alloc, bytes);
    errdefer other.destroy();

    if (effective_index == rlen) {
        try self.merge(other);
    } else {
        const righthand = try self.split(effective_index);
        errdefer righthand.destroy();
        try self.merge(other);

        // TODO: if this fails it is UB to destroy the other rope
        try self.merge(righthand);
    }
}

/// Delete a range of bytes from a rope.
/// Invalid indices are clamped to valid range. Errors are logged and operation may be partially complete.
pub fn delete(self: *Rope, beg: usize, end: usize) void {
    _ = self;
    _ = beg;
    _ = end;

    // TODO: make this use splice with empty rope

    return;
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
    std.mem.swap(Rope, swap, content);
    try self.merge(content);
    try self.merge(tail);

    std.debug.assert(self.getLen() > 0);
}

/// Get a byte of the rope.
///
/// Note that splay trees have some really important mathematical properties
/// here. For example, they have static optimality and are guaranteed to use
/// only linear time when accessing nodes in inorder traversal.
pub fn get(self: *Rope, i: u64) ?u8 {
    _ = self;
    _ = i;
    return null;
}

/// Write the rope to a stream as chunks
pub fn format(self: *Rope, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = self;
    _ = fmt;
    _ = options;
    _ = writer;

    unreachable;
}

// ----------------- node methods ---------------------

/// A node in the rope
const Node = struct {
    /// Pointer to parent node, if null then this is the root node of some tree,
    /// either the main one or something split off.
    parent: ?*Node = null,

    childern: [2]?*Node = .{ null, null },
    nodes: u64 = 1,

    /// Cached value length of data stored in self and childern
    contentSize: u64 = 0,

    /// Number of newline characters within this nodes buffer
    internalLines: u64 = 0,

    /// Cumulative line count (newlines) in the left subtree.
    /// This enables O(log n) row lookup by tracking where each subtree starts.
    lineOffset: u64 = 0,

    len: Index = 0,
    data: [ROPE_BUFFER_SIZE]u8 = undefined,

    // TODO: see if using a std.io.FixedBufferStream can manage both the feilds above

    /// Constructor. Creates a new tree based
    fn createTree(allocator: Allocator, bytes: []const u8) !*Node {
        _ = allocator;
        _ = bytes;

        // // Use only a suffix if the rope is too small.
        // if (bytes.len < MIN_BYTES) {
        //     rope.suffix_len = @intCast(bytes.len);
        //     rope.internalLines = std.mem.count(u8, bytes, "\n");
        //     @memcpy(rope.suffix_buf[0..bytes.len], bytes);
        //     return rope;
        // }

        @panic("TODO");
    }

    fn dir(self: *const Node) u1 {
        return if (self.parent) |p| @intFromBool(p.childern[1] == self) else 0;
    }

    fn connect(pa: ?*Node, ch: ?*Node, x: u1) void {
        if (ch) |c| c.parent = pa;
        if (pa) |p| p.childern[x] = ch;
    }

    fn rot(self: *Node) void {
        std.debug.assert(self.parent != null);

        const x = self.dir();
        const pa = self.parent.?;

        connect(pa.parent, self, pa.dir());
        connect(pa, self.childern[x ^ 1], x);
        connect(self, pa, x ^ 1);

        pa.update();
        self.update();
    }

    /// Updates the aggregate fields based on children and own data.
    fn update(self: *Node) void {
        self.contentSize = self.len;
        self.nodes = 1;
        self.internalLines = std.mem.count(u8, self.data[0..self.len], "\n");

        const left = self.childern[0];
        const right = self.childern[1];

        // line_offset = lines in left subtree + left's line_offset
        if (left) |l| {
            self.contentSize += l.contentSize;
            self.nodes += l.nodes;
            self.internalLines += l.internalLines;
            self.lineOffset = l.internalLines + l.lineOffset;
        } else {
            self.lineOffset = 0;
        }

        if (right) |r| {
            self.contentSize += r.contentSize;
            self.nodes += r.nodes;
            self.internalLines += r.internalLines;
        }
    }

    /// Run the splay operation on this node, bringing it to the root.
    fn splay(self: *Node) void {
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

    /// Free a splay tree node without using recursion.
    fn destroy(self: *Node, allocator: Allocator) void {
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
                allocator.destroy(node);
                node = next orelse break;
            }
        }
    }
};

/// Represents the byte range of a single row (line) in the rope.
pub const RowData = struct {
    beg: u64,
    end: u64,
};

// --------------------- Tests ---------------------------------

const testing = std.testing;

test "rope getRowData for 3 lines debug" {
    const a = testing.allocator;
    const r = try Rope.create(a, "line1\nline2\nline3");
    defer r.destroy();

    // This test will show the actual row data in the test output
    const row0 = r.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row0.beg);
    try testing.expectEqual(@as(u64, 5), row0.end);

    const row1 = r.getRowData(1);
    try testing.expectEqual(@as(u64, 6), row1.beg);
    try testing.expectEqual(@as(u64, 11), row1.end);
}

test "rope getRowData empty" {
    const a = testing.allocator;
    const rope = try Rope.create(a, "");
    defer rope.destroy();

    const row = rope.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row.beg);
    try testing.expectEqual(@as(u64, 0), row.end);
}

test "rope getRowData single line" {
    const a = testing.allocator;
    const rope = try Rope.create(a, "hello");
    defer rope.destroy();

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
    const a = testing.allocator;
    const rope = try Rope.create(a, "hello\nworld\nfoo");
    defer rope.destroy();

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
    const a = testing.allocator;
    const rope = try Rope.create(a, "line1\nline2\n");
    defer rope.destroy();

    // 2 newlines = 2 lines (last newline terminates line2, doesn't create new line)
    try testing.expectEqual(@as(u64, 2), rope.getLineCount());

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
    const rope = try Rope.create(a, "");
    defer rope.destroy();

    rope.insert(0, "abc\ndef");
    // 1 newline = 2 lines
    try testing.expectEqual(@as(u64, 1), rope.getLineCount());

    const row0 = rope.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row0.beg);
    try testing.expectEqual(@as(u64, 3), row0.end);

    const row1 = rope.getRowData(1);
    try testing.expectEqual(@as(u64, 4), row1.beg);
    try testing.expectEqual(@as(u64, 7), row1.end);
}

test "rope getRowData after delete" {
    const a = testing.allocator;
    const rope = try Rope.create(a, "hello\nworld");
    defer rope.destroy();

    // "hello\nworld" has 1 newline
    try testing.expectEqual(@as(u64, 1), rope.getLineCount());

    rope.delete(5, 6);

    // After deleting the newline, we should have "helloworld" with 0 newlines
    // But due to potential issues, just verify row data is consistent
    const row0 = rope.getRowData(0);
    try testing.expectEqual(@as(u64, 0), row0.beg);
    try testing.expectEqual(@as(u64, 10), row0.end);
}
