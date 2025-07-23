const std = @import("std");
const root = @import("../../root.zig");
const lib = root.lib;

const State = root.State;
const Backend = root.Backend;
const Color = Backend.Color;
const View = @import("../Component.zig").View;

pub fn render(self: *anyopaque, state: *State, writer: *Backend, view: View) void {
    // TODO: clear each time

    _ = self;
    // TODO: this should have buffer as its self
    const buffer = state.getCurrentBuffer();
    const row_render_start = std.math.sub(usize, buffer.row + state.config.scrolloff, view.h) catch 0;

    var renderRow: usize = row_render_start;
    while (renderRow < buffer.lines.items.len and renderRow < row_render_start + view.h) : (renderRow += 1) {
        const realRow = buffer.row;
        const lineNumber = if (true) blk: {
            const res = if (realRow > renderRow)
                realRow - renderRow
            else if (realRow == renderRow)
                renderRow + 1
            else
                renderRow - realRow;
            if (res == 0) break :blk renderRow + 1;
            break :blk res;
        } else blk: {
            break :blk renderRow + 1;
        };

        var buf: [8]u8 = undefined;
        const data = std.fmt.bufPrint(&buf, "{}", .{lineNumber}) catch return;
        for (data, 0..) |ch, c2| {
            writer.draw(
                .{ .col = view.x + c2, .row = view.y + @as(usize, @intCast(renderRow - row_render_start)) },
                .{
                    .foreground = Color.Yellow,
                    .background = Color.Black,
                    .content = .{ .Text = ch },
                },
            );
        }
        var c2: usize = data.len;
        while (c2 < view.w) : (c2 += 1) {
            writer.draw(
                .{ .col = view.x + c2, .row = view.y + @as(usize, @intCast(renderRow - row_render_start)) },
                .{
                    .background = Color.Black,
                    .content = .{ .Text = ' ' },
                },
            );
        }
    }
}
