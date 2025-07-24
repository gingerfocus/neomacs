const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;
const km = @import("root.zig"); // root.km

pub const KeySequence = @This();

// TODO: make some better allignment for this and find a good size for the keys
// also could but mode as first item in list

mode: km.ModeId,
keys: [8]u16 = .{0} ** 8,
len: u8 = 0,

pub fn isPrefix(self: KeySequence, other: KeySequence) bool {
    if (self.len >= other.len) return false;
    return std.mem.eql(u16, &self.keys[0..self.len], &other.keys[0..self.len]);
}

pub fn append(self: *KeySequence, key: u16) !void {
    if (self.len >= self.keys.len) return error.SequenceTooLong;
    self.keys[self.len] = key;
    self.len += 1;
}

pub fn init(mode: km.ModeId, keys: []const u8) KeySequence {
    // TODO: make this parse the escapse sequences like <C-a> and <leader>

    var seq: KeySequence = undefined;
    seq.mode = mode;
    for (keys, 0..) |ch, i| {
        seq.keys[i] = trm.keys.norm(ch);
    }
    seq.len = @intCast(keys.len);
    std.debug.assert(seq.len != 0);
    return seq;
}

const CompareResult = enum { better, equal, worse };

/// Compares both a and b to src and return true if b matches better than a
pub fn better(src: KeySequence, bestlen: u8, b: KeySequence) CompareResult {
    // std.debug.assert(src.len != 0);

    // wrong mode cant match
    // TODO: remove this once the mode is moved to the array, also assert len
    // is not 0
    if (!src.mode.eql(b.mode)) return .worse;

    // too long
    if (b.len > src.len) return .worse;

    // not better, equal length is ok
    if (b.len < bestlen) return .worse;

    if (std.mem.eql(u16, src.keys[0..b.len], b.keys[0..b.len])) {
        return if (b.len == src.len) .equal else .better;
    } else return .worse;
}

pub fn eql(
    a: KeySequence,
    b: KeySequence,
) bool {
    if (!a.mode.eql(b.mode)) return false;
    if (a.len != b.len) return false;

    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (a.keys[i] != b.keys[i]) return false;
    }
    return true;
}

pub const Ctx = struct {
    pub fn hash(_: @This(), key: KeySequence) u32 {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(std.mem.asBytes(&key.mode._));
        hasher.update(std.mem.asBytes(&key.keys[0..key.len]));
        return @truncate(hasher.final());
    }

    pub fn eql(_: @This(), a: KeySequence, b: KeySequence, _: usize) bool {
        return a.eql(b);
    }
};
