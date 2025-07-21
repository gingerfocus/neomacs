const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;

pub const KeyFunction = @import("KeyFunction.zig");
pub const Keymap = @import("Keymap.zig");
pub const KeySequence = @import("KeySequence.zig");

pub const ModeId = struct {
    _: u16,

    pub const Null = ModeId{ ._ = 0 };
    pub const Normal = ModeId{ ._ = 'n' };
    pub const Insert = ModeId{ ._ = 'i' };
    pub const Visual = ModeId{ ._ = 'v' };
    pub const Command = ModeId{ ._ = 'c' };

    pub fn toString(self: ModeId) []const u8 {
        return switch (self._) {
            'n' => "NORMAL",
            'i' => "INSERT",
            'v' => "VISUAL",
            'c' => "COMMAND",
            else => "UNKNOWN",
        };
    }

    pub fn eql(self: ModeId, other: ModeId) bool {
        return self._ == other._;
    }

    pub fn from(str: []const u8) ModeId {
        var mode: ModeId = std.mem.zeroes(ModeId);
        const mem = str[0..@min(str.len, 2)];
        @memcpy(std.mem.asBytes(&mode._)[0..mem.len], mem);
        return mode;
    }

    test "ModeId.from" {
        std.testing.expectEqual(ModeId.Null, ModeId.from(""));
        std.testing.expectEqual(ModeId.Normal, ModeId.from("n"));
        std.testing.expectEqual(ModeId.Insert, ModeId.from("i"));
        std.testing.expectEqual(ModeId.Visual, ModeId.from("v"));
        std.testing.expectEqual(ModeId.Command, ModeId.from("c"));
    }

    // // MUST always be one greater than the last one above
    // var static: u16 = 4;
    //
    // pub fn next() ModeId {
    //     const mode = ModeId{ ._ = static };
    //     static += 1;
    //     return mode;
    // }
};

/// TODO: add the character to this structure
pub const KeyFunctionDataValue = struct {
    character: trm.KeyEvent,
    dataptr: ?*KeyFunction.KeyDataPtr,

    pub fn getdata(self: KeyFunctionDataValue, comptime T: type) ?*T {
        if (self.dataptr) |ptr| return ptr.get(T);
        return null;
    }
};
