const std = @import("std");
const mem = std.mem;

/// Common utilitis shared among many modules
//
//
/// Used as row/col in many places
pub const Vec2 = struct {
    row: usize = 0,
    col: usize = 0,
};

pub const Vec4 = struct {
    x: usize = 0,
    y: usize = 0,
    w: usize = 0,
    h: usize = 0,
};

pub const shm = struct {
    const RANDOMNESS: usize = 10;

    const ShmError = std.posix.OpenError  // thign
        || std.posix.UnlinkError 
        || std.posix.TruncateError;

    /// Allocates a shared memory file of the given size.
    pub fn file(size: usize) ShmError!std.posix.fd_t {
        var retries: usize = 10;

        while (retries > 0) : (retries -= 1) {
            const template = "/dev/shm/wev-";
            var buf: [63:0]u8 = undefined;

            std.debug.assert(buf.len >= template.len + RANDOMNESS);

            @memcpy(buf[0..template.len], template);
            for (buf[template.len .. template.len + RANDOMNESS]) |*c| {
                c.* = std.crypto.random.intRangeAtMost(u8, 'A', 'z');
            }
            buf[template.len + RANDOMNESS] = 0; // null-terminate
            const name = buf[0 .. template.len + RANDOMNESS :0];

            // std.debug.print("Using file: {s}\n", .{name});

            // pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);
            const flags = std.posix.O{
                .ACCMODE = .RDWR,
                .CREAT = true,
                .EXCL = true,
                .TRUNC = true,

                .NOFOLLOW = true,
                .CLOEXEC = true,
                .NONBLOCK = true,
            };
            const fd = std.posix.openZ(name, flags, 0o600) catch |err| switch (err) {
                error.PathAlreadyExists => continue,
                else => return err,
            };
            errdefer std.posix.close(fd);
            // pthread_setcancelstate(cs, 0);

            try std.posix.unlinkZ(name);

            try std.posix.ftruncate(fd, size);
            return fd;
        }

        return std.posix.OpenError.PathAlreadyExists;
    }

};
