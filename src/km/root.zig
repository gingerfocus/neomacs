//! TODO: Fully modular system for keymaps
//! Dont have the nuance of reference counting escape this file

const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;
// const rc = @import("zigrc");

pub const KeyFunction = @import("KeyFunction.zig");
pub const KeyMaps = @import("KeyMaps.zig");

pub const ModeId = root.Buffer.ModeId;
pub const ModeToKeys = std.AutoArrayHashMapUnmanaged(ModeId, *KeyMaps);

/// TODO: add the character to this structure
pub const KeyFunctionDataValue = struct {
    character: trm.KeyEvent,
    dataptr: ?*KeyFunction.KeyDataPtr,

    pub fn getdata(self: KeyFunctionDataValue, comptime T: type) ?*T {
        if (self.dataptr) |ptr| return ptr.get(T);
        return null;
    }
};

pub fn debug(modes: *const ModeToKeys) void {
    var iter = modes.iterator();
    while (iter.next()) |key| {
        debugmodeid(key.key_ptr.*._);
        std.debug.print("\n", .{});

        debuginner(key.value_ptr.*, 1);
    }
}

pub fn debuginner(modes: *const KeyMaps, indent: usize) void {
    var iter = modes.keys.iterator();
    while (iter.next()) |key| {
        std.io.getStdOut().writer().writeByteNTimes(' ', indent * 4) catch unreachable;

        debugmodeid(key.key_ptr.*);

        std.debug.print(" {s}", .{@tagName(key.value_ptr.function)});
        switch (key.value_ptr.function) {
            .LuaFnc => |id| std.debug.print(" ({d})", .{id}),
            // .state => |fc| std.debug.print(" ({*})", .{fc}),
            // .buffer => |fc| std.debug.print(" ({*})", .{fc}),
            .setmod => |mode| std.debug.print(" (-> {d})", .{mode._}),
            else => {},
        }

        std.debug.print("\n", .{});
    }
}

pub fn debugmodeid(modeid: usize) void {
    // if (modeid < 128) {
    //     std.debug.print("{c:3}:", .{@as(u8, @intCast(modeid))});
    // } else {
    std.debug.print("{d:3}:", .{modeid});
    // }
}
