const std = @import("std");
const root = @import("../../root.zig");
const lib = root.lib;

const State = root.State;
const Backend = root.Backend;
const Color = Backend.Color;
const View = @import("../Component.zig").View;

pub fn render(self: *anyopaque, state: *State, writer: *Backend, view: View) void {
    _ = self;

    const buffer = state.getCurrentBuffer();

    // TODO: make a comparison API for modes
    if (buffer.mode._ == root.km.ModeId.Command._) {
        const command = std.fmt.allocPrint(state.a, ":{s}", .{state.commandbuffer.items}) catch return;
        defer state.a.free(command);

        for (command, 0..) |ch, i| {
            writer.draw(
                .{ .col = view.x + i, .row = view.y },
                .{
                    .background = Color.Black,
                    .foreground = Color.White,
                    .content = .{ .Text = ch },
                },
            );
        }
        writer.setCursor(.{ .col = view.x + command.len, .row = view.y }, .BlinkingBlock);
    }
}
