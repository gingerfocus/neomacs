const defs = @import("defs.zig");
const tools = @import("tools.zig");
const Buffer = @import("Buffer.zig");

const root = @import("root");
const std = @import("std");
const scu = @import("scured");
const trm = scu.thermit;

const Row = defs.Row;
const Rows = defs.Rows;
const Data = defs.Data;
// const String_View = defs.String_View;
// const Visual = defs.Visual;
// const Undo = defs.Undo;
// const Brace = defs.Brace;
const State = @import("State.zig");

pub fn initKeyMaps(state: *State) !void {
    const normal = &state.keyMaps[@intFromEnum(State.Mode.NORMAL)];
    const visual = &state.keyMaps[@intFromEnum(State.Mode.VISUAL)];
    const insert = &state.keyMaps[@intFromEnum(State.Mode.INSERT)];

    // insert
    try initInsertKeys(state.a, &insert.keys);
    insert.fallback = .{ .Native = insertCharacter };

    // normal
    try initToInsertKeys(state.a, &normal.keys);
    try initMotionKeys(state.a, &normal.keys);

    // normal
    try initMotionKeys(state.a, &visual.keys);
}

fn insertCharacter(state: *State) !void {
    if (@as(u8, @bitCast(state.ch.modifiers)) == 0) {
        try Buffer.buffer_insert_char(state, state.buffer, state.ch.character.b());
    }
}

const norm = scu.thermit.keys.norm;

pub fn initMotionKeys(a: std.mem.Allocator, mode: *State.KeyMapings) !void {
    try mode.put(a, norm(.j), .{ .Native = motion_j });
    try mode.put(a, norm(.k), .{ .Native = motion_k });

    // try mode.put(a, norm(.g), .{ .Native = motion_g });
    // motion_G(state);
    // motion_0(state);
    try mode.put(a, '$', .{ .Native = @"motion_$" });
    // motion_e(state);
    // motion_b(state);
    // motion_w(state);

    //  @as(c_int, 260), @as(c_int, 104) => {
    //      buffer_move_left(buffer);
    //  },
    //  @as(c_int, 258), @as(c_int, 106) => {
    //      buffer_move_down(buffer);
    //  },
    //  @as(c_int, 259), @as(c_int, 107) => {
    //      buffer_move_up(buffer);
    //  },
    //  @as(c_int, 261), @as(c_int, 108) => {
    //      buffer_move_right(buffer);
    //  },
    //  @as(c_int, 37) => {
    //          buffer_next_brace(buffer);
    //  },
}

// pub fn handle_motion_keys(arg_buffer: *Buffer, arg_state: *State, arg_ch: c_int, arg_repeating_count: *usize) c_int {

// pub fn handle_modifying_keys(arg_buffer: *Buffer, arg_state: *State) c_int {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     while (true) {
//         switch (state.*.ch) {
//             @as(c_int, 120) => {
//                 {
//                     buffer_delete_ch(buffer, state);
//                 }
//                 break;
//             },
//             @as(c_int, 100) => {
//                 {
//                     while (true) {
//                         switch (state.*.leader) {
//                             @as(c_uint, @bitCast(@as(c_int, 2))) => {
//                                 {
//                                     buffer_delete_row(buffer, state);
//                                 }
//                                 break;
//                             },
//                             else => break,
//                         }
//                         break;
//                     }
//                 }
//                 break;
//             },
//             @as(c_int, 114) => {
//                 {
//                     buffer_replace_ch(buffer, state);
//                 }
//                 break;
//             },
//             else => {
//                 {
//                     return 0;
//                 }
//             },
//         }
//         break;
//     }
//     return 1;
// }

pub fn initToInsertKeys(a: std.mem.Allocator, normal: *State.KeyMapings) !void {
    // var undo: Undo = Undo{
    //     .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //     .data = @import("std").mem.zeroes(Data),
    //     .start = @import("std").mem.zeroes(usize),
    //     .end = @import("std").mem.zeroes(usize),
    // };
    // undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
    // undo.start = buffer.*.cursor;
    // state.*.cur_undo = undo;

    try normal.put(a, norm(.i), .{ .Native = normal_i });
    // norm(.I) => {
    //     const row = buffer.row; // Buffer.bufferGetRow(buffer);
    //     const cur = buffer.rows.items[row];
    //     buffer.cursor = cur.start;
    //     // TODO: check for other white space, make an isspace function from ncurses
    //     while (buffer.cursor < cur.end and buffer.data.items[buffer.cursor] == ' ') buffer.cursor += 1;
    //     state.config.mode = .INSERT;
    // },
    //             @as(c_int, 97) => {
    //                 if (buffer.*.cursor < buffer.*.data.count) {
    //                     buffer.*.cursor +%= 1;
    //                 }
    //                 state.*.config.mode = @as(c_uint, @bitCast(INSERT));
    //                 break;
    //             },
    //             @as(c_int, 65) => {
    //                 {
    //                     var row: usize = buffer_get_row(buffer);
    //                     _ = &row;
    //                     var end: usize = buffer.*.rows.data[row].end;
    //                     _ = &end;
    //                     buffer.*.cursor = end;
    //                     state.*.config.mode = @as(c_uint, @bitCast(INSERT));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, 111) => {
    //                 {
    //                     while (true) {
    //                         var undo: Undo = Undo{
    //                             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //                             .data = @import("std").mem.zeroes(Data),
    //                             .start = @import("std").mem.zeroes(usize),
    //                             .end = @import("std").mem.zeroes(usize),
    //                         };
    //                         _ = &undo;
    //                         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
    //                         undo.start = buffer.*.cursor;
    //                         state.*.cur_undo = undo;
    //                         if (!false) break;
    //                     }
    //                     var row: usize = buffer_get_row(buffer);
    //                     _ = &row;
    //                     var end: usize = buffer.*.rows.data[row].end;
    //                     _ = &end;
    //                     buffer.*.cursor = end;
    //                     buffer_newline_indent(buffer, state);
    //                     state.*.config.mode = @as(c_uint, @bitCast(INSERT));
    //                     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, 79) => {
    //                 {
    //                     while (true) {
    //                         var undo: Undo = Undo{
    //                             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //                             .data = @import("std").mem.zeroes(Data),
    //                             .start = @import("std").mem.zeroes(usize),
    //                             .end = @import("std").mem.zeroes(usize),
    //                         };
    //                         _ = &undo;
    //                         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
    //                         undo.start = buffer.*.cursor;
    //                         state.*.cur_undo = undo;
    //                         if (!false) break;
    //                     }
    //                     var row: usize = buffer_get_row(buffer);
    //                     _ = &row;
    //                     var start: usize = buffer.*.rows.data[row].start;
    //                     _ = &start;
    //                     buffer.*.cursor = start;
    //                     buffer_newline_indent(buffer, state);
    //                     state.*.config.mode = @as(c_uint, @bitCast(INSERT));
    //                     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //                 }
    //                 break;
    //             },
}

