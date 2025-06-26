const std = @import("std");
const root = @import("../main.zig");
const trm = root.trm;
const lib = root.lib;

const State = root.State;
const Backend = State.Backend;
const Node = Backend.Node;
const Color = Backend.Color;
const Component = @import("Component.zig");
const View = Component.View;

const StatusBar = @import("components/StatusBar.zig");
const LineNumbers = @import("components/LineNumbers.zig");
const MainEditor = @import("components/MainEditor.zig");
const CommandLine = @import("components/CommandLine.zig");

pub const sidebarWidth = 3;
pub const statusbarHeight = 2;

const id = struct {
    var static: usize = 0;
    pub fn next() usize {
        static += 1;
        return static;
    }
};

pub fn init(state: *State) !void {
    const rootView = View{
        .x = 0,
        .y = 0,
        // .w = state.backend.getWidth(),
        // .h = state.backend.getHeight(),
        .w = 80, // TODO
        .h = 24,
    };

    {
        const statusBarView = View{
            .x = 0,
            .y = rootView.h - statusbarHeight,
            .w = rootView.w,
            .h = statusbarHeight,
        };
        const statusBar = Component{
            .dataptr = undefined,
            .vtable = &.{
                .renderFn = StatusBar.render,
            },
        };
        try state.components.put(state.a, id.next(), .{ .comp = statusBar, .view = statusBarView });
    }

    {
        const lineNumbersView = View{
            .x = 0,
            .y = 0,
            .w = sidebarWidth,
            .h = rootView.h - statusbarHeight,
        };
        const lineNumbers = Component{
            .dataptr = undefined,
            .vtable = &.{
                .renderFn = LineNumbers.render,
            },
        };
        try state.components.put(state.a, id.next(), .{ .comp = lineNumbers, .view = lineNumbersView });
    }

    {
        const mainView = View{
            .x = sidebarWidth,
            .y = 0,
            .w = rootView.w - sidebarWidth,
            .h = rootView.h - statusbarHeight,
        };
        const mainEditor = Component{
            .dataptr = undefined,
            .vtable = &.{
                .renderFn = MainEditor.render,
            },
        };
        try state.components.put(state.a, id.next(), .{ .comp = mainEditor, .view = mainView });
    }

    {
        const commandView = View{
            .x = 0,
            .y = rootView.h - 1, // Bottom line of status bar
            .w = rootView.w,
            .h = 1,
        };
        const commandLine = Component{
            .dataptr = undefined,
            .vtable = &.{
                .renderFn = CommandLine.render,
            },
        };
        try state.components.put(state.a, id.next(), .{ .comp = commandLine, .view = commandView });
    }

    // if (state.command.is) {
    //     const cmdPos = 1 + state.command.buffer.items.len; // After the colon and command text
    //     try trm.setCursorPos(cmdPos, state.backend.getHeight() - 1);
    //     return;
    // }

    // const buffer = state.getCurrentBuffer() orelse return;

    // const row_render_start = std.math.sub(usize, buffer.row, rootView.h - statusbarHeight) catch 0;
    // const viewportRow = buffer.row - row_render_start;
    // const cursorCol = sidebarWidth + buffer.col + 1;
    // try trm.setCursorPos(cursorCol, viewportRow);
}

// pub fn draw(state: *State) !void {
//     state.backend.render(.begin);
//     defer state.backend.render(.end);

//     // Example: draw a single cell at (3,3)
//     state.backend.draw(
//         .{ .col = 3, .row = 3 },
//         .{
//             .background = Color.Black,
//             .content = .{ .Text = 'o' },
//         },
//     );

//     // --- Layout calculations ---
//     // (Assume state.resized and window management is handled elsewhere)

//     // --- Clear status bar ---
//     var y: u16 = 0;
//     var x: u16 = 0;
//     while (y < state.status_bar.h) : (y += 1) {
//         x = 0;
//         while (x < state.status_bar.w) : (x += 1) {
//             state.backend.draw(
//                 .{ .col = x, .row = state.status_bar.y + y },
//                 .{
//                     .background = Color.Black,
//                     .content = .{ .Text = ' ' },
//                 },
//             );
//         }
//     }

//     // --- Draw command line if active ---
//     if (state.command.is) {
//         const command = try std.fmt.allocPrint(state.a, ":{s}", .{state.command.buffer.items});
//         defer state.a.free(command);

//         for (command, 0..) |ch, i| {
//             state.backend.draw(
//                 .{ .col = i, .row = state.status_bar.y + 1 },
//                 .{
//                     .background = Color.Black,
//                     .foreground = Color.White,
//                     .content = .{ .Text = ch },
//                 },
//             );
//         }
//         // Cursor movement is backend-specific, not handled here.
//     }

//     const buffer = state.getCurrentBuffer() orelse return;
//     // const realRow = buffer.row;

//     // --- Status bar message ---
//     if (state.status_bar_msg) |print_msg| {
//         for (print_msg, 0..) |ch, i| {
//             state.backend.draw(
//                 .{ .col = i, .row = state.status_bar.y + 1 },
//                 .{
//                     .background = Color.Black,
//                     .foreground = Color.White,
//                     .content = .{ .Text = ch },
//                 },
//             );
//         }
//         state.status_bar_msg = null;
//     }

