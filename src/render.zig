const root = @import("root");
const std = @import("std");
const scu = root.scu;
const trm = root.trm;
const lib = root.lib;

const State = root.State;
const Backend = @import("backend/Backend.zig");
const Node = Backend.Node;
const Color = Backend.Color;

pub const sidebarWidth = 3;
pub const statusbarHeight = 2;

// pub fn draw(state: *State) !void {
//     state.backend.render(.begin);
//     defer state.backend.render(.end);

//     state.backend.draw(.{ .col = 3, .row = 3 }, .{ .background = .Black, .content = .{ .Text = 'o' } });

//     if (true) return;

//     const BackendTerminal = @import("backend/BackendTerminal.zig");
//     const backend = @as(*BackendTerminal, @ptrCast(@alignCast(state.backend.dataptr)));
//     const term = &backend.terminal;

//     if (state.resized) {
//         // nothing
//         root.log(@src(), .info, "starting window resize render", .{});

//         const size = term.size;

//         state.line_num_win = term.makeScreen(0, 0, sidebarWidth, size.y - statusbarHeight);
//         state.status_bar = term.makeScreen(0, size.y - statusbarHeight, null, null);
//         state.main_win = term.makeScreen(sidebarWidth, 0, null, size.y - statusbarHeight);
//     }

//     // ---- clear status bar --------
//     {
//         var x: u16 = 0;
//         while (x < state.status_bar.w) : (x += 1) {
//             var y: u16 = 0;
//             while (y < state.status_bar.h) : (y += 1) {
//                 const cell = term.getScreenCell(state.status_bar, x, y).?;
//                 cell.setSymbol(' ');
//                 // cell.bg = .Cyan;
//             }
//         }
//     }
//     // ------------------------------

//     if (state.command.is) {
//         // if (state.buffer.mode == .comand or state.buffer.mode == .search) {
//         const command = try std.fmt.allocPrint(state.a, ":{s}", .{state.command.buffer.items});
//         defer state.a.free(command);
//         term.writeBuffer(state.status_bar, 0, 1, command);

//         term.moveCursor(state.status_bar, @intCast(1 + state.command.buffer.items.len), 1); // state.x
//     }

//     const buffer = state.getCurrentBuffer() orelse return;
//     const realRow = buffer.row;

//     // TODO: should be in state

//     const scroll = .{
//         .row = std.math.sub(usize, realRow, term.size.y) catch 0,
//         .col = 0,
//     };
//     const row_render_start = scroll.row;
//     const col_render_start = scroll.col;

//     const viewportRow = buffer.row - row_render_start;
//     const viewportCol = buffer.col - col_render_start;

//     // const row: usize = bf.bufferGetRow(state.buffer.?);
//     // if (state.is_exploring) {
//     //     cur_row = state.*.explore_cursor;
//     // }
//     // const cur: defs.Row = state.buffer.?.rows.items[row];

//     // const col: usize = state.buffer.?.cursor - cur.start;
//     // if (state.is_exploring) col = 0;

//     if (state.status_bar_msg) |print_msg| {
//         term.writeBuffer(state.status_bar, 0, 1, print_msg);
//         state.status_bar_msg = null;
//     }

//     {
//         const position = try std.fmt.allocPrint(state.a, "{}:{}", .{ buffer.row + 1, buffer.col + 1 });
//         defer state.a.free(position);
//         term.writeBuffer(
//             state.status_bar,
//             @intCast(state.status_bar.w - position.len),
//             0,
//             position,
//         );
//     }

//     const mode = state.buffer.mode.toString();
//     term.writeBuffer(state.status_bar, 0, 0, mode);

//     // {
//     //     state.term.writeBuffer(state.status_bar, state.status_bar.w - 1, 1, switch (state.leader) {
//     //         .R => "r",
//     //         .D => "d",
//     //         .Y => "y",
//     //         .NONE => " ", // clear an previous state
//     //     });
//     //     // state.term.writeBuffer(state.status_bar, state.status_bar.w - 5, 0, state.num.items);
//     // }

