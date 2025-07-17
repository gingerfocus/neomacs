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

const Ks = trm.KeySymbol;

const insertsfn = struct {
    fn append(s: *State, _: km.KeyFunctionDataValue) !void {
        if (s.ch.modifiers.bits() == 0) {
            const buf = s.getCurrentBuffer();
            try buf.insertCharacter(s.ch.character);
        }
    }
};

/// TODO: I dont think this needs an arena
pub fn create(
    alloc: std.mem.Allocator,
    arena: *std.heap.ArenaAllocator,
) !km.ModeToKeys {
    const a = arena.allocator();

    var modes = km.ModeToKeys{};

    const normal = try a.create(km.KeyMaps);
    normal.* = km.KeyMaps{
        .modeid = ModeId.Normal,
        .targeter = km.KeyFunction.initstate(actions.move),
        .fallback = null,
    };
    try modes.put(alloc, ModeId.Normal, normal);

    const insert = try a.create(km.KeyMaps);
    insert.* = km.KeyMaps{
        .modeid = ModeId.Insert,
        .targeter = km.KeyFunction.initstate(actions.move),
        .fallback = km.KeyFunction.initstate(insertsfn.append),
    };
    try modes.put(alloc, ModeId.Insert, insert);

    const visual = try a.create(km.KeyMaps);
    visual.* = km.KeyMaps{
        .modeid = ModeId.Visual,
        .targeter = km.KeyFunction.initstate(actions.moveKeep),
        .fallback = null,
    };
    try modes.put(alloc, ModeId.Visual, visual);

    // insert
    try initInsertKeys(a, insert);
    try insert.put(a, norm(Ks.Esc.toBits()), km.KeyFunction.initsetmod(ModeId.Normal));

    // normal
    try initToInsertKeys(a, normal);
    try initToVisualKeys(a, normal);
    try initMotionKeys(a, normal, &modes);
    try initNormalKeys(a, normal);
    try initModifyingKeys(a, normal, &modes);

    // visual
    try initMotionKeys(a, visual, &modes);
    try visual.put(a, norm(Ks.Esc.toBits()), km.KeyFunction.initsetmod(ModeId.Normal));
    try visual.put(a, norm('d'), km.KeyFunction.initstate(actions.deletelines));

    // command
    try normal.put(a, norm(':'), km.KeyFunction.initsetmod(km.ModeId.Command));
    try command.init(a, &modes);
    return modes;
}

pub fn initMotionKeys(a: std.mem.Allocator, maps: *km.KeyMaps, modes: *km.ModeToKeys) !void {
    // arrow keys?
    try maps.put(a, norm('j'), km.KeyFunction.initstate(targeters.target_down));
    try maps.put(a, norm('k'), km.KeyFunction.initstate(targeters.target_up));
    try maps.put(a, norm('l'), km.KeyFunction.initstate(targeters.target_right));
    try maps.put(a, norm('h'), km.KeyFunction.initstate(targeters.target_left));

    try maps.put(a, norm('G'), km.KeyFunction.initstate(targeters.target_bottom));
    try maps.put(a, '$', km.KeyFunction.initstate(targeters.motion_end));
    try maps.put(a, '0', km.KeyFunction.initstate(targeters.motionstart));

    try maps.put(a, norm('w'), km.KeyFunction.initstate(targeters.motion_word_start));
    try maps.put(a, norm('e'), km.KeyFunction.initstate(targeters.motion_word_end));
    try maps.put(a, norm('b'), km.KeyFunction.initstate(targeters.motion_word_back));

    //  @as(c_int, 37) buffer_next_brace(buffer);

    const g = try maps.then(a, modes, norm('g'));
    g.targeter = km.KeyFunction.initstate(actions.move);

    try g.put(a, norm('g'), km.KeyFunction.initstate(targeters.top));

    // const gq = try g.then(a, 'q');
    // _ = gq; // autofix
}

