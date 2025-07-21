const root = @import("../root.zig");
const std = root.std;
const scu = root.scu;
const trm = root.trm;
const lib = root.lib;
// const rc = root.rc;
const lua = root.lua;
const km = root.km;
const State = root.State;
const Buffer = root.Buffer;

const ModeId = km.ModeId;

const norm = trm.keys.norm;
const ctrl = trm.keys.ctrl;

pub const command = @import("command.zig");
pub const normal = @import("normal.zig");

const Ks = trm.KeySymbol;

/// TODO: I dont think this needs an arena
pub fn init(
    a: std.mem.Allocator,
    modes: *km.Keymap,
) !void {
    var insert = modes.appender(km.ModeId.Insert);
    insert.targeter(km.KeyFunction.initstate(actions.move));
    insert.fallback(km.KeyFunction.initstate(insertsfn.append));

    var visual = modes.appender(km.ModeId.Visual);
    visual.targeter(km.KeyFunction.initstate(actions.move));

    // insert
    try initInsertKeys(a, &insert);
    try insert.put(a, norm(Ks.Esc.toBits()), km.KeyFunction.initsetmod(ModeId.Normal));

    // normal
    try normal.init(a, modes);

    // visual
    try normal.initMotionKeys(a, &visual);
    try visual.put(a, norm(Ks.Esc.toBits()), km.KeyFunction.initsetmod(ModeId.Normal));
    try visual.put(a, norm('d'), km.KeyFunction.initstate(actions.deletelines));

    // command
    try command.init(a, modes);
}

fn deleteBufferCharacter(state: *State, _: km.KeyFunctionDataValue) !void {
    const buffer = state.getCurrentBuffer();
    try buffer.bufferDelete(state.a);
}

fn insertTab(buffer: *Buffer, _: km.KeyFunctionDataValue) !void {
    for (0..4) |_| try buffer.insertCharacter(' ');
}