//     // if (state.*.is_exploring) {
//     //     _ = wattr_on(state.*.main_win, @as(attr_t, @bitCast((@as(chtype, @bitCast(BLUE_COLOR)) << @intCast(@as(c_int, 0) + @as(c_int, 8))) & (@as(chtype, @bitCast((@as(c_uint, 1) << @intCast(8)) -% @as(c_uint, 1))) << @intCast(@as(c_int, 0) + @as(c_int, 8))))), @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
//     //     {
//     //         var i: usize = row_render_start.static;
//     //         _ = &i;
//     //         while (i <= (row_render_start.static +% @as(usize, @bitCast(@as(c_long, state.*.main_row))))) : (i +%= 1) {
//     //             if (i >= state.*.files.*.count) break;
//     //             var print_index_y: usize = i -% row_render_start.static;
//     //             _ = &print_index_y;
//     //             _ = mvwprintw(state.*.main_win, @as(c_int, @bitCast(@as(c_uint, @truncate(print_index_y)))), @as(c_int, 0), "%s", state.*.files.*.data[i].name);
//     //         }
//     //     }
//     // }

//     const relative_nums = true;

//     // ----- clear main buffer ----
//     {
//         var x: u16 = 0;
//         while (x < state.main_win.w) : (x += 1) {
//             var y: u16 = 0;
//             while (y < state.main_win.h) : (y += 1) {
//                 const cell = term.getScreenCell(state.main_win, x, y).?;
//                 cell.setSymbol(' ');
//                 cell.bg = .Black;
//             }
//         }
//     }
//     // ----------------------------

//     // ----- main buffer ----------------------------
//     {
//         var renderRow: usize = row_render_start;
//         while (renderRow < buffer.lines.items.len and renderRow < row_render_start + state.main_win.h) : (renderRow += 1) {
//             const line = buffer.lines.items[renderRow];
//             const bufdata = line.data.items;
//             // root.log(@src(), .debug, "rendering row {d} with {d} chars ({s})", .{ renderRow, bufdata.len, bufdata });
//             var c: u16 = 1;
//             for (bufdata) |ch| {
//                 const cell = term.getScreenCell(state.main_win, c, @intCast(renderRow)) orelse break;
//                 cell.fg = .DarkBlue;
//                 cell.bg = .Black;

//                 cell.setSymbol(ch);

//                 if (ch == ' ') {
//                     cell.fg = .Cyan;
//                     cell.setSymbol('-');
//                 }
//                 c += 1;
//             }

//             // ---- line numbers -------------------------
//             if (renderRow - row_render_start < state.line_num_win.h) {
//                 const lineNumber = if (relative_nums) blk: {
//                     const res = if (realRow > renderRow)
//                         realRow - renderRow
//                     else if (realRow == renderRow)
//                         renderRow + 1
//                     else
//                         renderRow - realRow;

//                     if (res == 0) break :blk renderRow + 1;
//                     break :blk res;
//                 } else blk: {
//                     break :blk renderRow + 1;
//                 };

//                 const BUFSIZE = 8;
//                 std.debug.assert(BUFSIZE >= sidebarWidth);

//                 var buf: [BUFSIZE]u8 = undefined;
//                 const data = try std.fmt.bufPrint(&buf, "{}", .{lineNumber});

//                 for (0..state.line_num_win.w) |c2| {
//                     const c6: u16 = @intCast(c2);
//                     const cell = term.getScreenCell(state.line_num_win, c6, @intCast(renderRow)) orelse break;
//                     if (c2 >= data.len) {
//                         cell.setSymbol(' ');
//                     } else {
//                         const ch = data[c2];
//                         cell.fg = .Yellow;
//                         cell.setSymbol(ch);
//                     }
//                 }

