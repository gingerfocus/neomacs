const std = @import("std");
const root = @import("../root.zig");
const lib = root.lib;

const State = root.State;
const Backend = State.Backend;

pub const View = lib.Vec4;

dataptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    renderFn: *const fn (*anyopaque, state: *State, writer: *Backend, veiw: View) void,
};
