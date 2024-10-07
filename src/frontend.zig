const defs = @import("defs.zig");
const bf = @import("buffer.zig");
const term = @import("thermit");
const scin = @import("scinee");

const std = @import("std");

const State = defs.State;

pub const sidebarWidth = 5;
pub const statusbarHeight = 2;

pub fn render(state: *State) !void {
    try state.term.start(false);
    defer state.term.finish() catch |err| std.log.err("{any}", .{err});

    const bufLen = sidebarWidth - 1;
    var buf: [bufLen]u8 = .{' '} ** bufLen;
    buf[bufLen - 1] = '|';

    for (0..state.line_num_win.h) |r| {
        const out = try std.fmt.bufPrint(&buf, "{}", .{r});
        std.debug.assert(out.len < 3);
        try state.term.draw(state.line_num_win, @intCast(r), 1, &buf);
    }

    // const row_render_start = struct {
    //     var static: usize = 0;
    // };

    //     const col_render_start = struct {
    //         var static: usize = 0;
    //     };

    //     _ = defs.werase(state.*.main_win);
    //     _ = defs.werase(state.*.status_bar);
    //     _ = defs.werase(state.*.line_num_win);

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

    //     if (is_term_resized(state.*.line_num_row, state.*.line_num_col)) { _ = blk: {
    //             state.*.grow = if (null != @as(?*const anyopaque, @ptrCast(stdscr))) @as(c_int, @bitCast(@as(c_int, stdscr.*._maxy))) + @as(c_int, 1) else -@as(c_int, 1);
    //             break :blk blk_1: {
    //                 const tmp = if (null != @as(?*const anyopaque, @ptrCast(stdscr))) @as(c_int, @bitCast(@as(c_int, stdscr.*._maxx))) + @as(c_int, 1) else -@as(c_int, 1);
    //                 state.*.gcol = tmp;
    //                 break :blk_1 tmp;
    //             };
    //         };
    //         _ = blk: {
    //             state.*.line_num_row = if (null != @as(?*const anyopaque, @ptrCast(state.*.line_num_win))) @as(c_int, @bitCast(@as(c_int, state.*.line_num_win.*._maxy))) + @as(c_int, 1) else -@as(c_int, 1);
    //             break :blk blk_1: {
    //                 const tmp = if (null != @as(?*const anyopaque, @ptrCast(state.*.line_num_win))) @as(c_int, @bitCast(@as(c_int, state.*.line_num_win.*._maxx))) + @as(c_int, 1) else -@as(c_int, 1);
    //                 state.*.line_num_col = tmp;
    //                 break :blk_1 tmp;
    //             };
    //         };
    //         _ = mvwin(state.*.status_bar, state.*.grow - @as(c_int, 2), @as(c_int, 0));
    //     }

    // if (state.status_bar_msg) |print_msg| {
    //     state.term.draw(state.status_bar, 1, 0, print_msg);
    //     state.status_bar_msg = null;
    // }

    const cur_row = 0;
    const cur_col = 0;

    {
        const position = try std.fmt.allocPrint(state.a, "{}:{}", .{ cur_row + 1, cur_col + 1 });
        defer state.a.free(position);
        try state.term.draw(
            state.status_bar,
            0,
            @intCast(state.status_bar.w - position.len),
            position,
        );
    }

    // const leader = state.config.leaders[@intFromEnum(state.leader)];
    // const leaders = try std.fmt.allocPrint(state.a, "{c}", .{leader});
    // defer state.a.free(leaders);
    // try state.term.draw(
    //     state.status_bar,
    //     0,
    //     11,
    //     leaders,
    // );

    const mode = state.config.mode.toString();
    try state.term.draw(state.status_bar, 0, 0, mode);

    {
        try state.term.draw(state.status_bar, 1, state.status_bar.w - 1, switch (state.leader) {
            .R => "r",
            .D => "d",
            .Y => "y",
            .NONE => " ", // clear an previous state
        });
        try state.term.draw(state.status_bar, 0, state.status_bar.w - 5, state.num.items);
    }

    if (state.config.mode == .COMMAND or state.config.mode == .SEARCH) {
        // const command = try std.fmt.allocPrint(state.a, ":{s}", .{ state.command });
        // defer state.a.free(command);
        // try state.term.draw(state.status_bar, 1, 0, command);
    }

    //     if (state.*.is_exploring) {
    //         _ = wattr_on(state.*.main_win, @as(attr_t, @bitCast((@as(chtype, @bitCast(BLUE_COLOR)) << @intCast(@as(c_int, 0) + @as(c_int, 8))) & (@as(chtype, @bitCast((@as(c_uint, 1) << @intCast(8)) -% @as(c_uint, 1))) << @intCast(@as(c_int, 0) + @as(c_int, 8))))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
    //         {
    //             var i: usize = row_render_start.static;
    //             _ = &i;
    //             while (i <= (row_render_start.static +% @as(usize, @bitCast(@as(c_long, state.*.main_row))))) : (i +%= 1) {
    //                 if (i >= state.*.files.*.count) break;
    //                 var print_index_y: usize = i -% row_render_start.static;
    //                 _ = &print_index_y;
    //                 _ = mvwprintw(state.*.main_win, @as(c_int, @bitCast(@as(c_uint, @truncate(print_index_y)))), @as(c_int, 0), "%s", state.*.files.*.data[i].name);
    //             }
    //         }
    //     } else {

    const row_render_start = 0;

    const buffer = state.buffer;
    // ---------------------------------
    var r: usize = row_render_start;
    while (r < buffer.rows.items.len and r < row_render_start + state.main_win.h) : (r += 1) {
        const row = buffer.rows.items[r];
        const bufdata = buffer.data.items[row.start..row.end];
        try state.term.draw(state.main_win, @intCast(r), 1, bufdata);
    }
    // ---------------------------------

    // var i: usize = row_render_start.static;
    // while (i <= (row_render_start.static +% @as(usize, @bitCast(@as(c_long, state.*.main_row))))) : (i +%= 1) {
    // if (i >= state.*.buffer.*.rows.count) break;
    // var print_index_y: usize = i -% row_render_start.static;
    // _ = &print_index_y;
    // _ = wattr_on(state.*.line_num_win, @as(attr_t, @bitCast((@as(chtype, @bitCast(YELLOW_COLOR)) << @intCast(@as(c_int, 0) + @as(c_int, 8))) & (@as(chtype, @bitCast((@as(c_uint, 1) << @intCast(8)) -% @as(c_uint, 1))) << @intCast(@as(c_int, 0) + @as(c_int, 8))))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
    // if (state.*.config.relative_nums != 0) {
    //     if (cur_row == i) {
    //         _ = mvwprintw(state.*.line_num_win, @as(c_int, @bitCast(@as(c_uint, @truncate(print_index_y)))), @as(c_int, 0), "%zu", i +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    //     } else {
    //         _ = mvwprintw(state.*.line_num_win, @as(c_int, @bitCast(@as(c_uint, @truncate(print_index_y)))), @as(c_int, 0), "%zu", @as(usize, @bitCast(@as(c_long, abs(@as(c_int, @bitCast(@as(c_uint, @truncate(i)))) - @as(c_int, @bitCast(@as(c_uint, @truncate(cur_row)))))))));
    //     }
    // } else {
    //     _ = mvwprintw(state.*.line_num_win, @as(c_int, @bitCast(@as(c_uint, @truncate(print_index_y)))), @as(c_int, 0), "%zu", i +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    // }

    // _ = wattr_off(state.*.line_num_win, @as(attr_t, @bitCast((@as(chtype, @bitCast(YELLOW_COLOR)) << @intCast(@as(c_int, 0) + @as(c_int, 8))) & (@as(chtype, @bitCast((@as(c_uint, 1) << @intCast(8)) -% @as(c_uint, 1))) << @intCast(@as(c_int, 0) + @as(c_int, 8))))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
    // var off_at: usize = 0;
    // var token_capacity: usize = 32;
    // var token_arr: *Token = @as(*Token, @ptrCast(@alignCast(calloc(token_capacity, @sizeOf(Token)))));
    // var token_s: usize = 0;
    // if (state.*.config.syntax != 0) {
    //     token_s = lx.generate_tokens(state.*.buffer.*.data.data + state.*.buffer.*.rows.data[i].start, state.*.buffer.*.rows.data[i].end -% state.*.buffer.*.rows.data[i].start, token_arr, &token_capacity);
    // }
    // var color: Color_Pairs = 0;

    // {
    //     var j: usize = state.*.buffer.*.rows.data[i].start;
    //     _ = &j;
    //     while (j < state.*.buffer.*.rows.data[i].end) : (j +%= 1) {
    //         if ((j < (state.*.buffer.*.rows.data[i].start +% col_render_start.static)) or (j > ((state.*.buffer.*.rows.data[i].end +% col) +% @as(usize, @bitCast(@as(c_long, state.*.main_col)))))) continue;
    //         var col_1: usize = j -% state.*.buffer.*.rows.data[i].start;
    //         _ = &col_1;
    //         var print_index_x: usize = col_1 -% col_render_start.static;
    //         _ = &print_index_x;
    //         {
    //             var chr: usize = state.*.buffer.*.rows.data[i].start;
    //             _ = &chr;
    //             while (chr < j) : (chr +%= 1) {
    //                 if (@as(c_int, @bitCast(@as(c_uint, state.*.buffer.*.data.data[chr]))) == @as(c_int, '\t')) {
    //                     print_index_x +%= @as(usize, @bitCast(@as(c_long, @as(c_int, 3))));
    //                 }
    //             }
    //         }
    //         var keyword_size: usize = 0;
    //         _ = &keyword_size;
    //         if ((state.*.config.syntax != 0) and (is_in_tokens_index(token_arr, token_s, col_1, &keyword_size, &color) != 0)) {
    //             _ = wattr_on(state.*.main_win, @as(attr_t, @bitCast((@as(chtype, @bitCast(color)) << @intCast(@as(c_int, 0) + @as(c_int, 8))) & (@as(chtype, @bitCast((@as(c_uint, 1) << @intCast(8)) -% @as(c_uint, 1))) << @intCast(@as(c_int, 0) + @as(c_int, 8))))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
    //             off_at = col_1 +% keyword_size;
    //         }
    //         if (col_1 == off_at) {
    //             _ = wattr_off(state.*.main_win, @as(attr_t, @bitCast((@as(chtype, @bitCast(color)) << @intCast(@as(c_int, 0) + @as(c_int, 8))) & (@as(chtype, @bitCast((@as(c_uint, 1) << @intCast(8)) -% @as(c_uint, 1))) << @intCast(@as(c_int, 0) + @as(c_int, 8))))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
    //         }
    //         if (col_1 > state.*.buffer.*.rows.data[i].end) break;
    //         var between: c_int = if (state.*.buffer.*.visual.start > state.*.buffer.*.visual.end) is_between(state.*.buffer.*.visual.end, state.*.buffer.*.visual.start, state.*.buffer.*.rows.data[i].start +% col_1) else is_between(state.*.buffer.*.visual.start, state.*.buffer.*.visual.end, state.*.buffer.*.rows.data[i].start +% col_1);
    //         _ = &between;
    //         if ((state.*.config.mode == @as(c_uint, @bitCast(VISUAL))) and (between != 0)) {
    //             _ = wattr_on(state.*.main_win, @as(attr_t, @bitCast(@as(chtype, @bitCast(@as(c_uint, 1))) << @intCast(@as(c_int, 8) + @as(c_int, 8)))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
    //         } else {
    //             _ = wattr_off(state.*.main_win, @as(attr_t, @bitCast(@as(chtype, @bitCast(@as(c_uint, 1))) << @intCast(@as(c_int, 8) + @as(c_int, 8)))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
    //         }
    //         _ = mvwprintw(state.*.main_win, @as(c_int, @bitCast(@as(c_uint, @truncate(print_index_y)))), @as(c_int, @bitCast(@as(c_uint, @truncate(print_index_x)))), "%c", @as(c_int, @bitCast(@as(c_uint, state.*.buffer.*.data.data[state.*.buffer.*.rows.data[i].start +% col_1]))));
    //     }
    // }
    // free(@as(?*anyopaque, @ptrCast(token_arr)));
    // }

    // try term.cursorShow(state.term.tty.f.writer());

    // col +%= count_num_tabs(state.*.buffer, bf.buffer_get_row(state.*.buffer)) *% @as(usize, @bitCast(@as(c_long, @as(c_int, 3))));

    // _ = wrefresh(state.*.main_win);
    // _ = wrefresh(state.*.line_num_win);
    // _ = wrefresh(state.*.status_bar);

    // if ((state.*.config.mode == @as(c_uint, @bitCast(COMMAND))) or (state.*.config.mode == @as(c_uint, @bitCast(SEARCH)))) {
    //     frontend_move_cursor(state.*.status_bar, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), state.*.x);
    //     _ = wrefresh(state.*.status_bar);
    // } else {
    //     frontend_move_cursor(state.*.main_win, cur_row -% row_render_start.static, col -% col_render_start.static);
    // }

    state.resized = false;
}