pub fn initModifyingKeys(a: std.mem.Allocator, maps: *km.KeyMaps, modes: *km.ModeToKeys) !void {
    // x - buffer_delete_ch(buffer, state);

    // c - buffer_replace_ch(buffer, state);

    const d = try maps.then(a, modes, norm('d'));
    d.targeter = km.KeyFunction.initstate(actions.deletelines);
    try d.put(a, norm('d'), km.KeyFunction.initstate(targeters.full_line));
    // TODO: this is not correct, some motions select different areas in this
    // mode
    try initMotionKeys(a, d, modes);
}

fn initToVisualKeys(a: std.mem.Allocator, normal: *km.KeyMaps) !void {
    try normal.put(a, norm('v'), km.KeyFunction.initstate(visuals.range));
    try normal.put(a, norm('V'), km.KeyFunction.initstate(visuals.line));
    try normal.put(a, ctrl('v'), km.KeyFunction.initstate(visuals.block));
}

fn initToInsertKeys(a: std.mem.Allocator, normal: *km.KeyMaps) !void {
    try normal.put(a, norm('i'), km.KeyFunction.initstate(inserts.before));
    try normal.put(a, norm('I'), km.KeyFunction.initstate(inserts.start));
    try normal.put(a, norm('a'), km.KeyFunction.initstate(inserts.after));
    try normal.put(a, norm('A'), km.KeyFunction.initstate(inserts.end));
    try normal.put(a, norm('o'), km.KeyFunction.initstate(inserts.below));
    try normal.put(a, norm('O'), km.KeyFunction.initstate(inserts.above));
}

