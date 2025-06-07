const backend = @import("backend.zig");
const root = @import("root");

const scu = @import("scured");
const lib = root.lib;

const TerminalBackend = struct {
    terminal: scu.Term,

    fn renderer(self: *TerminalBackend) backend.Renderer {
        return backend.Renderer{
            .dataptr = self,
            .vtable = .{
                .queryNode = __queryNode,
            },
        };
    }

    fn __queryNode(ptr: *anyopaque, pos: lib.Vec2) ?*backend.Node {
        const self = @as(*TerminalBackend, @ptrCast(@alignCast(ptr)));

        return self.terminal.getCell(pos.row, pos.col);
    }
};