//                 // c = 0;
//                 // for (data) |ch| {
//                 //     const cell = state.term.getScreenCell(state.line_num_win, c, @intCast(renderRow)) orelse break;
//                 //     cell.fg = .Yellow;
//                 //     cell.setSymbol(ch);
//                 //     c += 1;
//                 // }
//             } else unreachable; // I think this is a bug not sure
//             // -------------------------------------------
//         }
//     }
//     // -------------------------------------------

//     if (buffer.target) |visual| {
//         // root.log(@src(), .debug, "got visual selection {any}", .{visual});
//         _ = visual.mode;

//         var cur = visual.start;

//         const end = visual.end;
//         while (true) {
//             if (cur.row > end.row) break;
//             if (cur.row == end.row and cur.col >= end.col) break;

//             const row: u16 = @intCast(cur.row);
//             const col: u16 = @intCast(cur.col + 1); // add buffer row

//             if (term.getScreenCell(state.main_win, col, row)) |cell| {
//                 // root.log(@src(), .debug, "highlight cell {} {}", .{ row, col });
//                 cell.bg = .Reset;
//             }

//             cur = buffer.moveRight(cur, 1);
//         }
//     }

//     // TODO: account for tab characters
//     // const col = cur_row; // + countTabs() * 3;

//     if (!state.command.is) {
//         term.moveCursor(state.main_win, @intCast(viewportCol + 1), @intCast(viewportRow));
//     }

//     try handleCursorShape(state);

//     // we just finised rendering so we know that the current buffer is the
//     // right size
//     state.resized = false;
// }

