const std = @import("std");
const root = @import("../../main.zig");
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

    const buffer = state.getCurrentBuffer() orelse return;
    const row_render_start = std.math.sub(usize, buffer.row, view.h) catch 0;

    var renderRow: usize = row_render_start;
    while (renderRow < buffer.lines.items.len and renderRow < row_render_start + view.h) : (renderRow += 1) {
        const line = buffer.lines.items[renderRow];
        const bufdata = line.data.items;

        for (bufdata, 0..) |ch, c| {
            writer.draw(
                .{ .col = view.x + 1 + c, .row = @as(usize, @intCast(view.y)) + renderRow - row_render_start },
                .{
                    .foreground = if (ch == ' ') Color.Cyan else Color.DarkBlue,
                    .background = Color.Black,
                    .content = .{ .Text = if (ch == ' ') '-' else ch },
                },
            );
        }
    }

    if (buffer.target) |visual| {
        var cur = visual.start;
        const end = visual.end;
        while (true) {
            if (cur.row > end.row) break;
            if (cur.row == end.row and cur.col >= end.col) break;

            writer.draw(
                .{ .col = @as(usize, @intCast(view.x)) + 1 + cur.col, .row = @as(usize, @intCast(view.y)) + cur.row - row_render_start },
                .{
                    .background = Color.Reset,
                    .content = .{ .Text = buffer.lines.items[cur.row].data.items[cur.col] },
                },
            );

            cur = buffer.moveRight(cur, 1);
        }
    }
}
