const root = @import("../../root.zig");
const std = root.std;
const lib = root.lib;

const State = root.State;
const Backend = State.Backend;
const Color = Backend.Color;
const View = @import("../Component.zig").View;

pub fn render(self: *anyopaque, state: *State, writer: *Backend, view: View) void {
    _ = self;
    var y: u16 = 0;
    var x: u16 = 0;
    while (y < view.h) : (y += 1) {
        x = 0;
        while (x < view.w) : (x += 1) {
            writer.draw(
                .{ .col = view.x + x, .row = view.y + y },
                .{
                    .background = Color.Black,
                    .content = .{ .Text = ' ' },
                },
            );
        }
    }

    if (state.command.is) {
        const command = std.fmt.allocPrint(state.a, ":{s}", .{state.command.buffer.items}) catch return;
        defer state.a.free(command);

        for (command, 0..) |ch, i| {
            writer.draw(
                .{ .col = view.x + i, .row = view.y + 1 },
                .{
                    .background = Color.Black,
                    .foreground = Color.White,
                    .content = .{ .Text = ch },
                },
            );
        }
    }

    const buffer = state.getCurrentBuffer() orelse return;

    if (state.status_bar_msg) |print_msg| {
        for (print_msg, 0..) |ch, i| {
            writer.draw(
                .{ .col = view.x + i, .row = view.y + 1 },
                .{
                    .background = Color.Black,
                    .foreground = Color.White,
                    .content = .{ .Text = ch },
                },
            );
        }
        state.status_bar_msg = null;
    }

    {
        const position = std.fmt.allocPrint(state.a, "{}:{}", .{ buffer.row + 1, buffer.col + 1 }) catch return;
        defer state.a.free(position);
        const x2 = view.w - position.len;
        for (position, 0..) |ch, i| {
            writer.draw(
                .{ .col = view.x + x2 + i, .row = view.y + 0 },
                .{
                    .background = Color.Black,
                    .foreground = Color.White,
                    .content = .{ .Text = ch },
                },
            );
        }
    }

    {
        const mode = state.buffer.mode.toString();
        for (mode, 0..) |ch, i| {
            writer.draw(
                .{ .col = view.x + i, .row = view.y + 0 },
                .{
                    .background = Color.Black,
                    .foreground = Color.Yellow,
                    .content = .{ .Text = ch },
                },
            );
        }
    }
}
