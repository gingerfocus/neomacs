const std = @import("std");

const PtyManager = struct {
    master_fd: i32,
    slave_fd: i32,
    slave_name: [256]u8,

    pub fn init(allocator: *std.mem.Allocator) !*PtyManager {
        var self = try allocator.create(PtyManager);
        self.master_fd = -1;
        self.slave_fd = -1;
        std.mem.set(u8, &self.slave_name, 0);

        // Open PTY master
        self.master_fd = std.os.open("/dev/ptmx", std.os.O_RDWR, 0) catch |err| {
            allocator.destroy(self);
            return err;
        };

        // Grant access to the slave
        if (std.os.grantpt(self.master_fd) != 0) {
            std.os.close(self.master_fd);
            allocator.destroy(self);
            return error.GrantPtFailed;
        }

        // Unlock the slave
        if (std.os.unlockpt(self.master_fd) != 0) {
            std.os.close(self.master_fd);
            allocator.destroy(self);
            return error.UnlockPtFailed;
        }

        // Get the name of the slave
        const name_ptr = std.os.ptsname(self.master_fd) orelse {
            std.os.close(self.master_fd);
            allocator.destroy(self);
            return error.PtsNameFailed;
        };
        const name_len = std.mem.len(name_ptr);
        std.mem.copy(u8, self.slave_name[0..name_len], name_ptr[0..name_len]);
        self.slave_name[name_len] = 0;

        // Open the slave
        self.slave_fd = std.os.openZ(self.slave_name[0..name_len :0], std.os.O_RDWR, 0) catch |err| {
            std.os.close(self.master_fd);
            allocator.destroy(self);
            return err;
        };

        return self;
    }

    pub fn deinit(self: *PtyManager, allocator: *std.mem.Allocator) void {
        if (self.master_fd != -1) {
            std.os.close(self.master_fd);
        }
        if (self.slave_fd != -1) {
            std.os.close(self.slave_fd);
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
        const winsize = extern struct {
            ws_row: u16,
            ws_col: u16,
            ws_xpixel: u16,
            ws_ypixel: u16,
        }{
            .ws_row = rows,
            .ws_col = cols,
            .ws_xpixel = 0,
            .ws_ypixel = 0,
        };
        const res = std.os.ioctl(self.slave_fd, std.os.T.IOCSWINSZ, @ptrCast(*const anyopaque, &winsize));
        if (res != 0) {
            return error.SetWindowSizeFailed;
        }
    }

    pub fn fork(self: *PtyManager, argv: []const []const u8) !i32 {
        // Fork the process
        const pid = std.os.fork() catch |err| {
            return err;
        };
        if (pid == 0) {
            // Child process
            // Create a new session and set the slave pty as controlling terminal
            _ = std.os.setsid();

            // Set slave_fd as stdin, stdout, stderr
            _ = std.os.dup2(self.slave_fd, 0);
            _ = std.os.dup2(self.slave_fd, 1);
            _ = std.os.dup2(self.slave_fd, 2);

            // Set controlling terminal
            _ = std.os.ioctl(self.slave_fd, std.os.T.IOCSCTTY, 0);

            // Close master_fd in child
            std.os.close(self.master_fd);

            // Prepare argv for execvp
            var args_buf: [16]?[*:0]const u8 = undefined;
            var i: usize = 0;
            while (i < argv.len and i < args_buf.len - 1) : (i += 1) {
                args_buf[i] = argv[i].ptr;
            }
            args_buf[i] = null;

            // Execute the command
            std.os.execvp(args_buf[0].?, &args_buf);

            // If execvp fails, exit child
            std.os.exit(127);
        }
        // Parent process returns child's pid
        return pid;
    }

    pub fn getSlaveName(self: *PtyManager) []const u8 {
        return std.mem.sliceTo(&self.slave_name, 0);
    }
};
