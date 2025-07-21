const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;

pub const KeyFunction = @import("KeyFunction.zig");
pub const Keymap = @import("Keymap.zig");
pub const KeySequence = @import("KeySequence.zig");

pub const ModeId = struct {
    _: u16,

    pub const Normal = ModeId{ ._ = 0 };
    pub const Insert = ModeId{ ._ = 1 };
    pub const Visual = ModeId{ ._ = 2 };
    pub const Command = ModeId{ ._ = 3 };
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