fn initInsertKeys(a: std.mem.Allocator, insert: *km.Keymap.Appender) !void {
    try insert.put(a, norm(Ks.Backspace.toBits()), km.KeyFunction.initstate(deleteBufferCharacter));

    try insert.put(a, norm(Ks.Tab.toBits()), km.KeyFunction.initbuffer(insertTab));

    // try insert.put(a, ctrl('s'), km.KeyFunction.initstate({
    //     handle_save(buffer);
    //     state.*.config.QUIT = 1;
    // } });

    // ctrl-c
    // @as(c_int, 260) => {
    //      handle_move_left(state, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    // },
    // @as(c_int, 258) => {
    //      handle_move_down(state, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    // },
    // @as(c_int, 259) => {
    //      handle_move_up(state, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    // },
    // @as(c_int, 261) => {
    //      handle_move_right(state, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    // },
    // @as(c_int, 410) => {
    //      frontend_resize_window(state);
    // },

    // @as(term.KeyCharacter, @enumFromInt(@as(u8, '\t')))
    // @as(c_int, 9) => {
    //     if (state.*.config.indent > @as(c_int, 0)) {
    //             var i: usize = 0;
    //             while (@as(c_int, @bitCast(@as(c_uint, @truncate(i)))) < state.*.config.indent) : (i +%= 1) {
    //                 buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ' '))))));
    //             }
    //     } else {
    //         buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\t'))))));
    //     }
    //     break;
    // },
    // @as(c_int, 343), @as(c_int, 10) => {
    //     {
    //         state.*.cur_undo.end = buffer.*.cursor;
    //         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //         var brace: Brace = find_opposite_brace(buffer.*.data.data[buffer.*.cursor]);
    //         _ = &brace;
    //         while (true) {
    //             var undo: Undo = Undo{
    //                 .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //                 .data = @import("std").mem.zeroes(Data),
    //                 .start = @import("std").mem.zeroes(usize),
    //                 .end = @import("std").mem.zeroes(usize),
    //             };
    //             _ = &undo;
    //             undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
    //             undo.start = buffer.*.cursor;
    //             state.*.cur_undo = undo;
    //             if (!false) break;
    //         }
    //         buffer_newline_indent(buffer, state);
    //         state.*.cur_undo.end = buffer.*.cursor;
    //         if ((@as(c_int, @bitCast(@as(c_uint, brace.brace))) != @as(c_int, '0')) and (brace.closing != 0)) {
    //             buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\n'))))));
    //             if (state.*.num_of_braces == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
    //                 state.*.num_of_braces = 1;
    //             }
    //             if (state.*.config.indent > @as(c_int, 0)) {
    //                 {
    //                     var i: usize = 0;
    //                     _ = &i;
    //                     while (i < (@as(usize, @bitCast(@as(c_long, state.*.config.indent))) *% (state.*.num_of_braces -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))))) : (i +%= 1) {
    //                         buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ' '))))));
    //                     }
    //                 }
    //                 handle_move_left(state, @as(usize, @bitCast(@as(c_long, state.*.config.indent))) *% (state.*.num_of_braces -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))));
    //             } else {
    //                 {
    //                     var i: usize = 0;
    //                     _ = &i;
    //                     while (i < (state.*.num_of_braces -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))))) : (i +%= 1) {
    //                         buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\t'))))));
    //                     }
    //                 }
    //                 handle_move_left(state, state.*.num_of_braces -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    //             }
    //             handle_move_left(state, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    //         } else {
    //             undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //             while (true) {
    //                 var undo: Undo = Undo{
    //                     .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //                     .data = @import("std").mem.zeroes(Data),
    //                     .start = @import("std").mem.zeroes(usize),
    //                     .end = @import("std").mem.zeroes(usize),
    //                 };
    //                 _ = &undo;
    //                 undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
    //                 undo.start = buffer.*.cursor;
    //                 state.*.cur_undo = undo;
    //                 if (!false) break;
    //             }
    //         }
    //     }
    //     break;
    // },
    // else => {
    // while (true) {
    //     if (!(buffer.*.data.count >= buffer.*.cursor)) {
    //         frontend_end();
    //         _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/keys.c", @as(c_int, 613));
    //         _ = fprintf(stderr, "check");
    //         _ = fprintf(stderr, "\n");
    //         exit(@as(c_int, 1));
    //     }
    //     if (!false) break;
    // }
    // var brace: Brace = Brace{
    //     .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
    //     .closing = 0,
    // };
    // _ = &brace;
    // var cur_brace: Brace = Brace{
    //     .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
    //     .closing = 0,
    // };
    // _ = &cur_brace;
    // if (buffer.*.cursor == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
    //     cur_brace = find_opposite_brace(buffer.*.data.data[@as(c_uint, @intCast(@as(c_int, 0)))]);
    // } else {
    //     cur_brace = find_opposite_brace(buffer.*.data.data[buffer.*.cursor]);
    // }
    // if (((@as(c_int, @bitCast(@as(c_uint, cur_brace.brace))) != @as(c_int, '0')) and (cur_brace.closing != 0)) and (state.*.ch == @as(c_int, @bitCast(@as(c_uint, find_opposite_brace(cur_brace.brace).brace))))) {
    //     buffer.*.cursor +%= 1;
    //     break;
    // }
    // brace = find_opposite_brace(@as(u8, @bitCast(@as(i8, @truncate(state.*.ch)))));

    // try Buffer.buffer_insert_char(state, buffer, state.ch.character.b());

    // if ((@as(c_int, @bitCast(@as(c_uint, brace.brace))) != @as(c_int, '0')) and !(brace.closing != 0)) {
    //     state.*.cur_undo.end -%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    //     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //     while (true) {
    //         var undo: Undo = Undo{
    //             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //             .data = @import("std").mem.zeroes(Data),
    //             .start = @import("std").mem.zeroes(usize),
    //             .end = @import("std").mem.zeroes(usize),
    //         };
    //         _ = &undo;
    //         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
    //         undo.start = buffer.*.cursor -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    //         state.*.cur_undo = undo;
    //         if (!false) break;
    //     }
    //     buffer_insert_char(state, buffer, brace.brace);
    //     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //     while (true) {
    //         var undo: Undo = Undo{
    //             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //             .data = @import("std").mem.zeroes(Data),
    //             .start = @import("std").mem.zeroes(usize),
    //             .end = @import("std").mem.zeroes(usize),
    //         };
    //         _ = &undo;
    //         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
    //         undo.start = buffer.*.cursor;
    //         state.*.cur_undo = undo;
    //         if (!false) break;
    //     }
    //     handle_move_left(state, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    //     while (true) {
    //         var undo: Undo = Undo{
    //             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //             .data = @import("std").mem.zeroes(Data),
    //             .start = @import("std").mem.zeroes(usize),
    //             .end = @import("std").mem.zeroes(usize),
    //         };
    //         _ = &undo;
    //         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
    //         undo.start = buffer.*.cursor;
    //         state.*.cur_undo = undo;
    //         if (!false) break;
    //     }
    // }
    // },
    // }
}