pub fn draw(state: *State) !void {
    state.backend.render(.begin);
    defer state.backend.render(.end);

    // Example: draw a single cell at (3,3)
    state.backend.draw(
        .{ .col = 3, .row = 3 },
        .{
            .background = Color.Black,
            .content = .{ .Text = 'o' },
        },
    );

    // --- Layout calculations ---
    // (Assume state.resized and window management is handled elsewhere)

    // --- Clear status bar ---
    var y: u16 = 0;
    var x: u16 = 0;
    while (y < state.status_bar.h) : (y += 1) {
        x = 0;
        while (x < state.status_bar.w) : (x += 1) {
            state.backend.draw(
                .{ .col = x, .row = state.status_bar.y + y },
                .{
                    .background = Color.Black,
                    .content = .{ .Text = ' ' },
                },
            );
        }
    }

    // --- Draw command line if active ---
    if (state.command.is) {
        const command = try std.fmt.allocPrint(state.a, ":{s}", .{state.command.buffer.items});
        defer state.a.free(command);

        for (command, 0..) |ch, i| {
            state.backend.draw(
                .{ .col = i, .row = state.status_bar.y + 1 },
                .{
                    .background = Color.Black,
                    .foreground = Color.White,
                    .content = .{ .Text = ch },
                },
            );
        }
        // Cursor movement is backend-specific, not handled here.
    }

    const buffer = state.getCurrentBuffer() orelse return;
    // const realRow = buffer.row;

    // --- Status bar message ---
    if (state.status_bar_msg) |print_msg| {
        for (print_msg, 0..) |ch, i| {
            state.backend.draw(
                .{ .col = i, .row = state.status_bar.y + 1 },
                .{
                    .background = Color.Black,
                    .foreground = Color.White,
                    .content = .{ .Text = ch },
                },
            );
        }
        state.status_bar_msg = null;
    }

    // --- Status bar: position ---
    {
        const position = try std.fmt.allocPrint(state.a, "{}:{}", .{ buffer.row + 1, buffer.col + 1 });
        defer state.a.free(position);
        const x2 = state.status_bar.w - position.len;
        for (position, 0..) |ch, i| {
            state.backend.draw(
                .{ .col = x2 + i, .row = state.status_bar.y + 0 },
                .{
                    .background = Color.Black,
                    .foreground = Color.White,
                    .content = .{ .Text = ch },
                },
            );
        }
    }

    // --- Status bar: mode ---
    {
        const mode = state.buffer.mode.toString();
        for (mode, 0..) |ch, i| {
            state.backend.draw(
                .{ .col = i, .row = state.status_bar.y + 0 },
                .{
                    .background = Color.Black,
                    .foreground = Color.Yellow,
                    .content = .{ .Text = ch },
                },
            );
        }
    }

    // --- Clear main buffer ---
    y = 0;
    while (y < state.main_win.h) : (y += 1) {
        x = 0;
        while (x < state.main_win.w) : (x += 1) {
            state.backend.draw(
                .{ .col = state.main_win.x + x, .row = state.main_win.y + y },
                .{
                    .background = Color.Black,
                    .content = .{ .Text = ' ' },
                },
            );
        }
    }

    // --- Draw main buffer lines and line numbers ---
    // const relative_nums = true;
    const row_render_start = std.math.sub(usize, buffer.row, state.main_win.h) catch 0;
    // const col_render_start = 0;

    var renderRow: usize = row_render_start;
    while (renderRow < buffer.lines.items.len and renderRow < row_render_start + state.main_win.h) : (renderRow += 1) {
        const line = buffer.lines.items[renderRow];
        const bufdata = line.data.items;

        // Draw line contents
        for (bufdata, 0..) |ch, c| {
            state.backend.draw(
                .{ .col = state.main_win.x + 1 + c, .row = @as(usize, @intCast(state.main_win.y)) + renderRow - row_render_start },
                .{
                    .foreground = if (ch == ' ') Color.Cyan else Color.DarkBlue,
                    .background = Color.Black,
                    .content = .{ .Text = if (ch == ' ') '-' else ch },
                },
            );
        }

        // Draw line numbers
        // if (renderRow - row_render_start < state.line_num_win.h) {
        //     const lineNumber = if (relative_nums) blk: {
        //         const res = if (realRow > renderRow)
        //             realRow - renderRow
        //         else if (realRow == renderRow)
        //             renderRow + 1
        //         else
        //             renderRow - realRow;
        //         if (res == 0) break :blk renderRow + 1;
        //         break :blk res;
        //     } else blk: {
        //         break :blk renderRow + 1;
        //     };

        //     var buf: [8]u8 = undefined;
        //     const data = try std.fmt.bufPrint(&buf, "{}", .{lineNumber});
        //     for (c2, ch) in data {
        //         state.backend.draw(
        //             .{ .col = state.line_num_win.x + c2, .row = state.line_num_win.y + @intCast(renderRow - row_render_start) },
        //             .{
        //                 .foreground = Color.Yellow,
        //                 .background = Color.Black,
        //                 .content = .{ .Text = ch },
        //             },
        //         );
        //     }
        //     // Fill remaining sidebar with spaces
        //     for (c2: usize = data.len; c2 < state.line_num_win.w; c2 += 1) {
        //         state.backend.draw(
        //             .{ .col = state.line_num_win.x + c2, .row = state.line_num_win.y + @intCast(renderRow - row_render_start) },
        //             .{
        //                 .background = Color.Black,
        //                 .content = .{ .Text = ' ' },
        //             },
        //         );
        //     }
        // }
    }

    // --- Visual selection highlight ---
    if (buffer.target) |visual| {
        var cur = visual.start;
        const end = visual.end;
        while (true) {
            if (cur.row > end.row) break;
            if (cur.row == end.row and cur.col >= end.col) break;

            state.backend.draw(
                .{ .col = @as(usize, @intCast(state.main_win.x)) + 1 + cur.col, .row = @as(usize, @intCast(state.main_win.y)) + cur.row - row_render_start },
                .{
                    .background = Color.Reset,
                    .content = .{ .Text = buffer.lines.items[cur.row].data.items[cur.col] },
                },
            );

            cur = buffer.moveRight(cur, 1);
        }
    }

    // --- Cursor movement (handled by backend, not here) ---
    // try trm.setCursorStyle(...);

    state.resized = false;
}
