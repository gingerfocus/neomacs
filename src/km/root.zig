//! TODO: Fully modular system for keymaps
//! Dont have the nuance of reference counting escape this file

const root = @import("../root.zig");
const std = root.std;
// const rc = @import("zigrc");

pub const KeyFunction = @import("KeyFunction.zig");
pub const KeyMaps = @import("KeyMaps.zig");

pub const ModeId = root.Buffer.ModeId;
pub const ModeToKeys = std.AutoArrayHashMapUnmanaged(ModeId, *KeyMaps);

