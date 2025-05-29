const std = @import("std");
const ts = @import("root").ts;

var alloc: std.heap.GeneralPurposeAllocator(.{}) = .{};
const galloc = alloc.allocator();

pub fn init() void {
    ts.ts_set_allocator(malloc, calloc, realloc, free);
}
pub fn deinit() void {
    _ = alloc.deinit();
}

pub fn allocator() std.mem.Allocator {
    return galloc;
}

// ----------------------------------------------------------------------------

fn malloc(size: usize) callconv(.C) ?*anyopaque {
    // if (size == 0) return @as(*anyopaque, @ptrFromInt(math.maxInt(usize)));

    const ptr = galloc.rawAlloc(size, 1, @returnAddress()) orelse return null;
    return @as(*anyopaque, @ptrCast(ptr));
}

fn calloc(size: usize, count: usize) callconv(.C) ?*anyopaque {
    _ = count; // autofix
    _ = size; // autofix
    return null;
}

fn realloc(ptr: ?*anyopaque, size: usize) callconv(.C) ?*anyopaque {
    _ = ptr; // autofix
    _ = size; // autofix
    return null;
}

fn free(ptr: ?*anyopaque) callconv(.C) void {
    _ = ptr; // autofix
}

/// Can allocate memory and runs garbage collection when oom is hit
const Alloc = struct {
    // fn alloc()
};
