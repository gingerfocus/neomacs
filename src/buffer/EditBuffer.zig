const EditBuffer = @This();

const std = @import("std");
const root = @import("root");
const km = @import("../keymaps.zig");

const State = @import("../State.zig");

pub const Rows = std.ArrayListUnmanaged(Row);

pub const Row = struct {
    start: usize,
    end: usize,
};

/// Unique id of the buffer
id: u64,

/// literal data in the buffer
data: std.ArrayListUnmanaged(u8),
/// position in the data above
cursor: usize = 0,

/// Calculated from the above
rows: Rows,
/// Derived value from position
row: usize = 0,
/// Derived value from position
col: usize = 0,

filename: []const u8,
// visual: ?Visual = null,

// keyMaps: [Buffer.Mode.COUNT]km.KeyMaps,

// TODO: make a desired x and y
// when the y is change the desired x stays the same
// the col is set the to desired x or the most valid position

pub fn init(a: std.mem.Allocator, filename: []const u8) !EditBuffer {
    const file = try std.fs.cwd().openFile(filename, .{}); // a+
    defer file.close();

    var list = std.ArrayList(u8).init(a);
    defer list.deinit();
    try file.reader().readAllArrayList(&list, 128 * 1024 * 1024);

    // std.builtin.CallModifier
    // @call(.always_inline, Buffer.deinit, .{});
    const id = std.hash.murmur.Murmur2_64.hash(filename);

    var buffer = EditBuffer{
        .id = id,
        .filename = try a.dupe(u8, filename),
        .data = list.moveToUnmanaged(),
        .rows = .{},
    };
    try buffer.recalculateRows(a);

    return buffer;
}

pub fn deinit(buffer: *EditBuffer, a: std.mem.Allocator) void {
    buffer.data.deinit(a);
    buffer.rows.deinit(a);

    a.free(buffer.filename);
}

// pub const NO_ERROR: c_int = 0;
// pub const NOT_ENOUGH_ARGS: c_int = 1;
// pub const INVALID_ARGS: c_int = 2;
// pub const UNKNOWN_COMMAND: c_int = 3;
// pub const INVALID_IDENT: c_int = 4;
// pub const Command_Error = c_uint;

const Point = root.scu.thermit.Size;
const VisualMode = enum {
    Range,
    Line,
    Block,
};
pub const Visual = struct {
    start: Point,
    end: Point,
    mode: VisualMode,
};

// pub const Positions = extern struct {
//     data: *usize = @import("std").mem.zeroes(*usize),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
// };

// const Map = defs.Map;
// const Maps = defs.Maps;

pub fn recalculateRows(buffer: *EditBuffer, a: std.mem.Allocator) !void {
    buffer.rows.clearRetainingCapacity();

    var start: usize = 0;
    for (buffer.data.items, 0..) |ch, i| {
        if (i == buffer.cursor) {
            buffer.row = buffer.rows.items.len;
            buffer.col = i - start;
        }

        if (ch == '\n') {
            try buffer.rows.append(a, Row{ .start = start, .end = i });
            start = i + 1;
        }
    }
    try buffer.rows.append(a, Row{ .start = start, .end = buffer.data.items.len });
}

pub fn insertCharacter(buffer: *EditBuffer, a: std.mem.Allocator, ch: u8) !void {
    // if (buffer.cursor > buffer.data.items.len) {
    //     buffer.cursor = buffer.data.items.len;
    // }
    if (ch == '\n') {
        try buffer.newlineInsert(a);
        return;
    }

    if (buffer.cursor >= buffer.data.items.len) {
        try buffer.data.append(a, ch);
    } else {
        try buffer.data.insert(a, buffer.cursor, ch);
    }
    buffer.cursor += 1;

    // state.cur_undo.end = buffer.cursor;

    try buffer.recalculateRows(a);
    if (true) return;

    // PERF: time this to see if this is a real optimization, I think it is
    // beacuse it will be on debug as it has no error path but on release mode
    // it may be the same
    buffer.col += 1;
    for (buffer.rows.items) |*row| {
        // skip if you need
        if (row.end < buffer.cursor) continue;

        // add if you are not in it
        if (row.start >= buffer.cursor) row.start += 1;

        // always add after
        row.end += 1;
    }
}

