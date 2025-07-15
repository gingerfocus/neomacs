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

fallback: ?KeyFunction = null,
targeter: ?KeyFunction = KeyFunction.initstate(action.move),

/// used as a name to self identify
modeid: ModeId = ModeId.Null,

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

        if (self.targeter) |targeter| {
            if (targeter.function == .SubMap) {
                std.log.debug("you cant set targeter as submap", .{});
                return;
            }
            try targeter.run(state);
        }
    } else if (self.fallback) |fallback| {
        // if there is no handler and its just a regular key then send it to
        // the buffer
        try fallback.run(state);
    }
}

pub inline fn put(self: *KeyMaps, a: std.mem.Allocator, character: u16, value: KeyFunction) !void {
    try self.keys.put(a, character, value);
}

/// Gets the next
pub fn then(self: *KeyMaps, a: std.mem.Allocator, character: u16) !*KeyMaps {
    const res = try self.keys.getOrPut(a, character);
    if (res.found_existing) {
        switch (res.value_ptr.*) {
            .SubMap => |map| return map,
            .LuaFnc => |id| {
                // TODO: unref global
                _ = id;
            },
            else => {},
        }
    }
    const map = try a.create(KeyMaps);
    map.* = KeyMaps{};
    res.value_ptr.* = KeyFunction{ .SubMap = map };
    return map;
}

pub const action = struct {
    pub fn move(state: *State, _: ?*anyopaque) !void {
        try moveKeep(state);

        const buffer = state.getCurrentBuffer();

        buffer.target = null; // reset the target
        buffer.curkeymap = null;
    }

    pub fn moveKeep(state: *State) !void {
        const buffer = state.getCurrentBuffer();

        if (buffer.target) |target| {
            buffer.row = target.end.row;
            buffer.col = target.end.col;
        }
    }

    pub fn none(_: *State) !void {}
};

pub const KeyToFunction = std.AutoArrayHashMapUnmanaged(u16, KeyFunction);
