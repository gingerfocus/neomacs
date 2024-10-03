const defs = @import("defs.zig");
const std = @import("std");

// pub const __off_t = c_long;
// pub const __off64_t = c_long;
// pub const chtype = c_uint;
// pub const struct__IO_marker = opaque {};
// pub const _IO_lock_t = anyopaque;
// pub const struct__IO_codecvt = opaque {};
// pub const struct__IO_wide_data = opaque {};
// pub const struct__IO_FILE = extern struct {
//     _flags: c_int = @import("std").mem.zeroes(c_int),
//     _IO_read_ptr: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_read_end: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_read_base: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_write_base: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_write_ptr: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_write_end: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_buf_base: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_buf_end: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_save_base: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_backup_base: *u8 = @import("std").mem.zeroes(*u8),
//     _IO_save_end: *u8 = @import("std").mem.zeroes(*u8),
//     _markers: ?*struct__IO_marker = @import("std").mem.zeroes(?*struct__IO_marker),
//     _chain: *struct__IO_FILE = @import("std").mem.zeroes(*struct__IO_FILE),
//     _fileno: c_int = @import("std").mem.zeroes(c_int),
//     _flags2: c_int = @import("std").mem.zeroes(c_int),
//     _old_offset: __off_t = @import("std").mem.zeroes(__off_t),
//     _cur_column: c_ushort = @import("std").mem.zeroes(c_ushort),
//     _vtable_offset: i8 = @import("std").mem.zeroes(i8),
//     _shortbuf: [1]u8 = @import("std").mem.zeroes([1]u8),
//     _lock: ?*_IO_lock_t = @import("std").mem.zeroes(?*_IO_lock_t),
//     _offset: __off64_t = @import("std").mem.zeroes(__off64_t),
//     _codecvt: ?*struct__IO_codecvt = @import("std").mem.zeroes(?*struct__IO_codecvt),
//     _wide_data: ?*struct__IO_wide_data = @import("std").mem.zeroes(?*struct__IO_wide_data),
//     _freeres_list: *struct__IO_FILE = @import("std").mem.zeroes(*struct__IO_FILE),
//     _freeres_buf: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
//     __pad5: usize = @import("std").mem.zeroes(usize),
//     _mode: c_int = @import("std").mem.zeroes(c_int),
//     _unused2: [20]u8 = @import("std").mem.zeroes([20]u8),
// };
// pub const FILE = struct__IO_FILE;
// pub extern var stderr: *FILE;
// pub extern fn fprintf(__stream: *FILE, __format: *const u8, ...) c_int;
// pub const acs_map: *chtype = @extern(*chtype, .{
//     .name = "acs_map",
// });
// pub const struct_screen = opaque {};
// pub const SCREEN = struct_screen;
// pub const attr_t = chtype;
// pub const struct_ldat = opaque {};

// const WINDOW = defs.WINDOW;
//
// pub const _ISalnum: c_int = 8;
// pub extern fn __ctype_b_loc() **const c_ushort;
//
// const String_View = defs.String_View;
//
// pub const NORMAL: c_int = 0;
// pub const INSERT: c_int = 1;
// pub const SEARCH: c_int = 2;
// pub const COMMAND: c_int = 3;
// pub const VISUAL: c_int = 4;
// pub const MODE_COUNT: c_int = 5;
// pub const Mode = c_uint;
//
// pub const LEADER_NONE: c_int = 0;
// pub const LEADER_R: c_int = 1;
// pub const LEADER_D: c_int = 2;
// pub const LEADER_Y: c_int = 3;
// pub const LEADER_COUNT: c_int = 4;
// pub const Leader = c_uint;
//
// pub const NONE: c_int = 0;
// pub const INSERT_CHARS: c_int = 1;
// pub const DELETE_CHAR: c_int = 2;
// pub const DELETE_MULT_CHAR: c_int = 3;
// pub const REPLACE_CHAR: c_int = 4;
// pub const Undo_Type = c_uint;
//
// pub const NO_ERROR: c_int = 0;
// pub const NOT_ENOUGH_ARGS: c_int = 1;
// pub const INVALID_ARGS: c_int = 2;
// pub const UNKNOWN_COMMAND: c_int = 3;
// pub const INVALID_IDENT: c_int = 4;
// pub const Command_Error = c_uint;
//
// pub const ThreadArgs = extern struct {
//     path_to_file: *const u8 = @import("std").mem.zeroes(*const u8),
//     filename: *const u8 = @import("std").mem.zeroes(*const u8),
//     lang: *const u8 = @import("std").mem.zeroes(*const u8),
// };
// pub const Color = extern struct {
//     color_name: [20]u8 = @import("std").mem.zeroes([20]u8),
//     is_custom_line_row: bool = @import("std").mem.zeroes(bool),
//     is_custom: bool = @import("std").mem.zeroes(bool),
//     slot: c_int = @import("std").mem.zeroes(c_int),
//     id: c_int = @import("std").mem.zeroes(c_int),
//     red: c_int = @import("std").mem.zeroes(c_int),
//     green: c_int = @import("std").mem.zeroes(c_int),
//     blue: c_int = @import("std").mem.zeroes(c_int),
// };
// pub const Point = extern struct {
//     x: usize = @import("std").mem.zeroes(usize),
//     y: usize = @import("std").mem.zeroes(usize),
// };
// pub const Visual = extern struct {
//     start: usize = @import("std").mem.zeroes(usize),
//     end: usize = @import("std").mem.zeroes(usize),
//     is_line: c_int = @import("std").mem.zeroes(c_int),
// };

