const std = @import("std");

pub const CodeBlock = struct {
    code: []const u8,
};

pub const Session = struct {
    id: SessionId,
    blocks: std.ArrayList(CodeBlock),

    pub fn init(allocator: *std.mem.Allocator, id: u32) !Session {
        return Session{
            .id = id,
            .blocks = try std.ArrayList(CodeBlock).init(allocator),
        };
    }

    pub fn loadCodeBlock(self: *Session, code: []const u8) !void {
        try self.blocks.append(CodeBlock{ .code = code });
        // Here you would execute the code block and store results if needed.
    }
};

const VTable = struct {
    createSession: *const fn (?*anyopaque) anyerror!SessionId,
    loadCodeBlock: *const fn (?*anyopaque, SessionId, []const u8) anyerror!void,
    deinit: *const fn (?*anyopaque) void,
};

const Kernel = @This();

const SessionId = usize;

// allocator: *std.mem.Allocator,
// sessions: std.AutoHashMap(u32, Session),
// next_id: u32,

vtable: *const VTable,
data: ?*anyopaque,


pub fn init(allocator: *std.mem.Allocator) !Kernel {
    return Kernel{
        .allocator = allocator,
        .sessions = try std.AutoHashMap(u32, Session).init(allocator),
        .next_id = 1,
    };
}

pub fn createSession(self: *Kernel) !SessionId {
    const id = self.next_id;
    self.next_id += 1;
    const session = try Session.init(self.allocator, id);
    try self.sessions.put(id, session);
    return id;
}

pub fn loadCodeBlock(self: *Kernel, session_id: u32, code: []const u8) !void {
    var session = self.sessions.getPtr(session_id) orelse return error.SessionNotFound;
    try session.loadCodeBlock(code);
}
