const std = @import("std");
const root = @import("../root.zig");
const lib = root.lib;
const km = root.km;

const State = root.State;
const Backend = root.Backend;
const Color = Backend.Color;
const View = root.Component.View;

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

    const buffer = state.getCurrentBuffer();
    const row_render_start = std.math.sub(usize, buffer.row + state.config.scrolloff, view.h) catch 0;

    var renderRow: usize = row_render_start;
    while (renderRow < buffer.numLines() and renderRow < row_render_start + view.h) : (renderRow += 1) {
        const bufdata = buffer.getLine(renderRow) catch @panic("oom");
        const items = bufdata.items;
        defer bufdata.deinit();

        for (items, 0..) |ch, c| {
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
        var cur = visual.beg;
        const end = visual.end;
        while (true) {
            if (cur.row > end.row) break;
            if (cur.row == end.row and cur.col >= end.col) break;

            const bufdata = buffer.getLine(cur.row) catch @panic("oom");
            const items = bufdata.items;
            defer bufdata.deinit();

            writer.draw(
                .{ .col = @as(usize, @intCast(view.x)) + 1 + cur.col, .row = @as(usize, @intCast(view.y)) + cur.row - row_render_start },
                .{
                    .background = Color.Red,
                    .foreground = Color.White,
                    .content = .{ .Text = if (items.len == 0) ' ' else items[cur.col] },
                },
            );

            cur = buffer.moveRight(cur, 1);
        }
    }

    // render the cursor
    if (buffer.mode._ != km.ModeId.Command._) {
        const cursormode: root.trm.CursorStyle = if (buffer.mode.eql(km.ModeId.Insert)) .SteadyBar else .SteadyBlock;

        writer.setCursor(.{ .col = view.x + buffer.col + 1, .row = view.y + buffer.row - row_render_start }, cursormode);
    }
}