const Rows = defs.Rows;
const Row = defs.Row;

// const Data = defs.Data;
//
// pub const Positions = extern struct {
//     data: *usize = @import("std").mem.zeroes(*usize),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
// };
const Buffer = defs.Buffer;
//
// pub const Arg = extern struct {
//     size: usize = @import("std").mem.zeroes(usize),
//     arg: *u8 = @import("std").mem.zeroes(*u8),
// };
//
// const Undo = defs.Undo;
// const Undo_Stack = defs.Undo_Stack;
//
// pub const Repeating = extern struct {
//     repeating: bool = @import("std").mem.zeroes(bool),
//     repeating_count: usize = @import("std").mem.zeroes(usize),
// };
// pub const Sized_Str = extern struct {
//     str: *u8 = @import("std").mem.zeroes(*u8),
//     len: usize = @import("std").mem.zeroes(usize),
// };
// const Map = defs.Map;
// const Maps = defs.Maps;
// pub const Var_Value = extern union {
//     as_int: c_int,
//     as_float: f32,
//     as_ptr: ?*anyopaque,
// };
// pub const VAR_INT: c_int = 0;
// pub const VAR_FLOAT: c_int = 1;
// pub const VAR_PTR: c_int = 2;
// pub const Var_Type = c_uint;
//
// const Variable = defs.Variable;
// const Variables = defs.Variables;
//
// const File = defs.File;
// const Files = defs.Files;
// const Config_Vars = defs.Config_Vars;
// const Config = defs.Config;
// const State = defs.State;
//
// pub const Brace = extern struct {
//     brace: u8 = @import("std").mem.zeroes(u8),
//     closing: c_int = @import("std").mem.zeroes(c_int),
// };
// pub const Ncurses_Color = extern struct {
//     r: c_int = @import("std").mem.zeroes(c_int),
//     g: c_int = @import("std").mem.zeroes(c_int),
//     b: c_int = @import("std").mem.zeroes(c_int),
// };
// pub const Syntax_Highlighting = extern struct {
//     row: usize = @import("std").mem.zeroes(usize),
//     col: usize = @import("std").mem.zeroes(usize),
//     size: usize = @import("std").mem.zeroes(usize),
// };
// pub extern var string_modes: [5]*u8;

pub fn buffer_calculate_rows(a: std.mem.Allocator, buffer: *Buffer) !void {
    // buffer.rows.count = 0;
    var start: usize = 0;

    for (buffer.data.items, 0..) |ch, i| {
        if (ch == '\n') {
            try buffer.rows.append(a, Row{ .start = start, .end = i });
            start = i + 1;
        }
    }
    try buffer.rows.append(a, Row{ .start = start, .end = buffer.data.items.len });
}

