const std = @import("std");
const root = @import("root");

const Screen = @import("Screen.zig");

const Backend = root.State.Backend;

dataptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    renderFn: *const fn (*anyopaque, veiw: Screen.View, writer: Backend) void,
};
