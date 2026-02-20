//! Adapted from
//! https://github.com/ekzhang/redis-rope/blob/877f406fa5eabc197217f935d8dd14faeb1d188a/src/rope.zig
//!
//! Copyright (c) 2022 Eric Zhang
//! Permission is hereby granted, free of charge, to any person obtaining a copy
//! of this software and associated documentation files (the "Software"), to deal
//! in the Software without restriction, including without limitation the rights
//! to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//! copies of the Software, and to permit persons to whom the Software is
//! furnished to do so, subject to the following conditions:
//!
//! The above copyright notice and this permission notice shall be included in all
//! copies or substantial portions of the Software.
//!
//! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//! IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//! FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//! AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//! LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//! OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//! SOFTWARE.
//!
//!
//! A rope data structure based on splay trees, optimized to use less memory.

const std = @import("std");
const Allocator = std.mem.Allocator;

// TODO: make it so that each node keeps track of weather it is a newline or
// not and make it so that

/// The minimum number of bytes stored in a splay tree node.
const MIN_BYTES = 64;
/// The capacity of a splay tree node in bytes.
const CAP_BYTES = 127;

comptime {
    if (MIN_BYTES < 1 or MIN_BYTES * 2 != CAP_BYTES + 1) {
        @compileError("min_bytes must be half of cap_bytes + 1");
    }
    if (CAP_BYTES >= 128) {
        @compileError("cap_bytes must be less than 128 to do arithmetic");
    }
}

/// A node in the splay tree.
const Node = struct {
    parent: ?*Node = null,
    child: [2]?*Node = .{ null, null },
    nodes: u64 = 1,
    size: u64 = 0,
    lines: u64 = 0,
    len: u8 = 0,
    data: [CAP_BYTES]u8 = undefined,

    fn dir(self: *const Node) u1 {
        return if (self.parent) |p| @intFromBool(p.child[1] == self) else 0;
    }

    fn update(self: *Node) void {
        self.size = self.len;
        self.nodes = 1;
        self.lines = std.mem.count(u8, self.data[0..self.len], "\n");
        for (self.child) |ch| if (ch) |c| {
            self.size += c.size;
            self.nodes += c.nodes;
            self.lines += c.lines;
        };
    }

    fn connect(pa: ?*Node, ch: ?*Node, x: u1) void {
        if (ch) |c| c.parent = pa;
        if (pa) |p| p.child[x] = ch;
    }

    fn rot(self: *Node) void {
        std.debug.assert(self.parent != null);

        const x = self.dir();
        const pa = self.parent.?;

        connect(pa.parent, self, pa.dir());
        connect(pa, self.child[x ^ 1], x);
        connect(self, pa, x ^ 1);

        pa.update();
        self.update();
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
            if (node.child[0]) |c| {
                node.child[0] = null;
                node = c;
            } else if (node.child[1]) |c| {
                node.child[1] = null;
                node = c;
            } else {
                const next = node.parent;
                allocator.destroy(node);
                node = next orelse break;
            }
        }
    }
};

/// Access a splay tree at an index, returning the new root.
fn access(node: *Node, index: u64) *Node {
    std.debug.assert(index < node.size);
    var n = node;
    var i = index;
    while (true) {
        const left_size = if (n.child[0]) |c| c.size else 0;
        if (i < left_size) {
            n = n.child[0].?;
        } else {
            i -= left_size;
            if (i < n.len) {
                n.splay();
                return n;
            } else {
                i -= n.len;
                n = n.child[1].?;
            }
        }
    }
}