// pub fn buffer_insert_char(arg_state: *State, arg_buffer: *Buffer, arg_ch: u8) void {
//     var state = arg_state;
//     _ = &state;
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var ch = arg_ch;
//     _ = &ch;
//     while (true) {
//         if (!(buffer != @as(*Buffer, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//             frontend_end();
//             _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 19));
//             _ = fprintf(stderr, "buffer exists");
//             _ = fprintf(stderr, "\n");
//             exit(@as(c_int, 1));
//         }
//         if (!false) break;
//     }
//     if (buffer.*.cursor > buffer.*.data.count) {
//         buffer.*.cursor = buffer.*.data.count;
//     }
//     while (true) {
//         if ((&buffer.*.data).*.count >= (&buffer.*.data).*.capacity) {
//             (&buffer.*.data).*.capacity = if ((&buffer.*.data).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&buffer.*.data).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
//             var new: ?*anyopaque = calloc((&buffer.*.data).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(u8));
//             _ = &new;
//             while (true) {
//                 if (!(new != null)) {
//                     frontend_end();
//                     _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 23));
//                     _ = fprintf(stderr, "outta ram");
//                     _ = fprintf(stderr, "\n");
//                     exit(@as(c_int, 1));
//                 }
//                 if (!false) break;
//             }
//             _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&buffer.*.data).*.data)), (&buffer.*.data).*.count);
//             free(@as(?*anyopaque, @ptrCast((&buffer.*.data).*.data)));
//             (&buffer.*.data).*.data = @as(*u8, @ptrCast(@alignCast(new)));
//         }
//         (&buffer.*.data).*.data[
//             blk: {
//                 const ref = &(&buffer.*.data).*.count;
//                 const tmp = ref.*;
//                 ref.* +%= 1;
//                 break :blk tmp;
//             }
//         ] = ch;
//         if (!false) break;
//     }
//     _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), (buffer.*.data.count -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) -% buffer.*.cursor);
//     buffer.*.data.data[
//         blk: {
//             const ref = &buffer.*.cursor;
//             const tmp = ref.*;
//             ref.* +%= 1;
//             break :blk tmp;
//         }
//     ] = ch;
//     state.*.cur_undo.end = buffer.*.cursor;
//     buffer_calculate_rows(buffer);
// }