fn normal_i(state: *State) anyerror!void {
    state.config.mode = .INSERT;
    // state.repeating.repeating_count = 0;
    // if (state.*.repeating.repeating_count != 0) {
    //     state.*.ch = frontend_getch(state.*.main_win);
    // }
}

fn isdigit(ch: trm.KeyEvent) bool {
    if (@as(u8, @bitCast(ch.modifiers)) != 0) return false;
    return std.ascii.isDigit(ch.character.b());
}

pub fn handleNormalKeys(buffer: *Buffer, state: *State) anyerror!void {
    _ = buffer; // autofix
    // if (tools.check_keymaps(buffer, state)) return;

    if (state.leader == .NONE) {
        if (handleLeaderKeys(state)) return;
    } else if (state.ch.character == .Esc) {
        state.leader = .NONE;
    }

    // if (isdigit(state.ch) and
    //     !(state.ch.character.b() == '0' and state.num.items.len == 0))
    // {
    //     // std.log.info("adding number!\n", .{});
    //     try state.num.append(state.a, state.ch.character.b());
    //     return;
    // }

    // if (!isdigit(state.ch) and state.num.items.len > 0) {
    //     state.repeating.repeating_count = std.fmt.parseInt(u32, state.num.items, 10) catch {
    //         // TODO: error handleing
    //         return;
    //     };
    //     state.num.clearRetainingCapacity();
    //
    //     // Some functions are smart and will look at repeating_count when the
    //     // run and then set it to 0 when finished. Some are not and so this
    //     // allows the dumb ones (and user defined ones) to still be repeated.
    //     // An optimization might be to make this return a dynamic dispatch
    //     // object so we can just call it many times and not worry about finding
    //     // it many times.
    //     errdefer state.repeating.repeating_count = 0;
    //     var i: usize = 0;
    //     while (i < state.repeating.repeating_count) : (i += 1) {
    //         try state.key_func[@intFromEnum(state.config.mode)](buffer, state);
    //     }
    //     state.repeating.repeating_count = 0;
    //     return;
    // }

    switch (state.ch.character) {
        //         @as(c_int, 58) => {
        //             state.*.x = 1;
        //             frontend_move_cursor(state.*.status_bar, state.*.x, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
        //             state.*.config.mode = @as(c_uint, @bitCast(COMMAND));
        //             break;
        //         },
        //         @as(c_int, 47) => {
        //             if (state.*.is_exploring) break;
        //             reset_command(state.*.command, &state.*.command_s);
        //             state.*.x = state.*.command_s +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
        //             frontend_move_cursor(state.*.status_bar, state.*.x, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
        //             state.*.config.mode = @as(c_uint, @bitCast(SEARCH));
        //             break;
        //         },
        //         @as(c_int, 118) => {
        //             if (state.*.is_exploring) break;
        //             buffer.*.visual.start = buffer.*.cursor;
        //             buffer.*.visual.end = buffer.*.cursor;
        //             buffer.*.visual.is_line = 0;
        //             state.*.config.mode = @as(c_uint, @bitCast(VISUAL));
        //             break;
        //         },
        //         @as(c_int, 86) => {
        //             if (state.*.is_exploring) break;
        //             buffer.*.visual.start = buffer.*.rows.data[buffer_get_row(buffer)].start;
        //             buffer.*.visual.end = buffer.*.rows.data[buffer_get_row(buffer)].end;
        //             buffer.*.visual.is_line = 1;
        //             state.*.config.mode = @as(c_uint, @bitCast(VISUAL));
        //             break;
        //         },
        //         @as(c_int, 15) => {
        //             {
        //                 while (true) {
        //                     var undo: Undo = Undo{
        //                         .type = @as(c_uint, @bitCast(@as(c_int, 0))),
        //                         .data = @import("std").mem.zeroes(Data),
        //                         .start = @import("std").mem.zeroes(usize),
        //                         .end = @import("std").mem.zeroes(usize),
        //                     };
        //                     _ = &undo;
        //                     undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
        //                     undo.start = buffer.*.cursor;
        //                     state.*.cur_undo = undo;
        //                     if (!false) break;
        //                 }
        //                 var row: usize = buffer_get_row(buffer);
        //                 _ = &row;
        //                 var end: usize = buffer.*.rows.data[row].end;
        //                 _ = &end;
        //                 buffer.*.cursor = end;
        //                 buffer_newline_indent(buffer, state);
        //                 undo_push(state, &state.*.undo_stack, state.*.cur_undo);
        //                 break;
        //             }
        //         },
        //         @as(c_int, 110) => {
        //             {
        //                 var index_1: usize = search(buffer, state.*.command, state.*.command_s);
        //                 _ = &index_1;
        //                 buffer.*.cursor = index_1;
        //             }
        //             break;
        //         },
        //         @as(c_int, 117) => {
        //             {
        //                 var undo: Undo = undo_pop(&state.*.undo_stack);
        //                 _ = &undo;
        //                 buffer_handle_undo(state, &undo);
        //                 undo_push(state, &state.*.redo_stack, state.*.cur_undo);
        //                 free_undo(&undo);
        //             }
        //             break;
        //         },
        //         @as(c_int, 85) => {
        //             {
        //                 var redo: Undo = undo_pop(&state.*.redo_stack);
        //                 _ = &redo;
        //                 buffer_handle_undo(state, &redo);
        //                 undo_push(state, &state.*.undo_stack, state.*.cur_undo);
        //                 free_undo(&redo);
        //             }
        //             break;
        //         },
        //         @as(c_int, 19) => {
        //             {
        //                 handle_save(buffer);
        //                 state.*.config.QUIT = 1;
        //             }
        //             break;
        //         },
        //         @as(c_int, 3), @as(c_int, 27) => {
        //             state.*.repeating.repeating_count = 0;
        //             reset_command(state.*.command, &state.*.command_s);
        //             state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
        //             break;
        //         },
        //         @as(c_int, 410) => {
        //             {
        //                 frontend_resize_window(state);
        //             }
        //             break;
        //         },
        //         @as(c_int, 121) => {
        //             {
        //                 while (true) {
        //                     switch (state.*.leader) {
        //                         @as(c_uint, @bitCast(@as(c_int, 3))) => {
        //                             {
        //                                 if (state.*.repeating.repeating_count == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        //                                     state.*.repeating.repeating_count = 1;
        //                                 }
        //                                 reset_command(state.*.clipboard.str, &state.*.clipboard.len);
        //                                 {
        //                                     var i: usize = 0;
        //                                     _ = &i;
        //                                     while (i < state.*.repeating.repeating_count) : (i +%= 1) {
        //                                         buffer_yank_line(buffer, state, i);
        //                                     }
        //                                 }
        //                                 state.*.repeating.repeating_count = 0;
        //                             }
        //                             break;
        //                         },
        //                         else => break,
        //                     }
        //                     break;
        //                 }
        //             }
        //             break;
        //         },
        //         @as(c_int, 112) => {
        //             {
        //                 if (state.*.clipboard.len == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) break;
        //                 while (true) {
        //                     var undo: Undo = Undo{
        //                         .type = @as(c_uint, @bitCast(@as(c_int, 0))),
        //                         .data = @import("std").mem.zeroes(Data),
        //                         .start = @import("std").mem.zeroes(usize),
        //                         .end = @import("std").mem.zeroes(usize),
        //                     };
        //                     _ = &undo;
        //                     undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
        //                     undo.start = buffer.*.cursor;
        //                     state.*.cur_undo = undo;
        //                     if (!false) break;
        //                 }
        //                 var data: Data = dynstr_to_data(state.*.clipboard);
        //                 _ = &data;
        //                 if ((state.*.clipboard.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, state.*.clipboard.str[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\n'))) {
        //                     while (true) {
        //                         var file: *FILE = fopen("logs/cano.log", "a");
        //                         _ = &file;
        //                         if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
        //                             _ = fprintf(file, "%s:%d: newline\n", "src/keys.c", @as(c_int, 433));
        //                             _ = fclose(file);
        //                         }
        //                         if (!false) break;
        //                     }
        //                     var row: usize = buffer_get_row(buffer);
        //                     _ = &row;
        //                     var end: usize = buffer.*.rows.data[row].end;
        //                     _ = &end;
        //                     buffer.*.cursor = end;
        //                 }
        //                 buffer_insert_selection(buffer, &data, buffer.*.cursor);
        //                 state.*.cur_undo.end = buffer.*.cursor;
        //                 undo_push(state, &state.*.undo_stack, state.*.cur_undo);
        //                 if (((state.*.clipboard.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, state.*.clipboard.str[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\n'))) and (buffer.*.cursor < buffer.*.data.count)) {
        //                     buffer.*.cursor +%= 1;
        //                 }
        //             }
        //             break;
        //         },

        // term.ctrl('n') => {
        //     state.*.is_exploring = !state.*.is_exploring;
        // },

        else => {
            // if (state.*.is_exploring) {
            //     while (true) {
            //         switch (state.*.ch) {
            //             @as(c_int, 258), @as(c_int, 106) => {
            //                 if (state.explore_cursor < state.files.items.len - 1) {
            //                     state.explore_cursor += 1;
            //                 }
            //                 break;
            //             },
            //             @as(c_int, 259), @as(c_int, 107) => {
            //                 if (state.*.explore_cursor > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
            //                     state.*.explore_cursor -%= 1;
            //                 }
            //                 break;
            //             },
            //             @as(c_int, 10) => {
            //                 {
            //                     const f: File = state.files.items[state.explore_cursor];
            //                     if (f.is_directory) {
            //                         const str = try state.a.dupe(u8, f.path); // TODO: use a stack buffer
            //                         defer state.a.free(str);
            //                         state.files.clearRetainingCapacity();
            //                         try tools.scan_files(state, str);
            //                         state.explore_cursor = 0;
            //                     } else {
            //                         if (state.buffer) |buf| buf.deinit();
            //                         state.buffer = tools.load_buffer_from_file(f.path);
            //                         // var config_filename: *u8 = null;
            //                         // _ = &config_filename;
            //                         // var syntax_filename: *u8 = null;
            //                         // _ = &syntax_filename;
            //                         tools.load_config_from_file(state, state.buffer.?, null, null);
            //                         state.is_exploring = false;
            //                     }
            //                 }
            //                 break;
            //             },
            //             else => {},
            //         }
            //         break;
            //     }
            //     break;
            // }

            // if (handle_modifying_keys(buffer, state) != 0) break;

            std.log.warn("unimplemented key: {}", .{state.ch});
        },
    }

    // idk
    // if (state.repeating.repeating_count == 0) {
    //     state.leader = .NONE;
    // }
}