/// Allocate a pre-balanced tree of nodes from a data slice.
fn createTree(allocator: Allocator, data: []const u8) Allocator.Error!*Node {
    std.debug.assert(data.len >= MIN_BYTES);
    var node: *Node = undefined;
    if (data.len <= CAP_BYTES) {
        node = try allocator.create(Node);
        node.* = .{ .len = @intCast(data.len) };
        memcpy(node.data[0..data.len], data);
    } else {
        const blocks = data.len / CAP_BYTES;
        if (blocks < 2) {
            // node
            //    \
            //    right
            node = try createTree(allocator, data[0 .. data.len / 2]);
            errdefer node.destroy(allocator);
            std.debug.assert(node.child[1] == null);
            const right = try createTree(allocator, data[data.len / 2 ..]);
            Node.connect(node, right, 1);
        } else if (blocks < 3) {
            //    node
            //    /  \
            // left   ...
            node = try createTree(allocator, data[CAP_BYTES..]);
            errdefer node.destroy(allocator);
            std.debug.assert(node.child[0] == null);
            const left = try createTree(allocator, data[0..CAP_BYTES]);
            Node.connect(node, left, 0);
        } else {
            //    node
            //    /  \
            // left  right
            const start_idx = (blocks / 2) * CAP_BYTES;
            node = try createTree(allocator, data[start_idx .. start_idx + CAP_BYTES]);
            errdefer node.destroy(allocator);
            std.debug.assert(node.child[0] == null);
            std.debug.assert(node.child[1] == null);
            const left = try createTree(allocator, data[0..start_idx]);
            errdefer left.destroy(allocator);
            const right = try createTree(allocator, data[start_idx + CAP_BYTES ..]);
            Node.connect(node, left, 0);
            Node.connect(node, right, 1);
        }
    }
    node.update();
    return node;
}

/// Utility method for concatenating a slice to the front of another.
fn concat_front(dest: []u8, src: []u8) void {
    std.debug.assert(dest.len >= src.len);
    var i = dest.len - src.len;
    while (i > 0) {
        i -= 1;
        dest[i + src.len] = dest[i];
    }
    memcpy(dest[0..], src);
}

/// Mem-copy that doest care about length
fn memcpy(dst: []u8, src: []const u8) void {
    const len = @min(dst.len, src.len);
    std.mem.copyForwards(u8, dst[0..len], src[0..len]);
}

