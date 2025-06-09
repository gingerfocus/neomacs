const root = @import("root");
const lib = root.lib;

const Comp = @import("Component.zig");

view: View,
comp: Comp,

pub const View = struct {
    start: lib.Vec2,
    spans: lib.Vec2,
};