fn initNormalKeys(a: std.mem.Allocator, normal: *km.KeyMaps) !void {
    _ = a;
    _ = normal;

    // if (tools.check_keymaps(buffer, state)) return;

    // if (state.leader == .NONE) {
    //     if (handleLeaderKeys(state)) return;
    // } else if (state.ch.character == .Esc) {
    //     state.leader = .NONE;
    // }

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

    // @as(c_int, 58) => {
    //     state.*.x = 1;
    //     frontend_move_cursor(state.*.status_bar, state.*.x, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    //     state.*.config.mode = @as(c_uint, @bitCast(COMMAND));
    //     break;
    // },
    // @as(c_int, 47) => {
    //     if (state.*.is_exploring) break;
    //     reset_command(state.*.command, &state.*.command_s);
    //     state.*.x = state.*.command_s +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    //     frontend_move_cursor(state.*.status_bar, state.*.x, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    //     state.*.config.mode = @as(c_uint, @bitCast(SEARCH));
    //     break;
    // },
    // @as(c_int, 118) => {
    //     if (state.*.is_exploring) break;
    //     buffer.*.visual.start = buffer.*.cursor;
    //     buffer.*.visual.end = buffer.*.cursor;
    //     buffer.*.visual.is_line = 0;
    //     state.*.config.mode = @as(c_uint, @bitCast(VISUAL));
    //     break;
    // },
    // @as(c_int, 86) => {
    //     if (state.*.is_exploring) break;
    //     buffer.*.visual.start = buffer.*.rows.data[buffer_get_row(buffer)].start;
    //     buffer.*.visual.end = buffer.*.rows.data[buffer_get_row(buffer)].end;
    //     buffer.*.visual.is_line = 1;
    //     state.*.config.mode = @as(c_uint, @bitCast(VISUAL));
    //     break;
    // },
    // @as(c_int, 15) => {
    //     {
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
    //         var row: usize = buffer_get_row(buffer);
    //         _ = &row;
    //         var end: usize = buffer.*.rows.data[row].end;
    //         _ = &end;
    //         buffer.*.cursor = end;
    //         buffer_newline_indent(buffer, state);
    //         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //         break;
    //     }
    // },
    // @as(c_int, 110) => {
    //     {
    //         var index_1: usize = search(buffer, state.*.command, state.*.command_s);
    //         _ = &index_1;
    //         buffer.*.cursor = index_1;
    //     }
    //     break;
    // },
    // @as(c_int, 117) => {
    //     {
    //         var undo: Undo = undo_pop(&state.*.undo_stack);
    //         _ = &undo;
    //         buffer_handle_undo(state, &undo);
    //         undo_push(state, &state.*.redo_stack, state.*.cur_undo);
    //         free_undo(&undo);
    //     }
    //     break;
    // },
    // @as(c_int, 85) => {
    //     {
    //         var redo: Undo = undo_pop(&state.*.redo_stack);
    //         _ = &redo;
    //         buffer_handle_undo(state, &redo);
    //         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //         free_undo(&redo);
    //     }
    //     break;
    // },
    // @as(c_int, 19) => {
    //     {
    //         handle_save(buffer);
    //         state.*.config.QUIT = 1;
    //     }
    //     break;
    // },
    // @as(c_int, 3), @as(c_int, 27) => {
    //     state.*.repeating.repeating_count = 0;
    //     reset_command(state.*.command, &state.*.command_s);
    //     state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //     break;
    // },
    // @as(c_int, 410) => {
    //     {
    //         frontend_resize_window(state);
    //     }
    //     break;
    // },
    // @as(c_int, 121) => {
    //     {
    //         while (true) {
    //             switch (state.*.leader) {
    //                 @as(c_uint, @bitCast(@as(c_int, 3))) => {
    //                     {
    //                         if (state.*.repeating.repeating_count == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
    //                             state.*.repeating.repeating_count = 1;
    //                         }
    //                         reset_command(state.*.clipboard.str, &state.*.clipboard.len);
    //                         {
    //                             var i: usize = 0;
    //                             _ = &i;
    //                             while (i < state.*.repeating.repeating_count) : (i +%= 1) {
    //                                 buffer_yank_line(buffer, state, i);
    //                             }
    //                         }
    //                         state.*.repeating.repeating_count = 0;
    //                     }
    //                     break;
    //                 },
    //                 else => break,
    //             }
    //             break;
    //         }
    //     }
    //     break;
    // },
    // @as(c_int, 112) => {
    //     {
    //         if (state.*.clipboard.len == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) break;
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
    //         var data: Data = dynstr_to_data(state.*.clipboard);
    //         _ = &data;
    //         if ((state.*.clipboard.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, state.*.clipboard.str[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\n'))) {
    //             while (true) {
    //                 var file: *FILE = fopen("logs/cano.log", "a");
    //                 _ = &file;
    //                 if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
    //                     _ = fprintf(file, "%s:%d: newline\n", "src/keys.c", @as(c_int, 433));
    //                     _ = fclose(file);
    //                 }
    //                 if (!false) break;
    //             }
    //             var row: usize = buffer_get_row(buffer);
    //             _ = &row;
    //             var end: usize = buffer.*.rows.data[row].end;
    //             _ = &end;
    //             buffer.*.cursor = end;
    //         }
    //         buffer_insert_selection(buffer, &data, buffer.*.cursor);
    //         state.*.cur_undo.end = buffer.*.cursor;
    //         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //         if (((state.*.clipboard.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, state.*.clipboard.str[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\n'))) and (buffer.*.cursor < buffer.*.data.count)) {
    //             buffer.*.cursor +%= 1;
    //         }
    //     }
    //     break;
    // },

    // term.ctrl('n') => {
    //     state.*.is_exploring = !state.*.is_exploring;
    // },

    // else => {
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

    // std.log.warn("unimplemented key: {}", .{state.ch});
    // },

    // idk
    // if (state.repeating.repeating_count == 0) {
    //     state.leader = .NONE;
    // }
}

fn deleteBufferCharacter(state: *State, _: km.KeyFunctionDataValue) !void {
    const buffer = state.getCurrentBuffer();
    try buffer.bufferDelete(state.a);
}

fn insertTab(buffer: *Buffer, _: km.KeyFunctionDataValue) !void {
    for (0..4) |_| try buffer.insertCharacter(' ');
}