pub fn buffer_delete_char(buffer: *EditBuffer, a: std.mem.Allocator) !void {
    std.debug.assert(buffer.cursor < buffer.data.items.len);

    // nothing to delete
    if (buffer.cursor == 0) return;

    buffer.cursor -= 1;

    var i: usize = buffer.cursor;
    while (i < buffer.data.items.len - 1) : (i += 1) {
        buffer.data.items[i] = buffer.data.items[i + 1];
    }
    // reduce capacity
    buffer.data.items.len -= 1;

    // recalculate
    try buffer.recalculateRows(a);
}

// pub fn buffer_delete_ch(buffer: *Buffer, state: *State) void {
//     _ = buffer; // autofix
//     _ = state; // autofix
//     var undo = Undo{ };
//     undo.type = .INSERT_CHARS;
//     undo.start = buffer.cursor;
//     state.cur_undo = undo;
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

// pub fn bufferGetRow(buffer: *const Buffer) usize {
//     // std.debug.assert(buffer.cursor <= buffer.data.items.len);
//
//     // there must be at least one line
//     std.debug.assert(buffer.rows.items.len >= 1);
//
//     for (buffer.rows.items, 0..) |row, i| {
//         if (row.start <= buffer.cursor and buffer.cursor <= row.end) {
//             return i;
//         }
//     }
//
//     return 0;
// }

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
//  }
//     _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% size])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), buffer.*.data.count -% buffer.*.cursor);
//     _ = strncpy(&buffer.*.data.data[buffer.*.cursor], selection.*.data, size);
//     buffer.*.data.count +%= size;
//     buffer_calculate_rows(buffer);
// }

pub fn moveRight(buffer: *EditBuffer, count: usize) void {
    buffer.cursor += count;
    buffer.updatePostionKeepPos();
}

pub fn moveLeft(buffer: *EditBuffer, count: usize) void {
    buffer.cursor = if (buffer.cursor < count) 0 else buffer.cursor - count;
    buffer.updatePostionKeepPos();
}

/// Moves the cursor to the best position it can using the current row as the
/// authoritive value
/// TODO: inline?
pub fn updatePostionKeepRow(buffer: *EditBuffer) void {
    if (buffer.row >= buffer.rows.items.len)
        buffer.row = buffer.rows.items.len - 1;

    const row = buffer.rows.items[buffer.row];
    if (buffer.col > row.end - row.start) {
        buffer.col = row.end - row.start;
        if (buffer.col > 0) buffer.col -= 1;
    }

    buffer.cursor = row.start + buffer.col;
}

/// Moves the cursor to the best position it can using the cursor position as
/// the authoritive value
/// TODO: inline?
pub fn updatePostionKeepPos(buffer: *EditBuffer) void {
    if (buffer.cursor >= buffer.data.items.len)
        buffer.cursor = buffer.data.items.len - 1;

    for (buffer.rows.items, 0..) |row, r| {
        if (row.start <= buffer.cursor and buffer.cursor <= row.end) {
            buffer.row = r;
            buffer.col = buffer.cursor - row.start;
            return;
        }
    } else unreachable;
}

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

pub fn newlineInsert(buffer: *EditBuffer, a: std.mem.Allocator) !void {
    try buffer.data.insert(a, buffer.cursor, '\n');
    try buffer.recalculateRows(a);
    // TODO: indent the curosr
}

// const ROPE_SPLIT_LENGTH = 128;
// const RopeString = struct {
//     data: []const u8,
//     indx: usize, // the start index of the string
//     left: ?*RopeString = null,
//     rigt: ?*RopeString = null,
// };
// fn ropeFromBuffer(a: std.mem.Allocator, buffer: []const u8) !RopeString {
//     _ = a; // autofix
//     var remaining = buffer;
//     var root = RopeString{
//         .data = "",
//         .indx = 0,
//     };
//     var curr = &root;
//
//     while (remaining.len > ROPE_SPLIT_LENGTH) {
//         curr.data = remaining[0..ROPE_SPLIT_LENGTH];
//     }
//     curr.data = remaining;
//     return root;
// }

pub fn makebuffer(self: *EditBuffer) root.Buffer {
    return root.Buffer{
        .dataptr = self,
        .vtable = &.{},
    };
}
