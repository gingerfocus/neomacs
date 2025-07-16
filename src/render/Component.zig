//! TODO: figure out how to compose these, have one component nest others
//!
const root = @import("../root.zig");
const std = root.std;
const lib = root.lib;

const State = root.State;
const Backend = State.Backend;

pub const View = lib.Vec4;

dataptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    renderFn: *const fn (*anyopaque, state: *State, writer: *Backend, veiw: View) void,
};