fn initInsertKeys(a: std.mem.Allocator, insert: *km.KeyMaps) !void {
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

/// A collection of key targeters that can be applied in different contexts.
const targeters = struct {
    /// Selects `count` full lines starting from the current cursor position.
    fn full_line(state: *State, _: km.KeyFunctionDataValue) !void {
        const count = state.takeRepeating();
        const buffer = state.getCurrentBuffer();

        const start = lib.Vec2{ .row = buffer.row, .col = 0 };

        const row = @min(buffer.row + count, buffer.lines.items.len - 1);

        buffer.target = .{
            .mode = .Line,
            .start = start,
            .end = .{
                .row = row,
                .col = buffer.lines.items[row].items.len,
            },
        };
    }

    fn target_down(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const count = state.takeRepeating();

        const start = buffer.position();
        var end = start;
        end.row = @min(start.row + count, buffer.lines.items.len - 1);
        end.col = @min(end.col, buffer.lines.items[end.row].items.len);

        buffer.updateEnd(start, end);
    }

    fn target_up(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        const count = state.takeRepeating();

        buffer.row = if (buffer.row < count) 0 else buffer.row - count;

        buffer.col = @min(buffer.col, buffer.lines.items[buffer.row].items.len);
        // buffer.updatePostionKeepRow();
    }

    fn target_right(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        const count = state.takeRepeating();

        if (buffer.target) |*t| {
            t.end = buffer.moveRight(t.end, count);
        } else {
            const start = buffer.position();
            buffer.target = .{ .start = start, .end = buffer.moveRight(start, count) };
        }
    }

    fn target_left(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        const count = state.takeRepeating();

        const start = buffer.position();
        buffer.target = .{ .start = start, .end = buffer.moveLeft(start, count) };
    }

    fn top(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        const count = state.takeRepeating();

        std.log.debug("motionTop: target = {}", .{count});
        buffer.target = .{
            .mode = .Line,
            .start = buffer.position(),
            .end = .{ .row = count - 1, .col = 0 },
        };
        // buffer.updatePostionKeepRow();

    }

    fn target_bottom(state: *State, _: km.KeyFunctionDataValue) !void {
        _ = state.repeating.take();
        const buffer = state.getCurrentBuffer();

        const start = buffer.position();
        var end = start;
        end.row = buffer.lines.items.len - 1;

        buffer.updateEnd(start, end);
    }

    fn motion_word_end(state: *State, ctx: km.KeyFunctionDataValue) !void {
        _ = state;
        _ = ctx;

        root.log(@src(), .debug, "motion_word_end: unimplemented", .{});
        // try motion_word_start(state, ctx);
        //
        // const buffer = state.getCurrentBuffer();
        // if (buffer.target) |*target| {
        //     target.end = buffer.moveLeft(target.end, 1);
        // }
    }

    fn motion_word_back(state: *State, _: km.KeyFunctionDataValue) !void {
        _ = state;

        root.log(@src(), .debug, "motion_word_back: unimplemented", .{});
        // const buffer = state.getCurrentBuffer();
        // const start = buffer.position();
        // var end = start;
        //
        // var loop = true;
        // while (loop) {
        //     end = buffer.moveLeft(end, 1);
        //
        //     if (std.ascii.isAlphanumeric(buffer.lines.items[end.row].items[end.col])) {
        //         loop = false;
        //     } else {
        //         loop = std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col]);
        //     }
        // }
    }

    /// TODO: this is not correct, it should loop on more than just
    /// alphanumeric but also some symbols
    fn motion_word_start(state: *State, _: km.KeyFunctionDataValue) !void {
        // TODO: count
        const buffer = state.getCurrentBuffer();

        const start = buffer.position();
        var end = start;

        var inword = std.ascii.isAlphanumeric(buffer.lines.items[start.row].items[start.col]);
        var loop = true;
        while (loop) {
            end = buffer.moveRight(end, 1);

            if (inword) {
                inword = !std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col]);
            }

            if (inword) {
                loop = std.ascii.isAlphanumeric(buffer.lines.items[end.row].items[end.col]);
            } else {
                loop = std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col]);
            }

            // TODO: this can infinitly loop
        }

        buffer.updateEnd(start, end);
    }

    pub fn motion_end(state: *State, _: km.KeyFunctionDataValue) !void {
        const count = state.repeating.take();
        const buffer = state.getCurrentBuffer();

        const begin = buffer.position();
        var end = begin;

        end.row = @min(begin.row - (count - 1), buffer.lines.items.len - 1);
        end.col = buffer.lines.items[buffer.row].items.len;

        buffer.updateEnd(begin, end);
    }

    fn motionstart(state: *State, _: km.KeyFunctionDataValue) !void {
        const count = state.repeating.take();
        const buffer = state.getCurrentBuffer();

        const begin = buffer.position();
        var end = begin;

        end.row = std.math.sub(usize, begin.row, count - 1) catch 0;
        end.col = 0;

        buffer.updateEnd(begin, end);
    }
};

