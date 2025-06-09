const std = @import("std");
const mem = std.mem;

pub fn allocateShmFile(size: usize) !std.posix.fd_t {
    const fd = try createSharedMemoryFile();
    errdefer std.posix.close(fd);
    try std.posix.ftruncate(fd, size);
    return fd;
}

fn createSharedMemoryFile() !std.posix.fd_t {
    var retries: usize = 100;
    while (retries > 0) : (retries -= 1) {
        var buf: [64]u8 = undefined;
        const name = makeShmFileName("/wev-XXXXXX", &buf);

        const fd = shmOpen(name, std.posix.O{ .ACCMODE = .RDWR, .CREAT = true, .EXCL = true }, 0o600) catch |err| switch (err) {
            error.PathAlreadyExists => continue,
            else => return err,
        };
        shmUnlink(name);

        // std.log.info("Using file: {s}", .{name});
        return fd;
    }
    return error.EXIST;
}

fn makeShmFileName(comptime template: []const u8, buffer: []u8) [:0]u8 {
    std.debug.assert(template.len + 9 < buffer.len);

    @memcpy(buffer[0..8], "/dev/shm");

    const time = std.time.nanoTimestamp() << 32;
    var r: u64 = @bitCast(@as(i64, @truncate(time)));

    var i: usize = 8;
    inline for (template) |c| {
        const ch = if (c == 'X') 'A' + @as(u8, @truncate(r & 15)) + @as(u8, @truncate(r & 16)) * 2 else c;
        buffer[i] = ch;
        r >>= 5;
        i += 1;
    }
    buffer[i] = 0;
    return buffer[0..i :0];
}

// zig adaptation of musl shm_open
// name should be created with `makeShmFileName`
fn shmOpen(
    name: [:0]const u8,
    flag: std.posix.O,
    perm: std.posix.mode_t,
) std.posix.OpenError!std.posix.fd_t {
    std.debug.assert(mem.eql(u8, name[0..9], "/dev/shm/"));

    // pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);

    var fflag = flag;
    fflag.NOFOLLOW = true;
    fflag.CLOEXEC = true;
    fflag.NONBLOCK = true;
    const fd = try std.posix.openZ(name, fflag, perm);

    // pthread_setcancelstate(cs, 0);
    return fd;
}

// zig adaptation of musl shm_unlink
fn shmUnlink(name: [:0]const u8) void {
    std.posix.unlinkZ(name) catch {};
}