fn insert_esc(state: *State) anyerror!void {
    //     state.*.cur_undo.end = buffer.*.cursor;
    //     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    state.config.mode = .NORMAL;
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
}

fn initInsertKeys(a: std.mem.Allocator, insert: *State.KeyMapings) !void {
    try insert.put(a, norm(.Esc), .{ .Native = insert_esc });
    // switch (state.ch.character) {
    // 127, \b
    // .Backspace => {
    //     if (buffer.cursor > 0) {
    //         buffer.cursor -= 1;
    //         try Buffer.buffer_delete_char(buffer, state);
    //     }
    // },
    // @as(c_int, 19) => {
    //     {
    //         handle_save(buffer);
    //         state.*.config.QUIT = 1;
    //     }
    //     break;
    // },

    // ctrl-c
    // .Esc => { // back to normal mode
    // },
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

pub fn handle_command_keys(arg_buffer: *Buffer, state: *State) anyerror!void {
    _ = arg_buffer; // autofix
    _ = state; // autofix
    // var buffer = arg_buffer;
    // _ = &buffer;
    // while (true) {
    //     switch (state.*.ch) {
    //         @as(c_int, 8), @as(c_int, 127), @as(c_int, 263) => {
    //             {
    //                 if (state.*.x != @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) {
    //                     shift_str_left(state.*.command, &state.*.command_s, blk: {
    //                         const ref = &state.*.x;
    //                         ref.* -%= 1;
    //                         break :blk ref.*;
    //                     });
    //                     frontend_move_cursor(state.*.status_bar, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), state.*.x);
    //                 }
    //             }
    //             break;
    //         },
    //         @as(c_int, 3), @as(c_int, 27) => {
    //             reset_command(state.*.command, &state.*.command_s);
    //             state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //             break;
    //         },
    //         @as(c_int, 19) => {
    //             {
    //                 handle_save(buffer);
    //                 state.*.config.QUIT = 1;
    //             }
    //             break;
    //         },
    //         @as(c_int, 343), @as(c_int, 10) => {
    //             {
    //                 if (@as(c_int, @bitCast(@as(c_uint, state.*.command[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '!')) {
    //                     shift_str_left(state.*.command, &state.*.command_s, @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))));
    //                     var file: *FILE = popen(state.*.command, "r");
    //                     _ = &file;
    //                     if (file == @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
    //                         while (true) {
    //                             frontend_end();
    //                             _ = fprintf(stderr, "could not run command\n");
    //                             exit(@as(c_int, 1));
    //                             if (!false) break;
    //                         }
    //                     }
    //                     while (fgets(state.*.status_bar_msg, @as(c_int, @bitCast(@as(c_uint, @truncate(@sizeOf(*u8))))), file) != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
    //                         state.*.is_print_msg = @as(c_int, 1) != 0;
    //                     }
    //                     _ = pclose(file);
    //                 } else {
    //                     var command_s: usize = 0;
    //                     _ = &command_s;
    //                     var command: *Command_Token = lex_command(state, vw.view_create(state.*.command, state.*.command_s), &command_s);
    //                     _ = &command;
    //                     _ = execute_command(buffer, state, command, command_s);
    //                 }
    //                 reset_command(state.*.command, &state.*.command_s);
    //                 state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //             }
    //             break;
    //         },
    //         @as(c_int, 260) => {
    //             if (state.*.x > @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) {
    //                 state.*.x -%= 1;
    //             }
    //             break;
    //         },
    //         @as(c_int, 258) => break,
    //         @as(c_int, 259) => break,
    //         @as(c_int, 261) => {
    //             if (state.*.x < state.*.command_s) {
    //                 state.*.x +%= 1;
    //             }
    //             break;
    //         },
    //         @as(c_int, 410) => {
    //             frontend_resize_window(state);
    //             break;
    //         },
    //         else => {
    //             {
    //                 shift_str_right(state.*.command, &state.*.command_s, state.*.x);
    //                 state.*.command[
    //                     (blk: {
    //                         const ref = &state.*.x;
    //                         const tmp = ref.*;
    //                         ref.* +%= 1;
    //                         break :blk tmp;
    //                     }) -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))
    //                 ] = @as(u8, @bitCast(@as(i8, @truncate(state.*.ch))));
    //             }
    //             break;
    //         },
    //     }
    //     break;
    // }
}

pub fn handle_search_keys(arg_buffer: *Buffer, state: *State) anyerror!void {
    _ = arg_buffer; // autofix
    _ = state; // autofix
    // var buffer = arg_buffer;
    // _ = &buffer;
    // while (true) {
    //     switch (state.*.ch) {
    //         @as(c_int, 8), @as(c_int, 127), @as(c_int, 263) => {
    //             {
    //                 if (state.*.x != @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) {
    //                     shift_str_left(state.*.command, &state.*.command_s, blk: {
    //                         const ref = &state.*.x;
    //                         ref.* -%= 1;
    //                         break :blk ref.*;
    //                     });
    //                     frontend_move_cursor(state.*.status_bar, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), state.*.x);
    //                 }
    //             }
    //             break;
    //         },
    //         @as(c_int, 3), @as(c_int, 27) => {
    //             reset_command(state.*.command, &state.*.command_s);
    //             state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //             break;
    //         },
    //         @as(c_int, 10) => {
    //             {
    //                 var index_1: usize = search(buffer, state.*.command, state.*.command_s);
    //                 _ = &index_1;
    //                 if ((state.*.command_s > @as(usize, @bitCast(@as(c_long, @as(c_int, 2))))) and (strncmp(state.*.command, "s/", @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 2))))) == @as(c_int, 0))) {
    //                     var str: [128]u8 = undefined;
    //                     _ = &str;
    //                     _ = strncpy(@as(*u8, @ptrCast(@alignCast(&str))), state.*.command + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 2))))), state.*.command_s -% @as(usize, @bitCast(@as(c_long, @as(c_int, 2)))));
    //                     str[state.*.command_s -% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))))] = '\x00';
    //                     var token: *u8 = strtok(@as(*u8, @ptrCast(@alignCast(&str))), "/");
    //                     _ = &token;
    //                     var count: c_int = 0;
    //                     _ = &count;
    //                     var args: [2][100]u8 = undefined;
    //                     _ = &args;
    //                     while (token != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
    //                         var temp_buffer: [100]u8 = undefined;
    //                         _ = &temp_buffer;
    //                         _ = strcpy(@as(*u8, @ptrCast(@alignCast(&temp_buffer))), token);
    //                         if (count == @as(c_int, 0)) {
    //                             _ = strcpy(@as(*u8, @ptrCast(@alignCast(&args[@as(c_uint, @intCast(@as(c_int, 0)))]))), @as(*u8, @ptrCast(@alignCast(&temp_buffer))));
    //                         } else if (count == @as(c_int, 1)) {
    //                             _ = strcpy(@as(*u8, @ptrCast(@alignCast(&args[@as(c_uint, @intCast(@as(c_int, 1)))]))), @as(*u8, @ptrCast(@alignCast(&temp_buffer))));
    //                         }
    //                         count += 1;
    //                         token = strtok(null, "/");
    //                     }
    //                     index_1 = search(buffer, @as(*u8, @ptrCast(@alignCast(&args[@as(c_uint, @intCast(@as(c_int, 0)))]))), strlen(@as(*u8, @ptrCast(@alignCast(&args[@as(c_uint, @intCast(@as(c_int, 0)))])))));
    //                     find_and_replace(buffer, state, @as(*u8, @ptrCast(@alignCast(&args[@as(c_uint, @intCast(@as(c_int, 0)))]))), @as(*u8, @ptrCast(@alignCast(&args[@as(c_uint, @intCast(@as(c_int, 1)))]))));
    //                 }
    //                 buffer.*.cursor = index_1;
    //                 state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //             }
    //             break;
    //         },
    //         @as(c_int, 19) => {
    //             {
    //                 handle_save(buffer);
    //                 state.*.config.QUIT = 1;
    //             }
    //             break;
    //         },
    //         @as(c_int, 260) => {
    //             if (state.*.x > @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) {
    //                 state.*.x -%= 1;
    //             }
    //             break;
    //         },
    //         @as(c_int, 258) => break,
    //         @as(c_int, 259) => break,
    //         @as(c_int, 261) => {
    //             if (state.*.x < state.*.command_s) {
    //                 state.*.x +%= 1;
    //             }
    //             break;
    //         },
    //         @as(c_int, 410) => {
    //             frontend_resize_window(state);
    //             break;
    //         },
    //         else => {
    //             {
    //                 shift_str_right(state.*.command, &state.*.command_s, state.*.x);
    //                 state.*.command[
    //                     (blk: {
    //                         const ref = &state.*.x;
    //                         const tmp = ref.*;
    //                         ref.* +%= 1;
    //                         break :blk tmp;
    //                     }) -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))
    //                 ] = @as(u8, @bitCast(@as(i8, @truncate(state.*.ch))));
    //             }
    //             break;
    //         },
    //     }
    //     break;
    // }
}
pub fn handle_visual_keys(buffer: *Buffer, state: *State) anyerror!void {
    _ = buffer; // autofix
    _ = state; // autofix
    // frontend_cursor_visible(@as(c_int, 0));
    // while (true) {
    //     switch (state.*.ch) {
    //         @as(c_int, 3), @as(c_int, 27) => {
    //             {
    //                 state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //                 frontend_cursor_visible(@as(c_int, 1));
    //                 state.*.buffer.*.visual = Visual{
    //                     .start = @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))),
    //                     .end = @import("std").mem.zeroes(usize),
    //                     .is_line = 0,
    //                 };
    //             }
    //             break;
    //         },
    //         @as(c_int, 10) => break,
    //         @as(c_int, 19) => {
    //             {
    //                 handle_save(buffer);
    //                 state.*.config.QUIT = 1;
    //             }
    //             break;
    //         },
    //         @as(c_int, 100), @as(c_int, 120) => {
    //             {
    //                 var cond: c_int = @intFromBool(buffer.*.visual.start > buffer.*.visual.end);
    //                 _ = &cond;
    //                 var start: usize = if (cond != 0) buffer.*.visual.end else buffer.*.visual.start;
    //                 _ = &start;
    //                 var end: usize = if (cond != 0) buffer.*.visual.start else buffer.*.visual.end;
    //                 _ = &end;
    //                 while (true) {
    //                     var undo: Undo = Undo{
    //                         .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //                         .data = @import("std").mem.zeroes(Data),
    //                         .start = @import("std").mem.zeroes(usize),
    //                         .end = @import("std").mem.zeroes(usize),
    //                     };
    //                     _ = &undo;
    //                     undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
    //                     undo.start = start;
    //                     state.*.cur_undo = undo;
    //                     if (!false) break;
    //                 }
    //                 buffer_delete_selection(buffer, state, start, end);
    //                 undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //                 state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //                 frontend_cursor_visible(@as(c_int, 1));
    //             }
    //             break;
    //         },
    //         @as(c_int, 62) => {
    //             {
    //                 var cond: c_int = @intFromBool(buffer.*.visual.start > buffer.*.visual.end);
    //                 _ = &cond;
    //                 var start: usize = if (cond != 0) buffer.*.visual.end else buffer.*.visual.start;
    //                 _ = &start;
    //                 var end: usize = if (cond != 0) buffer.*.visual.start else buffer.*.visual.end;
    //                 _ = &end;
    //                 var position: usize = buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, state.*.config.indent)));
    //                 _ = &position;
    //                 var row: usize = index_get_row(buffer, start);
    //                 _ = &row;
    //                 var end_row: usize = index_get_row(buffer, end);
    //                 _ = &end_row;
    //                 {
    //                     var i: usize = row;
    //                     _ = &i;
    //                     while (i <= end_row) : (i +%= 1) {
    //                         buffer_calculate_rows(buffer);
    //                         buffer.*.cursor = buffer.*.rows.data[i].start;
    //                         if (state.*.config.indent > @as(c_int, 0)) {
    //                             {
    //                                 var i_1: usize = 0;
    //                                 _ = &i_1;
    //                                 while (@as(c_int, @bitCast(@as(c_uint, @truncate(i_1)))) < state.*.config.indent) : (i_1 +%= 1) {
    //                                     buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ' '))))));
    //                                 }
    //                             }
    //                         } else {
    //                             buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\t'))))));
    //                         }
    //                     }
    //                 }
    //                 buffer.*.cursor = position;
    //                 state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //                 frontend_cursor_visible(@as(c_int, 1));
    //             }
    //             break;
    //         },
    //         @as(c_int, 60) => {
    //             {
    //                 var cond: c_int = @intFromBool(buffer.*.visual.start > buffer.*.visual.end);
    //                 _ = &cond;
    //                 var start: usize = if (cond != 0) buffer.*.visual.end else buffer.*.visual.start;
    //                 _ = &start;
    //                 var end: usize = if (cond != 0) buffer.*.visual.start else buffer.*.visual.end;
    //                 _ = &end;
    //                 var row: usize = index_get_row(buffer, start);
    //                 _ = &row;
    //                 var end_row: usize = index_get_row(buffer, end);
    //                 _ = &end_row;
    //                 var offset: usize = 0;
    //                 _ = &offset;
    //                 {
    //                     var i: usize = row;
    //                     _ = &i;
    //                     while (i <= end_row) : (i +%= 1) {
    //                         buffer_calculate_rows(buffer);
    //                         buffer.*.cursor = buffer.*.rows.data[i].start;
    //                         if (state.*.config.indent > @as(c_int, 0)) {
    //                             {
    //                                 var j: usize = 0;
    //                                 _ = &j;
    //                                 while (@as(c_int, @bitCast(@as(c_uint, @truncate(j)))) < state.*.config.indent) : (j +%= 1) {
    //                                     if ((@as(c_int, @bitCast(@as(c_uint, (blk: {
    //                                         const tmp = @as(c_int, @bitCast(@as(c_uint, buffer.*.data.data[buffer.*.cursor])));
    //                                         if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    //                                     }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISspace)))))))) != 0) {
    //                                         buffer_delete_char(buffer, state);
    //                                         offset +%= 1;
    //                                         buffer_calculate_rows(buffer);
    //                                     }
    //                                 }
    //                             }
    //                         } else {
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
    //                 }
    //                 state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //                 frontend_cursor_visible(@as(c_int, 1));
    //             }
    //             break;
    //         },
    //         @as(c_int, 121) => {
    //             {
    //                 reset_command(state.*.clipboard.str, &state.*.clipboard.len);
    //                 var cond: c_int = @intFromBool(buffer.*.visual.start > buffer.*.visual.end);
    //                 _ = &cond;
    //                 var start: usize = if (cond != 0) buffer.*.visual.end else buffer.*.visual.start;
    //                 _ = &start;
    //                 var end: usize = if (cond != 0) buffer.*.visual.start else buffer.*.visual.end;
    //                 _ = &end;
    //                 buffer_yank_selection(buffer, state, start, end);
    //                 buffer.*.cursor = start;
    //                 state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //                 frontend_cursor_visible(@as(c_int, 1));
    //                 break;
    //             }
    //         },
    //         else => {
    //             {
    //                 if (buffer.*.visual.is_line != 0) {
    //                     buffer.*.visual.end = buffer.*.rows.data[buffer_get_row(buffer)].end;
    //                     if (buffer.*.visual.start >= buffer.*.visual.end) {
    //                         buffer.*.visual.end = buffer.*.rows.data[buffer_get_row(buffer)].start;
    //                         buffer.*.visual.start = buffer.*.rows.data[index_get_row(buffer, buffer.*.visual.start)].end;
    //                     }
    //                 } else {
    //                     buffer.*.visual.end = buffer.*.cursor;
    //                 }
    //             }
    //             break;
    //         },
    //     }
    //     break;
    // }
}

// ----------------------------------------------------------------------------

// const Command_Token = cmmd.Command_Token;
//
// pub extern fn lex_command(state: *State, command: String_View, token_s: *usize) *Command_Token;
// pub extern fn execute_command(buffer: *Buffer, state: *State, command: *Command_Token, command_s: usize) c_int;
//
// pub fn search(arg_buffer: *Buffer, arg_command: *u8, arg_command_s: usize) usize {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var command = arg_command;
//     _ = &command;
//     var command_s = arg_command_s;
//     _ = &command_s;
//     {
//         var i: usize = buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
//         _ = &i;
//         while (i < (buffer.*.data.count +% buffer.*.cursor)) : (i +%= 1) {
//             var pos: usize = i % buffer.*.data.count;
//             _ = &pos;
//             if (strncmp(buffer.*.data.data + pos, command, command_s) == @as(c_int, 0)) {
//                 return pos;
//             }
//         }
//     }
//     return buffer.*.cursor;
// }
// pub fn replace(arg_buffer: *Buffer, arg_state: *State, arg_new_str: *u8, arg_old_str_s: usize, arg_new_str_s: usize) void {
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
// pub fn find_and_replace(arg_buffer: *Buffer, arg_state: *State, arg_old_str: *u8, arg_new_str: *u8) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     var old_str = arg_old_str;
//     _ = &old_str;
//     var new_str = arg_new_str;
//     _ = &new_str;
//     var old_str_s: usize = strlen(old_str);
//     _ = &old_str_s;
//     var new_str_s: usize = strlen(new_str);
//     _ = &new_str_s;
//     var position: usize = search(buffer, old_str, old_str_s);
//     _ = &position;
//     if (position != buffer.*.cursor) {
//         buffer.*.cursor = position;
//         replace(buffer, state, new_str, old_str_s, new_str_s);
//     }
// }

fn motion_j(state: *State) !void {
    const count = if (state.repeating.is) blk: {
        const tmp = state.repeating.count;
        state.repeating.count = 0;
        state.repeating.is = false;
        break :blk tmp;
    } else 1;

    root.log(@src(), .debug, "motion j", .{});
    state.buffer.moveDown(count);
}

fn motion_k(state: *State) !void {
    const count = if (state.repeating.is) blk: {
        const tmp = state.repeating.count;
        state.repeating.count = 0;
        state.repeating.is = false;
        break :blk tmp;
    } else 1;

    root.log(@src(), .debug, "motion j", .{});
    state.buffer.moveUp(count);
}

// fn motion_g(state: *State) !void {
//     var row: usize = buffer_get_row(state.*.buffer);
//     _ = &row;
//     if (state.*.repeating.repeating_count >= state.*.buffer.*.rows.count) {
//         state.*.repeating.repeating_count = state.*.buffer.*.rows.count;
//     }
//     if (state.*.repeating.repeating_count == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
//         state.*.repeating.repeating_count = 1;
//     }
//     state.*.buffer.*.cursor = state.*.buffer.*.rows.data[state.*.repeating.repeating_count -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].start;
//     state.*.repeating.repeating_count = 0;
//     if (state.*.leader != @as(c_uint, @bitCast(LEADER_D))) return;
//     var end: usize = state.*.buffer.*.rows.data[row].end;
//     _ = &end;
//     var start: usize = state.*.buffer.*.cursor;
//     _ = &start;
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//         undo.start = start;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
//     buffer_delete_selection(state.*.buffer, state, start, end);
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }

// pub fn motion_G(arg_state: *State) void {
//     var state = arg_state;
//     _ = &state;
//     var row: usize = buffer_get_row(state.*.buffer);
//     _ = &row;
//     var start: usize = state.*.buffer.*.rows.data[row].start;
//     _ = &start;
//     if (state.*.repeating.repeating_count > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
//         if (state.*.repeating.repeating_count >= state.*.buffer.*.rows.count) {
//             state.*.repeating.repeating_count = state.*.buffer.*.rows.count;
//         }
//         state.*.buffer.*.cursor = state.*.buffer.*.rows.data[state.*.repeating.repeating_count -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].start;
//         state.*.repeating.repeating_count = 0;
//     } else {
//         state.*.buffer.*.cursor = state.*.buffer.*.data.count;
//     }
//     if (state.*.leader != @as(c_uint, @bitCast(LEADER_D))) return;
//     var end: usize = state.*.buffer.*.cursor;
//     _ = &end;
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//         undo.start = start;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
//     buffer_delete_selection(state.*.buffer, state, start, end);
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }
// pub fn motion_0(arg_state: *State) void {
//     var state = arg_state;
//     _ = &state;
//     var row: usize = buffer_get_row(state.*.buffer);
//     _ = &row;
//     var end: usize = state.*.buffer.*.cursor;
//     _ = &end;
//     state.*.buffer.*.cursor = state.*.buffer.*.rows.data[row].start;
//     if (state.*.leader != @as(c_uint, @bitCast(LEADER_D))) return;
//     var start: usize = state.*.buffer.*.cursor;
//     _ = &start;
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//         undo.start = start;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
//     buffer_delete_selection(state.*.buffer, state, start, end);
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }

