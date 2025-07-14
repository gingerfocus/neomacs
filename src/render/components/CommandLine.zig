const std = @import("std");
const root = @import("../../root.zig");
const lib = root.lib;

const State = root.State;
const Backend = State.Backend;
const Color = Backend.Color;
const View = @import("../Component.zig").View;

pub fn render(self: *anyopaque, state: *State, writer: *Backend, view: View) void {
    _ = self;
    _ = state;
    _ = writer;
    _ = view;
    // if (state.command.is) {
    //     const command = std.fmt.allocPrint(state.a, ":{s}", .{state.command.buffer.items}) catch return;
    //     defer state.a.free(command);
    //
    //     for (command, 0..) |ch, i| {
    //         writer.draw(
    //             .{ .col = view.x + i, .row = view.y },
    //             .{
    //                 .background = Color.Black,
    //                 .foreground = Color.White,
    //                 .content = .{ .Text = ch },
    //             },
    //         );
    //     }
    //     writer.setCursor(.{ .col = view.x + command.len, .row = view.y });
    // }
}