pub const Rope = struct {
    pub const rope_size = @sizeOf(Rope);
    pub const node_size = @sizeOf(Node);

    allocator: Allocator,
    root: ?*Node = null,
    suf_len: u8 = 0,
    suf_buf: [MIN_BYTES - 1]u8 = undefined,
    lines: u64 = 0,

    /// Create a new, pre-balanced rope from a byte slice.
    pub fn create(allocator: Allocator, bytes: []const u8) !*Rope {
        const rope = try allocator.create(Rope);
        errdefer allocator.destroy(rope);
        rope.* = .{ .allocator = allocator };

        // Use only a suffix if the rope is too small.
        if (bytes.len < MIN_BYTES) {
            rope.suf_len = @intCast(bytes.len);
            rope.lines = std.mem.count(u8, bytes, "\n");
            @memcpy(rope.suf_buf[0..bytes.len], bytes);
            return rope;
        }
        rope.root = try createTree(allocator, bytes);
        rope.lines = std.mem.count(u8, bytes, "\n");
        return rope;
    }

    /// Free the memory used by a rope and its nodes.
    pub fn destroy(self: *Rope) void {
        if (self.root) |node| {
            node.destroy(self.allocator);
        }
        self.allocator.destroy(self);
    }

    pub fn len(self: *const Rope) u64 {
        return self.suf_len + if (self.root) |r| r.size else 0;
    }

    pub fn line_count(self: *const Rope) u64 {
        return self.lines + if (self.root) |r| r.lines else 0;
    }

    pub fn empty(self: *const Rope) bool {
        return self.len() == 0;
    }

    pub fn append(self: *Rope, string: []const u8) !void {
        const other = try Rope.create(self.allocator, string);
        self.merge(other) catch |err| {
            other.destroy();
            return err;
        };
    }

    /// Merge this rope with another rope, taking ownership of it.
    ///
    /// On out-of-memory error, this function is safe. Neither rope is changed
    /// in a way that semantically modifies the values in it.
    pub fn merge(self: *Rope, other: *Rope) !void {
        std.debug.assert(self.allocator.vtable == other.allocator.vtable);

        if (other.root == null) {
            const total = self.suf_len + other.suf_len;
            if (total < MIN_BYTES) {
                @memcpy(self.suf_buf[self.suf_len..total], other.suf_buf[0..other.suf_len]);
                self.suf_len = total;
                self.lines += other.lines;
            } else {
                std.debug.assert(total <= CAP_BYTES);
                const node = try self.allocator.create(Node);
                node.* = .{ .len = total, .lines = self.lines + other.lines };
                memcpy(node.data[0..self.suf_len], self.suf_buf[0..self.suf_len]);
                memcpy(node.data[self.suf_len..], other.suf_buf[0..other.suf_len]);

                Node.connect(node, self.root, 0);
                node.update();
                self.root = node;
                self.suf_len = 0;
                self.lines = 0;
            }
        } else {
            _ = other.get(0); // splay
            var root = other.root.?;
            std.debug.assert(root.child[0] == null);
            const total = root.len + self.suf_len;
            if (total < CAP_BYTES) {
                root.len += self.suf_len;
                concat_front(root.data[0..root.len], self.suf_buf[0..self.suf_len]);
                root.lines += self.lines;
            } else {
                std.debug.assert(root.len >= MIN_BYTES);
                const node = try self.allocator.create(Node);
                node.* = .{ .len = MIN_BYTES };

                memcpy(node.data[0..], self.suf_buf[0..self.suf_len]);
                memcpy(node.data[self.suf_len..], root.data[0 .. MIN_BYTES - self.suf_len]);
                memcpy(root.data[0..], root.data[MIN_BYTES - self.suf_len .. root.len]);
                root.len -= MIN_BYTES - self.suf_len;
                root.lines -= std.mem.count(u8, root.data[0 .. MIN_BYTES - self.suf_len], "\n");
                root.update();

                Node.connect(node, root, 1);
                root = node;
            }
            std.debug.assert(root.child[0] == null);
            Node.connect(root, self.root, 0);
            self.root = null;
            root.update();

            other.root = root;
            self.lines = other.lines;
            other.lines = 0;
            std.mem.swap(Rope, self, other);
        }
        other.destroy();
    }

    /// Splits this rope into two at the given index.
    ///
    /// The current rope will be the first part, and the second part starting at
    /// and including the index will be returned as a new rope.
    ///
    /// On out-of-memory error, the rope is not modified.
    pub fn split(self: *Rope, index: u64) !*Rope {
        const length = self.len();
        if (index > length) {
            // If the index is out-of-range, just return an empty rope.
            return try Rope.create(self.allocator, &.{});
        }
        if (index >= length - self.suf_len) {
            const suf_rem: u8 = @intCast(index - (length - self.suf_len));
            const rope = try create(self.allocator, self.suf_buf[suf_rem..self.suf_len]);
            self.suf_len = suf_rem;
            return rope;
        }
        // The index is inside the splay tree. We split the tree now, although
        // it turns out that we never need to allocate new nodes here.
        std.debug.assert(index < self.root.?.size);
        const rope = try self.allocator.create(Rope);
        errdefer rope.destroy();
        rope.* = .{
            .allocator = self.allocator,
            .suf_len = self.suf_len, // copy suffix verbatim
            .suf_buf = self.suf_buf, // copy suffix verbatim
        };

        _ = self.get(index); // splay
        const root = self.root.?;
        const left_len = if (root.child[0]) |c| c.size else 0;
        std.debug.assert(left_len <= index and index < left_len + root.len);
        const pivot: u8 = @intCast(index - left_len);

        // Copy the left half of the node's data and establish the a new root.
        if (index - left_len >= MIN_BYTES) { // doesn't fit in self.suf_buf
            const new_root = try self.allocator.create(Node);
            new_root.* = .{ .len = pivot };
            memcpy(new_root.data[0..], root.data[0..pivot]);
            Node.connect(new_root, root.child[0], 0);
            new_root.update();
            self.root = new_root;
            self.suf_len = 0;
        } else { // fits in self.suf_buf
            memcpy(self.suf_buf[0..], root.data[0..pivot]);
            self.suf_len = pivot;
            self.root = root.child[0];
            if (self.root) |n| n.parent = null;
        }

        // Create the right half of the rope. First, we fix invariants.
        root.child[0] = null;
        memcpy(root.data[0..], root.data[pivot..root.len]);
        root.len -= pivot;
        root.update();

        // We could just set `rope.root = root;` now, but we need to check and
        // fix one more invariant: each node has `len >= min_bytes`.
        if (root.len >= MIN_BYTES) {
            rope.root = root;
        } else if (root.child[1]) |right_child| {
            // Splay the next inorder node to the top and do a left concatenation.
            right_child.parent = null;
            root.child[1] = null;
            const new_root = access(right_child, 0);
            std.debug.assert(new_root.child[0] == null);
            rope.root = new_root;
            if (root.len + new_root.len <= CAP_BYTES) {
                new_root.len += root.len;
                concat_front(new_root.data[0..new_root.len], root.data[0..root.len]);
                new_root.update();
                root.destroy(self.allocator);
            } else {
                const copy_len = MIN_BYTES - root.len;
                memcpy(root.data[root.len..], new_root.data[0..copy_len]);
                memcpy(new_root.data[0..], new_root.data[copy_len..new_root.len]);
                root.len += copy_len;
                new_root.len -= copy_len;
                Node.connect(new_root, root, 0);
                root.update();
                new_root.update();
            }
        } else if (rope.suf_len + root.len >= MIN_BYTES) {
            // Concatenate the suffix onto the node directly.
            std.debug.assert(rope.suf_len + root.len <= CAP_BYTES);
            memcpy(root.data[root.len..], rope.suf_buf[0..rope.suf_len]);
            root.len += rope.suf_len;
            root.update();
            rope.suf_len = 0;
            rope.root = root;
        } else {
            // Delete the root and only use the suffix buffer.
            rope.suf_len += root.len;
            concat_front(rope.suf_buf[0..rope.suf_len], root.data[0..root.len]);
            root.destroy(self.allocator);
        }

        return rope;
    }

    /// Insert bytes at the given index. Invalid indices are clamped to valid range.
    /// Errors are logged and operation may be partially complete.
    pub fn insert(self: *Rope, index: u64, bytes: []const u8) void {
        if (bytes.len == 0) return;

        const rlen = self.len();
        const effective_index = if (index > rlen) blk: {
            std.log.warn("rope.insert: invalid index {} > len {}, clamping to {}", .{ index, rlen, rlen });
            break :blk rlen;
        } else index;

        const other = Rope.create(self.allocator, bytes) catch |err| {
            std.log.err("rope.insert: failed to create rope: {}", .{err});
            return;
        };

        if (effective_index == rlen) {
            self.merge(other) catch |err| {
                std.log.err("rope.insert: merge failed: {}", .{err});
                other.destroy();
            };
        } else {
            const righthand = self.split(effective_index) catch |err| {
                std.log.err("rope.insert: split failed: {}", .{err});
                other.destroy();
                return;
            };
            self.merge(other) catch |err| {
                std.log.err("rope.insert: merge failed: {}", .{err});
                other.destroy();
                righthand.destroy();
                return;
            };
            self.merge(righthand) catch |err| {
                std.log.err("rope.insert: merge righthand failed: {}", .{err});
                righthand.destroy();
            };
        }
    }

    /// Delete a range of bytes from a rope.
    /// Invalid indices are clamped to valid range. Errors are logged and operation may be partially complete.
    pub fn delete_range(self: *Rope, start: usize, end: usize) void {
        const rlen = self.len();
        if (rlen == 0) return;

        const s = if (start > rlen) blk: {
            std.log.warn("rope.delete_range: invalid start {} > len {}, clamping to 0", .{ start, rlen });
            break :blk @as(usize, 0);
        } else start;

        const e = if (end > rlen) blk: {
            std.log.warn("rope.delete_range: invalid end {} > len {}, clamping to {}", .{ end, rlen, rlen });
            break :blk rlen;
        } else end;

        if (s == 0 and e == rlen) {
            self.destroy();
        } else if (s < e) {
            const rope2 = self.split(s) catch |err| {
                std.log.err("rope.delete_range: split failed: {}", .{err});
                return;
            };
            const rope3 = rope2.split(e - s) catch |err| {
                std.log.err("rope.delete_range: split failed: {}", .{err});
                rope2.destroy();
                return;
            };

            self.merge(rope3) catch |err| {
                std.log.err("rope.delete_range: merge failed: {}", .{err});
                rope2.destroy();
                rope3.destroy();
                return;
            };

            rope2.destroy();
        }
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
        std.debug.assert(self.len() > 0);
        std.debug.assert(end <= self.len());
        std.debug.assert(beg <= end);

        const content = try self.split(beg);
        const tail = try content.split(end - beg) catch unreachable;
        std.mem.swap(Rope, swap, content);
        try self.merge(content);
        try self.merge(tail);

        std.debug.assert(self.len() > 0);
    }

    /// Get a byte of the rope.
    ///
    /// Note that splay trees have some really important mathematical properties
    /// here. For example, they have static optimality and are guaranteed to use
    /// only linear time when accessing nodes in inorder traversal.
    pub fn get(self: *Rope, i: u64) ?u8 {
        const slice = self.get_scan(i) orelse return null;
        return slice[0];
    }

    /// Get a byte of the rope, also returning any remaining contiguous bytes.
    pub fn get_scan(self: *Rope, i: u64) ?[]u8 {
        const length = self.len();
        if (i >= length) {
            return null;
        } else if (i >= length - self.suf_len) {
            return self.suf_buf[i - (length - self.suf_len) .. self.suf_len];
        } else {
            var node = self.root.?;
            std.debug.assert(i < node.size);
            node = access(node, i);
            self.root = node;
            return node.data[i - (if (node.child[0]) |c| c.size else 0) .. node.len];
        }
    }

    /// Return an efficient iterator over chunks in a range of bytes.
    pub fn chunks(self: *Rope, start: u64, end: u64) Chunks {
        std.debug.assert(start <= end and end <= self.len());
        return .{ .rope = self, .start = start, .end = end };
    }

    /// Returns the total memory usage of this data structure, in bytes.
    pub fn memusage(self: *const Rope) u64 {
        return rope_size + node_size * self.numnodes();
    }

    /// Returns the total number of splay tree nodes in this data structure.
    pub fn numnodes(self: *const Rope) u64 {
        return if (self.root) |r| r.nodes else 0;
    }

    pub fn format(self: *Rope, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        var chnks = self.chunks(0, self.len());
        while (chnks.next()) |str| {
            try std.fmt.format(writer, "(chunk: {d})", .{str.len});
        }
    }
};

/// Iterator over a rope
pub const Chunks = struct {
    const block_size = 1024; // 65536

    rope: *Rope,
    start: u64,
    end: u64,
    buf: [block_size]u8 = undefined,

    /// Count how many chunks are left in the iterator.
    pub fn remaining(self: *const Chunks) u64 {
        return std.math.divCeil(u64, self.end - self.start, block_size) catch unreachable;
    }

    /// Return the next chunk of this iterator, advancing the index.
    pub fn next(self: *Chunks) ?[]u8 {
        if (self.start >= self.end) {
            return null;
        }
        const len = @min(self.end - self.start, block_size);
        var i: u64 = 0;
        while (i < len) {
            const slice = self.rope.get_scan(self.start + i).?;
            const k = @min(slice.len, len - i);
            @memcpy(self.buf[i .. i + k], slice[0..k]);
            i += k;
        }
        self.start += len;
        return self.buf[0..len];
    }
};