//     // --- Status bar: position ---
//     {
//         const position = try std.fmt.allocPrint(state.a, "{}:{}", .{ buffer.row + 1, buffer.col + 1 });
//         defer state.a.free(position);
//         const x2 = state.status_bar.w - position.len;
//         for (position, 0..) |ch, i| {
//             state.backend.draw(
//                 .{ .col = x2 + i, .row = state.status_bar.y + 0 },
//                 .{
//                     .background = Color.Black,
//                     .foreground = Color.White,
//                     .content = .{ .Text = ch },
//                 },
//             );
//         }
//     }

//     // --- Status bar: mode ---
//     {
//         const mode = state.buffer.mode.toString();
//         for (mode, 0..) |ch, i| {
//             state.backend.draw(
//                 .{ .col = i, .row = state.status_bar.y + 0 },
//                 .{
//                     .background = Color.Black,
//                     .foreground = Color.Yellow,
//                     .content = .{ .Text = ch },
//                 },
//             );
//         }
//     }

//     // --- Clear main buffer ---
//     y = 0;
//     while (y < state.main_win.h) : (y += 1) {
//         x = 0;
//         while (x < state.main_win.w) : (x += 1) {
//             state.backend.draw(
//                 .{ .col = state.main_win.x + x, .row = state.main_win.y + y },
//                 .{
//                     .background = Color.Black,
//                     .content = .{ .Text = ' ' },
//                 },
//             );
//         }
//     }

//     // --- Draw main buffer lines and line numbers ---
//     // const relative_nums = true;
//     const row_render_start = std.math.sub(usize, buffer.row, state.main_win.h) catch 0;
//     // const col_render_start = 0;

//     var renderRow: usize = row_render_start;
//     while (renderRow < buffer.lines.items.len and renderRow < row_render_start + state.main_win.h) : (renderRow += 1) {
//         const line = buffer.lines.items[renderRow];
//         const bufdata = line.data.items;

//         // Draw line contents
//         for (bufdata, 0..) |ch, c| {
//             state.backend.draw(
//                 .{ .col = state.main_win.x + 1 + c, .row = @as(usize, @intCast(state.main_win.y)) + renderRow - row_render_start },
//                 .{
//                     .foreground = if (ch == ' ') Color.Cyan else Color.DarkBlue,
//                     .background = Color.Black,
//                     .content = .{ .Text = if (ch == ' ') '-' else ch },
//                 },
//             );
//         }

//         // Draw line numbers
//         // if (renderRow - row_render_start < state.line_num_win.h) {
//         //     const lineNumber = if (relative_nums) blk: {
//         //         const res = if (realRow > renderRow)
//         //             realRow - renderRow
//         //         else if (realRow == renderRow)
//         //             renderRow + 1
//         //         else
//         //             renderRow - realRow;
//         //         if (res == 0) break :blk renderRow + 1;
//         //         break :blk res;
//         //     } else blk: {
//         //         break :blk renderRow + 1;
//         //     };

//         //     var buf: [8]u8 = undefined;
//         //     const data = try std.fmt.bufPrint(&buf, "{}", .{lineNumber});
//         //     for (c2, ch) in data {
//         //         state.backend.draw(
//         //             .{ .col = state.line_num_win.x + c2, .row = state.line_num_win.y + @intCast(renderRow - row_render_start) },
//         //             .{
//         //                 .foreground = Color.Yellow,
//         //                 .background = Color.Black,
//         //                 .content = .{ .Text = ch },
//         //             },
//         //         );
//         //     }
//         //     // Fill remaining sidebar with spaces
//         //     for (c2: usize = data.len; c2 < state.line_num_win.w; c2 += 1) {
//         //         state.backend.draw(
//         //             .{ .col = state.line_num_win.x + c2, .row = state.line_num_win.y + @intCast(renderRow - row_render_start) },
//         //             .{
//         //                 .background = Color.Black,
//         //                 .content = .{ .Text = ' ' },
//         //             },
//         //         );
//         //     }
//         // }
//     }

//     // --- Visual selection highlight ---
//     if (buffer.target) |visual| {
//         var cur = visual.start;
//         const end = visual.end;
//         while (true) {
//             if (cur.row > end.row) break;
//             if (cur.row == end.row and cur.col >= end.col) break;

//             state.backend.draw(
//                 .{ .col = @as(usize, @intCast(state.main_win.x)) + 1 + cur.col, .row = @as(usize, @intCast(state.main_win.y)) + cur.row - row_render_start },
//                 .{
//                     .background = Color.Reset,
//                     .content = .{ .Text = buffer.lines.items[cur.row].data.items[cur.col] },
//                 },
//             );
//             cur = buffer.moveRight(cur, 1);
//         }
//     }
//     // --- Cursor movement (handled by backend, not here) ---
//     // try trm.setCursorStyle(...);
//     state.resized = false;
// }

pub fn draw(state: *State) !void {
    state.backend.render(.begin);
    defer state.backend.render(.end);

    var iter = state.components.iterator();
    while (iter.next()) |v| {
        const comp = v.value_ptr.comp;
        const view = v.value_ptr.view;

        if (view.w == 0 or view.h == 0) continue; // Skip empty components

        comp.vtable.renderFn(comp.dataptr, state, &state.backend, view);
    }

    state.resized = false;
}
