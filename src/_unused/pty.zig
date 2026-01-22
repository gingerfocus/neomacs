const std = @import("std");

const PtyManager = struct {
    master_fd: i32,
    slave_fd: i32,
    slave_name: [256]u8,

    pub fn init(allocator: *std.mem.Allocator) !*PtyManager {
        var self = try allocator.create(PtyManager);
        errdefer allocator.destroy(self);

        self.* = PtyManager{
            .master_fd = -1,
            .slave_fd = -1,
            .slave_name = [_]u8{0} ** 256,
        };

        // Open PTY master
        self.master_fd = try std.posix.open("/dev/ptmx", std.posix.O_RDWR, 0);
        errdefer std.posix.close(self.master_fd);

        // Grant access to the slave
        if (std.c.grantpt(self.master_fd) != 0) {
            return error.GrantPtFailed;
        }

        // Unlock the slave
        if (std.c.unlockpt(self.master_fd) != 0) {
            return error.UnlockPtFailed;
        }

        // Get the name of the slave
        const name_ptr = std.c.ptsname(self.master_fd) orelse {
            return error.PtsNameFailed;
        };

        const name_len = std.mem.len(name_ptr);
        @memcpy(self.slave_name[0..name_len], name_ptr[0..name_len]);
        self.slave_name[name_len] = 0;

        // Open the slave
        self.slave_fd = try std.posix.openZ(self.slave_name[0..name_len :0].ptr, .{ .ACCMODE = .RDWR }, 0);

        return self;
    }

    pub fn deinit(self: *PtyManager, allocator: *std.mem.Allocator) void {
        if (self.master_fd != -1) {
            std.posix.close(self.master_fd);
        }
        if (self.slave_fd != -1) {
            std.posix.close(self.slave_fd);
        }
        allocator.destroy(self);
    }

    pub fn getMasterFd(self: *PtyManager) i32 {
        return self.master_fd;
    }

    pub fn getSlaveFd(self: *PtyManager) i32 {
        return self.slave_fd;
    }

    pub fn setSlaveWindowSize(self: *PtyManager, rows: u16, cols: u16) !void {
        const winsize = std.posix.winsize{
            .row = rows,
            .col = cols,
            .xpixel = 0,
            .ypixel = 0,
        };

        const res = std.os.linux.ioctl(self.slave_fd, std.os.linux.T.IOCSWINSZ, @ptrCast(&winsize));
        if (res != 0) return error.SetWindowSizeFailed;
    }

    pub fn fork(self: *PtyManager, argv: []const []const u8) !i32 {
        // Fork the process
        const pid = std.posix.fork() catch |err| {
            return err;
        };
        if (pid == 0) {
            // Child process
            // Create a new session and set the slave pty as controlling terminal
            _ = std.os.linux.setsid();

            // Set slave_fd as stdin, stdout, stderr
            try std.posix.dup2(self.slave_fd, 0);
            try std.posix.dup2(self.slave_fd, 1);
            try std.posix.dup2(self.slave_fd, 2);

            // Set controlling terminal
            _ = std.os.linux.ioctl(self.slave_fd, std.posix.T.IOCSCTTY, 0);

            // Close master_fd in child
            std.posix.close(self.master_fd);

            // Prepare argv for execvp
            var args_buf: [16]?[*:0]const u8 = undefined;
            var i: usize = 0;
            while (i < argv.len and i < args_buf.len - 1) : (i += 1) {
                args_buf[i] = argv[i].ptr;
            }
            args_buf[i] = null;

            // Execute the command
            return std.process.execv(&args_buf);
        }
        // Parent process returns child's pid
        return pid;
    }

    pub fn getSlaveName(self: *PtyManager) []const u8 {
        return std.mem.sliceTo(&self.slave_name, 0);
    }
};