// pub fn buffer_delete_char(arg_buffer: *Buffer, arg_state: *State) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     _ = &state;
//     if (buffer.*.cursor < buffer.*.data.count) {
//         _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))])), (buffer.*.data.count -% buffer.*.cursor) -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
//         buffer.*.data.count -%= 1;
//         buffer_calculate_rows(buffer);
//     }
// }
// pub fn buffer_delete_ch(arg_buffer: *Buffer, arg_state: *State) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//         undo.start = buffer.*.cursor;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
//     reset_command(state.*.clipboard.str, &state.*.clipboard.len);
//     buffer_yank_char(buffer, state);
//     buffer_delete_char(buffer, state);
//     state.*.cur_undo.end = buffer.*.cursor;
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }
// pub fn buffer_replace_ch(arg_buffer: *Buffer, arg_state: *State) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     while (true) {
//         var undo: Undo = Undo{
//             .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//             .data = @import("std").mem.zeroes(Data),
//             .start = @import("std").mem.zeroes(usize),
//             .end = @import("std").mem.zeroes(usize),
//         };
//         _ = &undo;
//         undo.type = @as(c_uint, @bitCast(REPLACE_CHAR));
//         undo.start = buffer.*.cursor;
//         state.*.cur_undo = undo;
//         if (!false) break;
//     }
//     while (true) {
//         if ((&state.*.cur_undo.data).*.count >= (&state.*.cur_undo.data).*.capacity) {
//             (&state.*.cur_undo.data).*.capacity = if ((&state.*.cur_undo.data).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&state.*.cur_undo.data).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
//             var new: ?*anyopaque = calloc((&state.*.cur_undo.data).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(u8));
//             _ = &new;
//             while (true) {
//                 if (!(new != null)) {
//                     frontend_end();
//                     _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 82));
//                     _ = fprintf(stderr, "outta ram");
//                     _ = fprintf(stderr, "\n");
//                     exit(@as(c_int, 1));
//                 }
//                 if (!false) break;
//             }
//             _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&state.*.cur_undo.data).*.data)), (&state.*.cur_undo.data).*.count);
//             free(@as(?*anyopaque, @ptrCast((&state.*.cur_undo.data).*.data)));
//             (&state.*.cur_undo.data).*.data = @as(*u8, @ptrCast(@alignCast(new)));
//         }
//         (&state.*.cur_undo.data).*.data[
//             blk: {
//                 const ref = &(&state.*.cur_undo.data).*.count;
//                 const tmp = ref.*;
//                 ref.* +%= 1;
//                 break :blk tmp;
//             }
//         ] = buffer.*.data.data[buffer.*.cursor];
//         if (!false) break;
//     }
//     state.*.ch = frontend_getch(state.*.main_win);
//     buffer.*.data.data[buffer.*.cursor] = @as(u8, @bitCast(@as(i8, @truncate(state.*.ch))));
//     undo_push(state, &state.*.undo_stack, state.*.cur_undo);
// }
//
// pub fn buffer_delete_row(arg_buffer: *Buffer, arg_state: *State) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     var repeat: usize = state.*.repeating.repeating_count;
//     _ = &repeat;
//     if (repeat == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
//         repeat = 1;
//     }
//     if (repeat > (buffer.*.rows.count -% bufferGetRow(buffer))) {
//         repeat = buffer.*.rows.count -% bufferGetRow(buffer);
//     }
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < repeat) : (i +%= 1) {
//             reset_command(state.*.clipboard.str, &state.*.clipboard.len);
//             buffer_yank_line(buffer, state, @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))));
//             var row: usize = bufferGetRow(buffer);
//             _ = &row;
//             var cur: Row = buffer.*.rows.data[row];
//             _ = &cur;
//             var offset: usize = buffer.*.cursor -% cur.start;
//             _ = &offset;
//             while (true) {
//                 var undo: Undo = Undo{
//                     .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//                     .data = @import("std").mem.zeroes(Data),
//                     .start = @import("std").mem.zeroes(usize),
//                     .end = @import("std").mem.zeroes(usize),
//                 };
//                 _ = &undo;
//                 undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
//                 undo.start = cur.start;
//                 state.*.cur_undo = undo;
//                 if (!false) break;
//             }
//             if (row == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
//                 var end: usize = if (buffer.*.rows.count > @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) cur.end +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))) else cur.end;
//                 _ = &end;
//                 buffer_delete_selection(buffer, state, cur.start, end);
//             } else {
//                 state.*.cur_undo.start -%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
//                 buffer_delete_selection(buffer, state, cur.start -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), cur.end);
//             }
//             undo_push(state, &state.*.undo_stack, state.*.cur_undo);
//             buffer_calculate_rows(buffer);
//             if (row >= buffer.*.rows.count) {
//                 row = buffer.*.rows.count -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
//             }
//             cur = buffer.*.rows.data[row];
//             var pos: usize = cur.start +% offset;
//             _ = &pos;
//             if (pos > cur.end) {
//                 pos = cur.end;
//             }
//             buffer.*.cursor = pos;
//         }
//     }
//     state.*.repeating.repeating_count = 0;
// }

pub fn bufferGetRow(buffer: *const Buffer) usize {
    // std.debug.assert(buffer.cursor <= buffer.data.items.len);

    // there must be at least one line
    std.debug.assert(buffer.rows.items.len >= 1);

    for (buffer.rows.items, 0..) |row, i| {
        if (row.start <= buffer.cursor and buffer.cursor <= row.end) {
            return i;
        }
    }

    return 0;
}

// pub fn index_get_row(arg_buffer: *Buffer, arg_index_1: usize) usize {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var index_1 = arg_index_1;
//     _ = &index_1;
//     while (true) {
//         if (!(index_1 <= buffer.*.data.count)) {
//             frontend_end();
//             _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 102));
//             _ = fprintf(stderr, "index: %zu", index_1);
//             _ = fprintf(stderr, "\n");
//             exit(@as(c_int, 1));
//         }
//         if (!false) break;
//     }
//     while (true) {
//         if (!(buffer.*.rows.count >= @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))))) {
//             frontend_end();
//             _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 103));
//             _ = fprintf(stderr, "there must be at least one line");
//             _ = fprintf(stderr, "\n");
//             exit(@as(c_int, 1));
//         }
//         if (!false) break;
//     }
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < buffer.*.rows.count) : (i +%= 1) {
//             if ((buffer.*.rows.data[i].start <= index_1) and (index_1 <= buffer.*.rows.data[i].end)) {
//                 return i;
//             }
//         }
//     }
//     return 0;
// }
//
// pub fn buffer_yank_line(arg_buffer: *Buffer, arg_state: *State, arg_offset: usize) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     var offset = arg_offset;
//     _ = &offset;
//     var row: usize = bufferGetRow(buffer);
//     _ = &row;
//     if (offset > index_get_row(buffer, buffer.*.data.count)) return;
//     var cur: Row = buffer.*.rows.data[row +% offset];
//     _ = &cur;
//     var line_offset: c_int = 0;
//     _ = &line_offset;
//     var initial_s: usize = state.*.clipboard.len;
//     _ = &initial_s;
//     state.*.clipboard.len = (cur.end -% cur.start) +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
//     state.*.clipboard.str = @as(*u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.clipboard.str)), initial_s +% (state.*.clipboard.len *% @sizeOf(u8))))));
//     if (row > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
//         line_offset = -@as(c_int, 1);
//     } else {
//         state.*.clipboard.len -%= 1;
//         initial_s +%= 1;
//         state.*.clipboard.str[@as(c_uint, @intCast(@as(c_int, 0)))] = '\n';
//     }
//     while (true) {
//         if (!(state.*.clipboard.str != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//             frontend_end();
//             _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 129));
//             _ = fprintf(stderr, "clipboard was null");
//             _ = fprintf(stderr, "\n");
//             exit(@as(c_int, 1));
//         }
//         if (!false) break;
//     }
//     _ = strncpy(state.*.clipboard.str + initial_s, (buffer.*.data.data + cur.start) + @as(usize, @bitCast(@as(isize, @intCast(line_offset)))), state.*.clipboard.len);
//     state.*.clipboard.len +%= initial_s;
// }
//
// pub fn buffer_yank_char(arg_buffer: *Buffer, arg_state: *State) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     reset_command(state.*.clipboard.str, &state.*.clipboard.len);
//     state.*.clipboard.len = 2;
//     state.*.clipboard.str = @as(*u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.clipboard.str)), state.*.clipboard.len *% @sizeOf(u8)))));
//     while (true) {
//         if (!(state.*.clipboard.str != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//             frontend_end();
//             _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 140));
//             _ = fprintf(stderr, "clipboard was null");
//             _ = fprintf(stderr, "\n");
//             exit(@as(c_int, 1));
//         }
//         if (!false) break;
//     }
//     _ = strncpy(state.*.clipboard.str, buffer.*.data.data + buffer.*.cursor, state.*.clipboard.len);
// }
// pub fn buffer_yank_selection(arg_buffer: *Buffer, arg_state: *State, arg_start: usize, arg_end: usize) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     var start = arg_start;
//     _ = &start;
//     var end = arg_end;
//     _ = &end;
//     state.*.clipboard.len = (end -% start) +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
//     state.*.clipboard.str = @as(*u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.clipboard.str)), (state.*.clipboard.len *% @sizeOf(u8)) +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
//     while (true) {
//         if (!(state.*.clipboard.str != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//             frontend_end();
//             _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 148));
//             _ = fprintf(stderr, "clipboard was null %zu", state.*.clipboard.len);
//             _ = fprintf(stderr, "\n");
//             exit(@as(c_int, 1));
//         }
//         if (!false) break;
//     }
//     _ = strncpy(state.*.clipboard.str, buffer.*.data.data + start, state.*.clipboard.len);
// }
// pub fn buffer_delete_selection(arg_buffer: *Buffer, arg_state: *State, arg_start: usize, arg_end: usize) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     var start = arg_start;
//     _ = &start;
//     var end = arg_end;
//     _ = &end;
//     buffer_yank_selection(buffer, state, start, end);
//     var size: usize = end -% start;
//     _ = &size;
//     if (size >= buffer.*.data.count) {
//         size = buffer.*.data.count;
//     }
//     buffer.*.cursor = start;
//     if ((buffer.*.cursor +% size) > buffer.*.data.count) return;
//     if (state.*.cur_undo.data.capacity < size) {
//         state.*.cur_undo.data.capacity = size;
//         state.*.cur_undo.data.data = @as(*u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.cur_undo.data.data)), @sizeOf(u8) *% size))));
//         while (true) {
//             if (!(state.*.cur_undo.data.data != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//                 frontend_end();
//                 _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 166));
//                 _ = fprintf(stderr, "could not alloc");
//                 _ = fprintf(stderr, "\n");
//                 exit(@as(c_int, 1));
//             }
//             if (!false) break;
//         }
//     }
//     _ = strncpy(state.*.cur_undo.data.data, &buffer.*.data.data[buffer.*.cursor], size);
//     state.*.cur_undo.data.count = size;
//     _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% size])), buffer.*.data.count -% end);
//     buffer.*.data.count -%= size;
//     buffer_calculate_rows(buffer);
// }
// pub fn buffer_insert_selection(arg_buffer: *Buffer, arg_selection: *Data, arg_start: usize) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var selection = arg_selection;
//     _ = &selection;
//     var start = arg_start;
//     _ = &start;
//     buffer.*.cursor = start;
//     var size: usize = selection.*.count;
//     _ = &size;
//     if ((buffer.*.data.count +% size) >= buffer.*.data.capacity) {
//         buffer.*.data.capacity +%= size *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
//         buffer.*.data.data = @as(*u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(buffer.*.data.data)), (@sizeOf(u8) *% buffer.*.data.capacity) +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
//         while (true) {
//             if (!(buffer.*.data.data != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
//                 frontend_end();
//                 _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 187));
//                 _ = fprintf(stderr, "could not alloc");
//                 _ = fprintf(stderr, "\n");
//                 exit(@as(c_int, 1));
//             }
//             if (!false) break;
//         }
//     }
//     _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% size])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), buffer.*.data.count -% buffer.*.cursor);
//     _ = strncpy(&buffer.*.data.data[buffer.*.cursor], selection.*.data, size);
//     buffer.*.data.count +%= size;
//     buffer_calculate_rows(buffer);
// }
// pub fn buffer_move_up(arg_buffer: *Buffer) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var row: usize = bufferGetRow(buffer);
//     _ = &row;
//     var col: usize = buffer.*.cursor -% buffer.*.rows.data[row].start;
//     _ = &col;
//     if (row > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
//         buffer.*.cursor = buffer.*.rows.data[row -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].start +% col;
//         if (buffer.*.cursor > buffer.*.rows.data[row -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].end) {
//             buffer.*.cursor = buffer.*.rows.data[row -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].end;
//         }
//     }
// }
// pub fn buffer_move_down(arg_buffer: *Buffer) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var row: usize = bufferGetRow(buffer);
//     _ = &row;
//     var col: usize = buffer.*.cursor -% buffer.*.rows.data[row].start;
//     _ = &col;
//     if (row < (buffer.*.rows.count -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))))) {
//         buffer.*.cursor = buffer.*.rows.data[row +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].start +% col;
//         if (buffer.*.cursor > buffer.*.rows.data[row +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].end) {
//             buffer.*.cursor = buffer.*.rows.data[row +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].end;
//         }
//     }
// }
// pub fn buffer_move_right(arg_buffer: *Buffer) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     if (buffer.*.cursor < buffer.*.data.count) {
//         buffer.*.cursor +%= 1;
//     }
// }
// pub fn buffer_move_left(arg_buffer: *Buffer) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     if (buffer.*.cursor > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
//         buffer.*.cursor -%= 1;
//     }
// }
// pub fn skip_to_char(arg_buffer: *Buffer, arg_cur_pos: c_int, arg_direction: c_int, arg_c: u8) c_int {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var cur_pos = arg_cur_pos;
//     _ = &cur_pos;
//     var direction = arg_direction;
//     _ = &direction;
//     var c = arg_c;
//     _ = &c;
//     if (@as(c_int, @bitCast(@as(c_uint, (blk: {
//         const tmp = cur_pos;
//         if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     }).*))) == @as(c_int, @bitCast(@as(c_uint, c)))) {
//         cur_pos += direction;
//         while (((cur_pos > @as(c_int, 0)) and (cur_pos <= @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) and (@as(c_int, @bitCast(@as(c_uint, (blk: {
//             const tmp = cur_pos;
//             if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//         }).*))) != @as(c_int, @bitCast(@as(c_uint, c))))) {
//             if (((cur_pos > @as(c_int, 1)) and (cur_pos < @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) and (@as(c_int, @bitCast(@as(c_uint, (blk: {
//                 const tmp = cur_pos;
//                 if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//             }).*))) == @as(c_int, '\\'))) {
//                 cur_pos += direction;
//             }
//             cur_pos += direction;
//         }
//     }
//     return cur_pos;
// }
// pub fn buffer_next_brace(arg_buffer: *Buffer) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var cur_pos: c_int = @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.cursor))));
//     _ = &cur_pos;
//     var initial_brace: Brace = find_opposite_brace((blk: {
//         const tmp = cur_pos;
//         if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     }).*);
//     _ = &initial_brace;
//     var brace_stack: usize = 0;
//     _ = &brace_stack;
//     if (@as(c_int, @bitCast(@as(c_uint, initial_brace.brace))) == @as(c_int, '0')) return;
//     var direction: c_int = if (initial_brace.closing != 0) -@as(c_int, 1) else @as(c_int, 1);
//     _ = &direction;
//     while ((cur_pos >= @as(c_int, 0)) and (cur_pos <= @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) {
//         cur_pos += direction;
//         cur_pos = skip_to_char(buffer, cur_pos, direction, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '"'))))));
//         cur_pos = skip_to_char(buffer, cur_pos, direction, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\''))))));
//         var cur_brace: Brace = find_opposite_brace((blk: {
//             const tmp = cur_pos;
//             if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//         }).*);
//         _ = &cur_brace;
//         if (@as(c_int, @bitCast(@as(c_uint, cur_brace.brace))) == @as(c_int, '0')) continue;
//         if (((cur_brace.closing != 0) and (direction == -@as(c_int, 1))) or (!(cur_brace.closing != 0) and (direction == @as(c_int, 1)))) {
//             brace_stack +%= 1;
//         } else {
//             if (((blk: {
//                 const ref = &brace_stack;
//                 const tmp = ref.*;
//                 ref.* -%= 1;
//                 break :blk tmp;
//             }) == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, cur_brace.brace))) == @as(c_int, @bitCast(@as(c_uint, find_opposite_brace(initial_brace.brace).brace))))) {
//                 buffer.*.cursor = @as(usize, @bitCast(@as(c_long, cur_pos)));
//                 break;
//             }
//         }
//     }
// }
// pub fn isword(arg_ch: u8) c_int {
//     var ch = arg_ch;
//     _ = &ch;
//     if (((@as(c_int, @bitCast(@as(c_uint, (blk: {
//         const tmp = @as(c_int, @bitCast(@as(c_uint, ch)));
//         if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISalnum)))))))) != 0) or (@as(c_int, @bitCast(@as(c_uint, ch))) == @as(c_int, '_'))) return 1;
//     return 0;
// }
// pub fn buffer_create_indent(arg_buffer: *Buffer, arg_state: *State) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     if (state.*.config.indent > @as(c_int, 0)) {
//         {
//             var i: usize = 0;
//             _ = &i;
//             while (i < (@as(usize, @bitCast(@as(c_long, state.*.config.indent))) *% state.*.num_of_braces)) : (i +%= 1) {
//                 buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ' '))))));
//             }
//         }
//     } else {
//         {
//             var i: usize = 0;
//             _ = &i;
//             while (i < state.*.num_of_braces) : (i +%= 1) {
//                 buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\t'))))));
//             }
//         }
//     }
// }
// pub fn buffer_newline_indent(arg_buffer: *Buffer, arg_state: *State) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     var state = arg_state;
//     _ = &state;
//     buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\n'))))));
//     buffer_create_indent(buffer, state);
// }
//
// pub const wchar_t = c_int;
// pub const div_t = extern struct {
//     quot: c_int = @import("std").mem.zeroes(c_int),
//     rem: c_int = @import("std").mem.zeroes(c_int),
// };
// pub const ldiv_t = extern struct {
//     quot: c_long = @import("std").mem.zeroes(c_long),
//     rem: c_long = @import("std").mem.zeroes(c_long),
// };
// pub const lldiv_t = extern struct {
//     quot: c_longlong = @import("std").mem.zeroes(c_longlong),
//     rem: c_longlong = @import("std").mem.zeroes(c_longlong),
// };
// pub extern fn calloc(__nmemb: c_ulong, __size: c_ulong) ?*anyopaque;
// pub extern fn realloc(__ptr: ?*anyopaque, __size: c_ulong) ?*anyopaque;
// pub extern fn free(__ptr: ?*anyopaque) void;
// pub extern fn exit(__status: c_int) noreturn;
// pub extern fn memcpy(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
// pub extern fn memmove(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
// pub extern fn strncpy(__dest: *u8, __src: *const u8, __n: c_ulong) *u8;
// pub extern fn frontend_getch(window: *WINDOW) c_int;
// pub extern fn frontend_end() void;
// pub extern fn undo_push(state: *State, stack: *Undo_Stack, undo: Undo) void;
// pub extern fn find_opposite_brace(opening: u8) Brace;
// pub extern fn reset_command(command: *u8, command_s: *usize) void;
