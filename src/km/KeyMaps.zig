const root = @import("../root.zig");
const std = root.std;
const lua = root.lua;
const trm = root.trm;
const State = root.State;

const km = @import("root.zig");
const ModeId = km.ModeId;
const KeyFunction = km.KeyFunction;

const KeyMaps = @This();

keys: KeyToFunction = .{},

fallback: ?KeyFunction,
targeter: ?KeyFunction,

/// used as a name to self identify
modeid: ModeId = ModeId.Null,

/// Causes the keymap to not be set to null at the end of the run
pending: bool = false,

// Note: you can statically init this but just be sure to use the same
// allocator for everything
// pub fn init(name: ?[]const u8) KeyMaps {
//     return .{
//         .name = name,
//     };
// }

pub fn deinit(self: *KeyMaps, L: ?*lua.State, a: std.mem.Allocator) void {
    var iter = self.keys.iterator();
    while (iter.next()) |key| key.value_ptr.deinit(L, a);

    self.keys.deinit(a);
}

pub fn run(self: KeyMaps, state: *State, ke: trm.KeyEvent) !void {
    if (self.keys.get(trm.keys.bits(ke))) |*function| {
        // if there is a custom handler then run it
        try function.run(state);
    } else if (self.fallback) |fallback| {
        // if there is no handler and its just a regular key then send it to
        // the buffer
        try fallback.run(state);
    } else {
        // cause states that forget to set and exit condition to exit on unknown input
        const buffer = state.getCurrentBuffer();
        buffer.curkeymap = null;
        return;
    }

    if (self.targeter) |targeter| try targeter.run(state);
}

pub inline fn put(self: *KeyMaps, a: std.mem.Allocator, character: u16, value: KeyFunction) !void {
    try self.keys.put(a, character, value);
}

/// Gets the next submap
/// TODO: this function is so bad and will be my downfall
pub fn then(
    self: *KeyMaps,
    a: std.mem.Allocator,
    // from: ModeId,
    maps: *km.ModeToKeys,
    character: u16,
) !*KeyMaps {
    // 1. create a new id
    const newid = self.modeid.chain(character);

    // std.log.debug("new id: {any}", .{newid});

    // 2. create a new map in the mode maps
    const res = try maps.getOrPut(a, newid);
    if (res.found_existing) return res.value_ptr.*;
    res.value_ptr.* = try a.create(KeyMaps);
    res.value_ptr.*.* = KeyMaps{
        .modeid = newid,
        // TODO: find a way to move this to the callers responsibility
        .targeter = null,
        .fallback = null,
    };

    // 3. add a key function to switch to that map
    const kf = KeyFunction{ .function = .{ .setmod = newid } };
    try self.put(a, character, kf);

    // 4. return the map
    return res.value_ptr.*;
}

pub const KeyToFunction = std.AutoArrayHashMapUnmanaged(u16, KeyFunction);
