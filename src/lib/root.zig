const std = @import("std");
const mem = std.mem;

pub const desktop = @import("desktop.zig");

/// Common utilitis shared among many modules
//
//
/// Used as row/col in many places
pub const Vec2 = struct {
    row: usize = 0,
    col: usize = 0,

    pub fn cmp(a: Vec2, b: Vec2) std.math.Order {
        if (a.row < b.row) return .lt;
        if (a.row > b.row) return .gt;
        if (a.col < b.col) return .lt;
        if (a.col > b.col) return .gt;
        return .eq;
    }
};

pub const Vec4 = struct {
    x: usize = 0,
    y: usize = 0,
    w: usize = 0,
    h: usize = 0,
};

pub const shm = struct {
    const RANDOMNESS: usize = 10;

    const ShmError = std.posix.OpenError || std.posix.UnlinkError || std.posix.TruncateError;

    /// Allocates a shared memory file of the given size.
    pub fn file(size: usize) ShmError!std.posix.fd_t {
        var retries: usize = 10;

        while (retries > 0) : (retries -= 1) {
            const template = "/dev/shm/wev-";
            var buf: [63:0]u8 = undefined;

            std.debug.assert(RANDOMNESS > 5);
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

pub const types = struct {
    pub fn typeid(comptime T: type) usize {
        _ = T;
        const H = struct {
            var byte: u8 = 0;
        };
        return @intFromPtr(&H.byte);
    }

    /// This is a really heavy structure and I dont know how to make it better
    /// so i think it would be better to just limit the use instead of trying
    /// to make it better
    pub const TypeErasedData = packed struct {
        id: usize,
        size: usize,
        alignof: std.mem.Alignment,

        pub fn get(self: *TypeErasedData, comptime T: type) ?*T {
            if (self.id != typeid(T)) return null;

            const value: *TypeErased(T) = @fieldParentPtr("data", self);
            return &value.value;
        }

        pub fn deinit(self: *TypeErasedData, a: std.mem.Allocator) void {
            // TODO: this makes the free dependent on the layout
            var data: [*]u8 = @ptrCast(@alignCast(self));
            a.rawFree(data[0..self.size], self.alignof, @returnAddress());

            @memset(data[0..self.size], undefined);
        }
    };

    pub fn TypeErased(comptime T: type) type {
        return struct {
            data: TypeErasedData,
            value: T,

            pub fn init(a: std.mem.Allocator, value: T) !*TypeErasedData {
                const size = @sizeOf(@This());
                const self = try a.create(@This());
                const allign = @alignOf(@This());

                self.* = .{
                    .data = .{
                        .id = 0,
                        .size = size,
                        .alignof = std.mem.Alignment.fromByteUnits(allign),
                    },
                    .value = value,
                };
                return &self.data;
            }
        };
    }
};