pub fn initVisualKeys() !void {
    // @as(c_int, 3), @as(c_int, 27) => {
    //     {
    //         state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //         frontend_cursor_visible(@as(c_int, 1));
    //         state.*.buffer.*.visual = Visual{
    //             .start = @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))),
    //             .end = @import("std").mem.zeroes(usize),
    //             .is_line = 0,
    //         };
    //     }
    //     break;
    // },
    // @as(c_int, 10) => break,
    // @as(c_int, 19) => {
    //     {
    //         handle_save(buffer);
    //         state.*.config.QUIT = 1;
    //     }
    //     break;
    // },
    // @as(c_int, 100), @as(c_int, 120) => {
    //     {
    //         var cond: c_int = @intFromBool(buffer.*.visual.start > buffer.*.visual.end);
    //         _ = &cond;
    //         var start: usize = if (cond != 0) buffer.*.visual.end else buffer.*.visual.start;
    //         _ = &start;
    //         var end: usize = if (cond != 0) buffer.*.visual.start else buffer.*.visual.end;
    //         _ = &end;
    //         while (true) {
    //             var undo: Undo = Undo{
    //                 .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //                 .data = @import("std").mem.zeroes(Data),
    //                 .start = @import("std").mem.zeroes(usize),
    //                 .end = @import("std").mem.zeroes(usize),
    //             };
    //             _ = &undo;
    //             undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
    //             undo.start = start;
    //             state.*.cur_undo = undo;
    //             if (!false) break;
    //         }
    //         buffer_delete_selection(buffer, state, start, end);
    //         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //         state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //         frontend_cursor_visible(@as(c_int, 1));
    //     }
    //     break;
    // },
    // @as(c_int, 62) => {
    //     {
    //         var cond: c_int = @intFromBool(buffer.*.visual.start > buffer.*.visual.end);
    //         _ = &cond;
    //         var start: usize = if (cond != 0) buffer.*.visual.end else buffer.*.visual.start;
    //         _ = &start;
    //         var end: usize = if (cond != 0) buffer.*.visual.start else buffer.*.visual.end;
    //         _ = &end;
    //         var position: usize = buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, state.*.config.indent)));
    //         _ = &position;
    //         var row: usize = index_get_row(buffer, start);
    //         _ = &row;
    //         var end_row: usize = index_get_row(buffer, end);
    //         _ = &end_row;
    //         {
    //             var i: usize = row;
    //             _ = &i;
    //             while (i <= end_row) : (i +%= 1) {
    //                 buffer_calculate_rows(buffer);
    //                 buffer.*.cursor = buffer.*.rows.data[i].start;
    //                 if (state.*.config.indent > @as(c_int, 0)) {
    //                     {
    //                         var i_1: usize = 0;
    //                         _ = &i_1;
    //                         while (@as(c_int, @bitCast(@as(c_uint, @truncate(i_1)))) < state.*.config.indent) : (i_1 +%= 1) {
    //                             buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ' '))))));
    //                         }
    //                     }
    //                 } else {
    //                     buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\t'))))));
    //                 }
    //             }
    //         }
    //         buffer.*.cursor = position;
    //         state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //         frontend_cursor_visible(@as(c_int, 1));
    //     }
    //     break;
    // },
    // @as(c_int, 60) => {
    //     {
    //         var cond: c_int = @intFromBool(buffer.*.visual.start > buffer.*.visual.end);
    //         _ = &cond;
    //         var start: usize = if (cond != 0) buffer.*.visual.end else buffer.*.visual.start;
    //         _ = &start;
    //         var end: usize = if (cond != 0) buffer.*.visual.start else buffer.*.visual.end;
    //         _ = &end;
    //         var row: usize = index_get_row(buffer, start);
    //         _ = &row;
    //         var end_row: usize = index_get_row(buffer, end);
    //         _ = &end_row;
    //         var offset: usize = 0;
    //         _ = &offset;
    //         {
    //             var i: usize = row;
    //             _ = &i;
    //             while (i <= end_row) : (i +%= 1) {
    //                 buffer_calculate_rows(buffer);
    //                 buffer.*.cursor = buffer.*.rows.data[i].start;
    //                 if (state.*.config.indent > @as(c_int, 0)) {
    //                     {
    //                         var j: usize = 0;
    //                         _ = &j;
    //                         while (@as(c_int, @bitCast(@as(c_uint, @truncate(j)))) < state.*.config.indent) : (j +%= 1) {
    //                             if ((@as(c_int, @bitCast(@as(c_uint, (blk: {
    //                                 const tmp = @as(c_int, @bitCast(@as(c_uint, buffer.*.data.data[buffer.*.cursor])));
    //                                 if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    //                             }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISspace)))))))) != 0) {
    //                                 buffer_delete_char(buffer, state);
    //                                 offset +%= 1;
    //                                 buffer_calculate_rows(buffer);
    //                             }
    //                         }
    //                     }
    //                 } else {
    //                     if ((@as(c_int, @bitCast(@as(c_uint, (blk: {
    //                         const tmp = @as(c_int, @bitCast(@as(c_uint, buffer.*.data.data[buffer.*.cursor])));
    //                         if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    //                     }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISspace)))))))) != 0) {
    //                         buffer_delete_char(buffer, state);
    //                         offset +%= 1;
    //                         buffer_calculate_rows(buffer);
    //                     }
    //                 }
    //             }
    //         }
    //         state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //         frontend_cursor_visible(@as(c_int, 1));
    //     }
    //     break;
    // },
    // @as(c_int, 121) => {
    //     {
    //         reset_command(state.*.clipboard.str, &state.*.clipboard.len);
    //         var cond: c_int = @intFromBool(buffer.*.visual.start > buffer.*.visual.end);
    //         _ = &cond;
    //         var start: usize = if (cond != 0) buffer.*.visual.end else buffer.*.visual.start;
    //         _ = &start;
    //         var end: usize = if (cond != 0) buffer.*.visual.start else buffer.*.visual.end;
    //         _ = &end;
    //         buffer_yank_selection(buffer, state, start, end);
    //         buffer.*.cursor = start;
    //         state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //         frontend_cursor_visible(@as(c_int, 1));
    //         break;
    //     }
    // },
    // else => {
    //     {
    //         if (buffer.*.visual.is_line != 0) {
    //             buffer.*.visual.end = buffer.*.rows.data[buffer_get_row(buffer)].end;
    //             if (buffer.*.visual.start >= buffer.*.visual.end) {
    //                 buffer.*.visual.end = buffer.*.rows.data[buffer_get_row(buffer)].start;
    //                 buffer.*.visual.start = buffer.*.rows.data[index_get_row(buffer, buffer.*.visual.start)].end;
    //             }
    //         } else {
    //             buffer.*.visual.end = buffer.*.cursor;
    //         }
    //     }
    //     break;
    // },
}