/// A collection of functions that act on a target.
const actions = struct {
    pub fn move(state: *State, ctx: km.KeyFunctionDataValue) !void {
        try moveKeep(state, ctx);

        const buffer = state.getCurrentBuffer();
        buffer.target = null; // reset the target
    }

    pub fn moveKeep(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        if (buffer.target) |target| {
            buffer.row = target.end.row;
            buffer.col = target.end.col;

            // only go back if we expend something
            buffer.curkeymap = null;
        }
    }

    pub fn none(_: *State) !void {}

    // Deletes text only using the target as a guide for lines
    fn deletelines(state: *State, _: km.KeyFunctionDataValue) !void {
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

// TODO: remake this functions by just saying, move to target, then go insert
// using the appropriate abstractions
const inserts = struct {
    fn before(state: *State, _: km.KeyFunctionDataValue) !void {
        root.log(@src(), .debug, "inserts before", .{});
        const buffer = state.getCurrentBuffer();

        // TODO: repeating this repeart the text you insert, i dont want to
        // make that
        state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }

    fn after(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        // targeter.right()
        // buffer.moveRight(buffer.position(), 1);

        // if (buffer.cursor < buffer.data.items.len) {
        //     buffer.cursor += 1;
        // }
        //state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }

    fn start(state: *State, ctx: km.KeyFunctionDataValue) !void {
        // TODO: move this to an external function that both call, for exmaple
        //
        // const target = motions.movestart(buffer, count);
        // buffer.moveto(target.end);
        // buffer.setMode(ModeId.Insert);

        try targeters.motionstart(state, ctx);
        const buffer = state.getCurrentBuffer();
        buffer.setMode(ModeId.Insert);
    }

    fn end(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        // const row = buffer.rows.items[buffer.row];
        //
        // buffer.cursor = row.end;
        // buffer.col = row.end - row.start;
        //
        // state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }

    fn above(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        buffer.col = 0;
        try buffer.newlineInsert(state.a);

        root.log(@src(), .debug, "number of lines: {d}", .{buffer.lines.items.len});

        buffer.row = @max(0, buffer.row - 1);

        state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }

    fn below(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const line = &buffer.lines.items[buffer.row];

        buffer.col = line.items.len;
        try buffer.newlineInsert(state.a);

        state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }
};

/// These are the visual mode shims that set a trivial target then move to visual mode
const visuals = struct {
    fn setModeMeta(comptime mode: Buffer.VisualMode) (*const fn (*State, km.KeyFunctionDataValue) anyerror!void) {
        return struct {
            fn set(state: *State, _: km.KeyFunctionDataValue) !void {
                const buffer = state.getCurrentBuffer();
                const cur = buffer.position();

                buffer.setMode(ModeId.Visual);
                buffer.target = .{ .mode = mode, .start = cur, .end = cur };
            }
        }.set;
    }

    const line = setModeMeta(.Line);
    const block = setModeMeta(.Block);
    const range = setModeMeta(.Range);
};
