const std = @import("std");

const defs = @import("defs.zig");
// const scu = root.scu

const State = @import("State.zig");
// const Buffer = @import("Buffer.zig");

pub const sidebarWidth = 3;
pub const statusbarHeight = 2;

pub fn render(state: *State) !void {
    try state.term.start(state.resized);
    defer state.term.finish() catch |err| std.log.err("{any}", .{err});

    const cur_row = 2;
    const cur_col = 0;

    // TODO: should be in state
    const row_render_start = 0;
    const col_render_start = 0;

    _ = col_render_start; // autofix

    if (state.resized) {
        // nothing
    }

    // const row: usize = bf.bufferGetRow(state.buffer.?);
    // if (state.is_exploring) {
    //     cur_row = state.*.explore_cursor;
    // }
    // const cur: defs.Row = state.buffer.?.rows.items[row];

    // const col: usize = state.buffer.?.cursor - cur.start;
    // if (state.is_exploring) col = 0;

    //     if (cur_row <= row_render_start.static) {
    //         row_render_start.static = cur_row;
    //     }
    //     if (cur_row >= (row_render_start.static +% @as(usize, @bitCast(@as(c_long, state.*.main_row))))) {
    //         row_render_start.static = (cur_row -% @as(usize, @bitCast(@as(c_long, state.*.main_row)))) +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    //     }
    //     if (col <= col_render_start.static) {
    //         col_render_start.static = col;
    //     }
    //     if (col >= (col_render_start.static +% @as(usize, @bitCast(@as(c_long, state.*.main_col))))) {
    //         col_render_start.static = (col -% @as(usize, @bitCast(@as(c_long, state.*.main_col)))) +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    //     }
    //     state.*.num_of_braces = num_of_open_braces(state.*.buffer);

    if (state.status_bar_msg) |print_msg| {
        state.term.writeBuffer(state.status_bar, 0, 1, print_msg);
        state.status_bar_msg = null;
    }

    {
        const position = try std.fmt.allocPrint(state.a, "{}:{}", .{ cur_row + 1, cur_col + 1 });
        defer state.a.free(position);
        state.term.writeBuffer(
            state.status_bar,
            @intCast(state.status_bar.w - position.len),
            0,
            position,
        );
    }

    const mode = state.config.mode.toString();
    state.term.writeBuffer(state.status_bar, 0, 0, mode);

    // {
    //     state.term.writeBuffer(state.status_bar, state.status_bar.w - 1, 1, switch (state.leader) {
    //         .R => "r",
    //         .D => "d",
    //         .Y => "y",
    //         .NONE => " ", // clear an previous state
    //     });
    //     state.term.writeBuffer(state.status_bar, state.status_bar.w - 5, 0, state.num.items);
    // }

    // if (state.config.mode == .COMMAND or state.config.mode == .SEARCH) {
    //     const command = try std.fmt.allocPrint(state.a, ":{s}", .{state.command});
    //     defer state.a.free(command);
    //     try state.term.draw(state.status_bar, 1, 0, command);
    // }

    // if (state.*.is_exploring) {
    //     _ = wattr_on(state.*.main_win, @as(attr_t, @bitCast((@as(chtype, @bitCast(BLUE_COLOR)) << @intCast(@as(c_int, 0) + @as(c_int, 8))) & (@as(chtype, @bitCast((@as(c_uint, 1) << @intCast(8)) -% @as(c_uint, 1))) << @intCast(@as(c_int, 0) + @as(c_int, 8))))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
    //     {
    //         var i: usize = row_render_start.static;
    //         _ = &i;
    //         while (i <= (row_render_start.static +% @as(usize, @bitCast(@as(c_long, state.*.main_row))))) : (i +%= 1) {
    //             if (i >= state.*.files.*.count) break;
    //             var print_index_y: usize = i -% row_render_start.static;
    //             _ = &print_index_y;
    //             _ = mvwprintw(state.*.main_win, @as(c_int, @bitCast(@as(c_uint, @truncate(print_index_y)))), @as(c_int, 0), "%s", state.*.files.*.data[i].name);
    //         }
    //     }
    // }

    const relative_nums = false;

    // ----- main buffer ----------------------------
    {
        var r: usize = row_render_start;
        while (r < state.buffer.rows.items.len and r < row_render_start + state.main_win.h) : (r += 1) {
            const row = state.buffer.rows.items[r];
            const bufdata = state.buffer.data.items[row.start..row.end];
            var c: u16 = 1;
            for (bufdata) |ch| {
                const cell = state.term.getScreenCell(state.main_win, c, @intCast(r)) orelse break;
                cell.fg = .DarkBlue;
                // cell.bg = .Black;

                cell.setSymbol(ch);
                c += 1;
            }

            // ---- line numbers -------------------------
            if (r - row_render_start < state.line_num_win.h) {
                const lineNumber = if (relative_nums) blk: {
                    const srow = @as(isize, cur_row);
                    const sr = @as(isize, @intCast(r));
                    const res: usize = @abs(srow - sr);
                    if (res == 0) break :blk r + 1;
                    break :blk res;
                } else blk: {
                    break :blk r + 1;
                };

                const BUFSIZE = 8;
                std.debug.assert(BUFSIZE >= sidebarWidth);

                var buf: [BUFSIZE]u8 = undefined;
                const data = try std.fmt.bufPrint(&buf, "{}", .{lineNumber});

                c = 0;
                for (data) |ch| {
                    const cell = state.term.getScreenCell(state.line_num_win, c, @intCast(r)) orelse break;
                    cell.fg = .Yellow;
                    cell.setSymbol(ch);
                    c += 1;
                }
            } else unreachable; // I think this is a bug not sure
            // -------------------------------------------
        }
    }
    // -------------------------------------------

    if (state.config.mode == .COMMAND or state.config.mode == .SEARCH) {
        // frontend_move_cursor(state.*.status_bar, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), state.*.x);
    } else {
        // TODO: account for tab characters
        // col = cur_row + countTabs() * 3;

        // state.term.moveCursor(state.*.main_win, cur_row -% row_render_start, col - col_render_start);
    }

    // we just finised rendering so we know that the current buffer is the
    // right size
    state.resized = false;
}