// ----------------------------------------------------------------------------

// pub fn replace(arg_buffer: *Buffer, arg_state: *State, _: km.KeyFunctionDataValue, arg_new_str: *u8, arg_old_str_s: usize, arg_new_str_s: usize) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     var new_str = arg_new_str;
//     _ = &new_str;
//     var old_str_s = arg_old_str_s;
//     _ = &old_str_s;
//     var new_str_s = arg_new_str_s;
//     _ = &new_str_s;
//     if ((buffer == @as(*Buffer, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) or (new_str == @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//         while (true) {
//             var file: *FILE = fopen("logs/cano.log", "a");
//             _ = &file;
//             if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
//                 _ = fprintf(file, "%s:%d: Error: null pointer\n", "src/keys.c", @as(c_int, 17));
//                 _ = fclose(file);
//             }
//             if (!false) break;
//         }
//         return;
//     }
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < old_str_s) : (i +%= 1) {
//             buffer_delete_char(buffer, state);
//         }
//     }
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < new_str_s) : (i +%= 1) {
//             buffer_insert_char(state, buffer, new_str[i]);
//         }
//     }
// }

// const ctrl_keys: [26]struct {} = blk: {
//     var buf: [26]struct {} = undefined;
//
//     for (0..26) |i| {
//         const ch = i + 'a' - 1;
//         const fmt = std.fmt.comptimePrint("<ctrl-{}>", .{ch});
//         buf[i] = .{
//             .name = fmt,
//             .value = scu.thermit.keys.ctrl(ch),
//         };
//     }
//
//     break :blk buf;
// };

/// A collection of functions that act on a target.
pub const actions = struct {
    fn yeank(buffer: *Buffer, _: km.KeyFunctionDataValue) !void {
        if (buffer.target) |target| {
            _ = target;
            // TODO: implement
        }
    }

    pub fn move(state: *State, ctx: km.KeyFunctionDataValue) !void {
        try moveKeep(state, ctx);

        const buffer = state.getCurrentBuffer();
        buffer.target = null; // reset the target
    }

    pub fn moveKeep(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        if (buffer.target) |target| {
            // std.debug.print("moveKeep: target: {any}\n", .{target});

            buffer.row = target.end.row;
            buffer.col = target.end.col;

            // only go back if we expend something
            buffer.input_state.len = 0;
        }
    }

    pub fn none(_: *State) !void {}

    // Deletes text only using the target as a guide for lines
    pub fn deletelines(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        root.log(@src(), .debug, "delete motion", .{});

        if (buffer.target) |target| {
            // TODO: checking
            std.debug.assert(target.start.row <= target.end.row);
            for (buffer.lines.items[target.start.row..target.end.row]) |*line| {
                line.deinit(state.a);
            }
            try buffer.lines.replaceRange(state.a, target.start.row, target.end.row - target.start.row, &.{});
        }
        buffer.target = null;
        buffer.setMode(ModeId.Normal);
    }
};

const insertsfn = struct {
    fn append(s: *State, _: km.KeyFunctionDataValue) !void {
        if (s.ch.modifiers.bits() == 0) {
            const buf = s.getCurrentBuffer();
            try buf.insertCharacter(s.ch.character);
        }
    }
};