// pub fn frontend_resize_window(arg_state: *State) void {
//     var state = arg_state;
//     _ = &state;
//     _ = blk: {
//         state.*.grow = if (null != @as(?*const anyopaque, @ptrCast(stdscr))) @as(c_int, @bitCast(@as(c_int, stdscr.*._maxy))) + @as(c_int, 1) else -@as(c_int, 1);
//         break :blk blk_1: {
//             const tmp = if (null != @as(?*const anyopaque, @ptrCast(stdscr))) @as(c_int, @bitCast(@as(c_int, stdscr.*._maxx))) + @as(c_int, 1) else -@as(c_int, 1);
//             state.*.gcol = tmp;
//             break :blk_1 tmp;
//         };
//     };
//     _ = wresize(state.*.main_win, state.*.grow - @as(c_int, 2), state.*.gcol - state.*.line_num_col);
//     _ = wresize(state.*.status_bar, @as(c_int, 2), state.*.gcol);
//     _ = blk: {
//         state.*.main_row = if (null != @as(?*const anyopaque, @ptrCast(state.*.main_win))) @as(c_int, @bitCast(@as(c_int, state.*.main_win.*._maxy))) + @as(c_int, 1) else -@as(c_int, 1);
//         break :blk blk_1: {
//             const tmp = if (null != @as(?*const anyopaque, @ptrCast(state.*.main_win))) @as(c_int, @bitCast(@as(c_int, state.*.main_win.*._maxx))) + @as(c_int, 1) else -@as(c_int, 1);
//             state.*.main_col = tmp;
//             break :blk_1 tmp;
//         };
//     };
//     _ = mvwin(state.*.main_win, @as(c_int, 0), state.*.line_num_col);
//     _ = wrefresh(state.*.main_win);
// }

// pub fn frontend_move_cursor(arg_window: *WINDOW, arg_x_pos: usize, arg_y_pos: usize) void {
//     var window = arg_window;
//     _ = &window;
//     var x_pos = arg_x_pos;
//     _ = &x_pos;
//     var y_pos = arg_y_pos;
//     _ = &y_pos;
//     _ = wmove(window, @as(c_int, @bitCast(@as(c_uint, @truncate(x_pos)))), @as(c_int, @bitCast(@as(c_uint, @truncate(y_pos)))));
// }

// pub fn frontend_cursor_visible(arg_value: c_int) void {
//     var value = arg_value;
//     _ = &value;
//     _ = curs_set(value);
// }

// deinit
// printf("\x1b[0 q");