pub fn @"motion_$"(state: *State) !void {
    state.buffer.cursor = state.buffer.rows.items[state.buffer.row].end;

    //     var row: usize = buffer_get_row(state.*.buffer);
    //     _ = &row;
    //     var start: usize = state.*.buffer.*.cursor;
    //     _ = &start;
    //     state.*.buffer.*.cursor = state.*.buffer.*.rows.data[row].end;
    //     if (state.*.leader != @as(c_uint, @bitCast(LEADER_D))) return;
    //     var end: usize = state.*.buffer.*.cursor;
    //     _ = &end;
    //     while (true) {
    //         var undo: Undo = Undo{
    //             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
    //             .data = @import("std").mem.zeroes(Data),
    //             .start = @import("std").mem.zeroes(usize),
    //             .end = @import("std").mem.zeroes(usize),
    //         };
    //         _ = &undo;
    //         undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
    //         undo.start = start;
    //         state.*.cur_undo = undo;
    //         if (!false) break;
    //     }
    //     buffer_delete_selection(state.*.buffer, state, start, end -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    //     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
}
// pub fn motion_e(arg_state: *State) void {
//     var state = arg_state;
//     _ = &state;
//     var start: usize = state.*.buffer.*.cursor;
//     _ = &start;
//     if (((state.*.buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) < state.*.buffer.*.data.count) and !(isword(state.*.buffer.*.data.data[state.*.buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))]) != 0)) {
//         state.*.buffer.*.cursor +%= 1;
//     }
//     while (((state.*.buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) < state.*.buffer.*.data.count) and ((isword(state.*.buffer.*.data.data[state.*.buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))]) != 0) or ((@as(c_int, @bitCast(@as(c_uint, (blk: {
//         const tmp = @as(c_int, @bitCast(@as(c_uint, state.*.buffer.*.data.data[state.*.buffer.*.cursor])));
//         if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISspace)))))))) != 0))) {
//         state.*.buffer.*.cursor +%= 1;
//     }
//     if (state.*.leader != @as(c_uint, @bitCast(LEADER_D))) return;
//     var end: usize = state.*.buffer.*.cursor;
//     _ = &end;
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//         undo.start = start;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
//     buffer_delete_selection(state.*.buffer, state, start, end);
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }
// pub fn motion_b(arg_state: *State) void {
//     var state = arg_state;
//     _ = &state;
//     var buffer: *Buffer = state.*.buffer;
//     _ = &buffer;
//     if (buffer.*.cursor == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) return;
//     var end: usize = buffer.*.cursor;
//     _ = &end;
//     if (((buffer.*.cursor -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and !(isword(buffer.*.data.data[buffer.*.cursor -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))]) != 0)) {
//         buffer.*.cursor -%= 1;
//     }
//     while (((buffer.*.cursor -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and ((isword(buffer.*.data.data[buffer.*.cursor -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))]) != 0) or ((@as(c_int, @bitCast(@as(c_uint, (blk: {
//         const tmp = @as(c_int, @bitCast(@as(c_uint, buffer.*.data.data[buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))])));
//         if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISspace)))))))) != 0))) {
//         buffer.*.cursor -%= 1;
//     }
//     if ((buffer.*.cursor -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
//         buffer.*.cursor -%= 1;
//     }
//     if (state.*.leader != @as(c_uint, @bitCast(LEADER_D))) return;
//     var start: usize = buffer.*.cursor;
//     _ = &start;
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//         undo.start = start;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
//     buffer_delete_selection(buffer, state, start, end);
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }
// pub fn motion_w(arg_state: *State) void {
//     var state = arg_state;
//     _ = &state;
//     var buffer: *Buffer = state.*.buffer;
//     _ = &buffer;
//     var start: usize = buffer.*.cursor;
//     _ = &start;
//     while ((buffer.*.cursor < buffer.*.data.count) and ((isword(buffer.*.data.data[buffer.*.cursor]) != 0) or ((@as(c_int, @bitCast(@as(c_uint, (blk: {
//         const tmp = @as(c_int, @bitCast(@as(c_uint, buffer.*.data.data[buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))])));
//         if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISspace)))))))) != 0))) {
//         buffer.*.cursor +%= 1;
//     }
//     if (buffer.*.cursor < buffer.*.data.count) {
//         buffer.*.cursor +%= 1;
//     }
//     if (state.*.leader != @as(c_uint, @bitCast(LEADER_D))) return;
//     var end: usize = buffer.*.cursor -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
//     _ = &end;
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//         undo.start = start;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
//     buffer_delete_selection(buffer, state, start, end -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }

pub fn handleLeaderKeys(state: *State) bool {
    if (state.ch.modifiers.ctrl or state.ch.modifiers.altr) return false;
    switch (state.ch.character) {
        .d => {
            state.leader = .D;
            return true;
        },
        .y => {
            state.leader = .Y;
            return true;
        },
        .r => {
            state.leader = .R;
            return true;
        },
        else => return true,
    }
}

// pub fn buffer_handle_undo(arg_state: *State, arg_undo: *Undo) void {
//     var state = arg_state;
//     _ = &state;
//     var undo = arg_undo;
//     _ = &undo;
//     var buffer: *Buffer = state.*.buffer;
//     _ = &buffer;
//     var redo: Undo = Undo{
//         .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//         .data = @import("std").mem.zeroes(Data),
//         .start = @import("std").mem.zeroes(usize),
//         .end = @import("std").mem.zeroes(usize),
//     };
//     _ = &redo;
//     redo.start = undo.*.start;
//     state.*.cur_undo = redo;
//     while (true) {
//         switch (undo.*.type) {
//             @as(c_uint, @bitCast(@as(c_int, 0))) => break,
//             @as(c_uint, @bitCast(@as(c_int, 1))) => {
//                 state.*.cur_undo.type = @as(c_uint, @bitCast(if (undo.*.data.count > @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) DELETE_MULT_CHAR else DELETE_CHAR));
//                 state.*.cur_undo.end = (undo.*.start +% undo.*.data.count) -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
//                 buffer.*.cursor = undo.*.start;
//                 buffer_insert_selection(buffer, &undo.*.data, undo.*.start);
//                 break;
//             },
//             @as(c_uint, @bitCast(@as(c_int, 2))) => {
//                 state.*.cur_undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//                 buffer.*.cursor = undo.*.start;
//                 buffer_delete_char(buffer, state);
//                 break;
//             },
//             @as(c_uint, @bitCast(@as(c_int, 3))) => {
//                 state.*.cur_undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//                 state.*.cur_undo.end = undo.*.end;
//                 buffer.*.cursor = undo.*.start;
//                 while (true) {
//                     var file: *FILE = fopen("logs/cano.log", "a");
//                     _ = &file;
//                     if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
//                         _ = fprintf(file, "%s:%d: %zu %zu\n", "src/keys.c", @as(c_int, 314), undo.*.start, undo.*.end);
//                         _ = fclose(file);
//                     }
//                     if (!false) break;
//                 }
//                 buffer_delete_selection(buffer, state, undo.*.start, undo.*.end);
//                 break;
//             },
//             @as(c_uint, @bitCast(@as(c_int, 4))) => {
//                 state.*.cur_undo.type = @as(c_uint, @bitCast(REPLACE_CHAR));
//                 buffer.*.cursor = undo.*.start;
//                 while (true) {
//                     if ((&undo.*.data).*.count >= (&undo.*.data).*.capacity) {
//                         (&undo.*.data).*.capacity = if ((&undo.*.data).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&undo.*.data).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
//                         var new: ?*anyopaque = calloc((&undo.*.data).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(u8));
//                         _ = &new;
//                         while (true) {
//                             if (!(new != null)) {
//                                 frontend_end();
//                                 _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/keys.c", @as(c_int, 320));
//                                 _ = fprintf(stderr, "outta ram");
//                                 _ = fprintf(stderr, "\n");
//                                 exit(@as(c_int, 1));
//                             }
//                             if (!false) break;
//                         }
//                         _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&undo.*.data).*.data)), (&undo.*.data).*.count);
//                         free(@as(?*anyopaque, @ptrCast((&undo.*.data).*.data)));
//                         (&undo.*.data).*.data = @as(*u8, @ptrCast(@alignCast(new)));
//                     }
//                     (&undo.*.data).*.data[
//                         blk: {
//                             const ref = &(&undo.*.data).*.count;
//                             const tmp = ref.*;
//                             ref.* +%= 1;
//                             break :blk tmp;
//                         }
//                     ] = buffer.*.data.data[buffer.*.cursor];
//                     if (!false) break;
//                 }
//                 buffer.*.data.data[buffer.*.cursor] = undo.*.data.data[@as(c_uint, @intCast(@as(c_int, 0)))];
//                 break;
//             },
//             else => {},
//         }
//         break;
//     }
// }
//
// pub fn handle_move_left(arg_state: *State, arg_num: usize) void {
//     var state = arg_state;
//     _ = &state;
//     var num = arg_num;
//     _ = &num;
//     state.*.cur_undo.end = state.*.buffer.*.cursor;
//     if (state.*.cur_undo.end != state.*.cur_undo.start) {
//         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
//     }
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < num) : (i +%= 1) {
//             buffer_move_left(state.*.buffer);
//         }
//     }
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
//         undo.start = state.*.buffer.*.cursor;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
// }
// pub fn handle_move_down(arg_state: *State, arg_num: usize) void {
//     var state = arg_state;
//     _ = &state;
//     var num = arg_num;
//     _ = &num;
//     state.*.cur_undo.end = state.*.buffer.*.cursor;
//     if (state.*.cur_undo.end != state.*.cur_undo.start) {
//         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
//     }
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < num) : (i +%= 1) {
//             buffer_move_down(state.*.buffer);
//         }
//     }
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
//         undo.start = state.*.buffer.*.cursor;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
// }

// pub fn handle_move_up(arg_state: *State, arg_num: usize) void {
//     var state = arg_state;
//     _ = &state;
//     var num = arg_num;
//     _ = &num;
//     state.*.cur_undo.end = state.*.buffer.*.cursor;
//     if (state.*.cur_undo.end != state.*.cur_undo.start) {
//         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
//     }
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < num) : (i +%= 1) {
//             buffer_move_up(state.*.buffer);
//         }
//     }
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
//         undo.start = state.*.buffer.*.cursor;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
// }

// pub fn handle_move_right(arg_state: *State, arg_num: usize) void {
//     var state = arg_state;
//     _ = &state;
//     var num = arg_num;
//     _ = &num;
//     state.*.cur_undo.end = state.*.buffer.*.cursor;
//     if (state.*.cur_undo.end != state.*.cur_undo.start) {
//         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
//     }
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < num) : (i +%= 1) {
//             buffer_move_right(state.*.buffer);
//         }
//     }
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(DELETE_MULT_CHAR));
//         undo.start = state.*.buffer.*.cursor;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
// }
