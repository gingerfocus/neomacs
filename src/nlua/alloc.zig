const std = @import("std");

pub fn alloc(a: *std.mem.Allocator, ptr: ?*anyopaque, osize: usize, nsize: usize) callconv(.C) ?*anyopaque {
    std.log.info("alloc (ptr={*}, old={d}, new={d})", .{ ptr, osize, nsize });

    if (nsize == 0) {
        if (ptr == null) return null;
        if (osize == 0) return null;

        const slice = @as([*]u8, @ptrCast(ptr))[0..osize];
        a.free(slice);
        return null;
    }

    if (osize == 0) {
        // sanity check
        std.debug.assert(ptr == null);

        const oslice = a.alloc(u8, nsize) catch return null;
        std.log.info("alloc (out={*})", .{oslice.ptr});
        return oslice.ptr;
    }

    const slice = @as([*]u8, @ptrCast(ptr))[0..osize];
    const oslice = a.realloc(slice, nsize) catch return null;
    return @ptrCast(oslice.ptr);
}
