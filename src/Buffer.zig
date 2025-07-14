const root = @import("root.zig");
const std = root.std;
const lib = root.lib;
const km = root.km;

const State = root.State;

const Buffer = @This();

/// Unique id for this buffer, never changes once created
id: usize,

// File mode
// mode: ModeId = ModeId.Normal,

/// Motion keys have two ways in which they select text, a region and a
/// point. A motion can set this structure to not null to indicate what it
/// wants. Then a selector runs using this data. The default one just sets the
/// cursor to target position. Some other common ones are `d` which deletes
/// text in the selection. The can also be user defined.
target: ?Visual = null,

/// literal data in the buffer
lines: std.ArrayListUnmanaged(Line),

row: usize = 0,
col: usize = 0,

/// Row and Col in buffer
// cursor: lib.Vec2 = .{ .row = 0, .col = 0 },
// desired: lib.Vec2 = .{ .row = 0, .col = 0 },

filename: []const u8,

/// Not owned
/// TODO: do ref counting for this
keymaps: *km.ModeToKeys,

curkeymap: ?*km.KeyMaps = null,

pub fn getKeymap(buffer: *Buffer) *km.KeyMaps {
    return buffer.curkeymap orelse return buffer.keymaps.get(Buffer.ModeId.Normal).?;
}

pub fn setMode(buffer: *Buffer, mode: Buffer.ModeId) void {
    // buffer.mode = mode;
    buffer.curkeymap = buffer.keymaps.get(mode);
}

const Line = std.ArrayListUnmanaged(u8);

// pub const Mode = enum {
//     normal,
//     insert,
//     visual,
//
//     pub const COUNT = @typeInfo(Mode).@"enum".fields.len;
//
//     pub fn toString(self: Mode) []const u8 {
//         return switch (self) {
//             .normal => "NORMAL",
//             .insert => "INSERT",
//             .visual => "VISUAL",
//         };
//     }
// };

pub fn updateEnd(buffer: *Buffer, start: lib.Vec2, end: lib.Vec2) void {
    if (buffer.target) |*t| {
        // TODO: what do I do with start here?
        t.end = end;
    } else {
        buffer.target = .{
            .mode = .Range,
            .start = start,
            .end = end,
        };
    }
}
pub const Visual = struct {
    mode: VisualMode = .Range,
    start: lib.Vec2,
    end: lib.Vec2,
};
pub const VisualMode = enum {
    Range,
    Line,
    Block,
};

// keyMaps: [Buffer.Mode.COUNT]km.KeyMaps,

// pub fn edit(a: std.mem.Allocator, file: []const u8) !Buffer {
//     return .{
//         .id = id.next(),
//         .data = .{ .Edit = try Buffer.init(a, file) },
//         .mode = .normal,
//     };
// }

pub fn initEmpty(
    keymaps: *km.ModeToKeys,
) Buffer {
    return Buffer{
        .id = idgen.next(),
        .filename = "",
        .lines = .{},
        .keymaps = keymaps,
        // .keymap = state,
    };
}

pub fn initFile(
    a: std.mem.Allocator,
    keymaps: *km.ModeToKeys,
    filename: []const u8,
) !Buffer {
    // const maps = try state.maps.clone(state.a);

    var lines = std.ArrayList(Line).init(a);

    if (std.fs.cwd().openFile(filename, .{})) |file| {
        defer file.close();

        while (true) {
            const line = try file.reader().readUntilDelimiterOrEofAlloc(a, '\n', 128 * 1024) orelse break;
            // if (line.len == 0) break;

            const l = Line.fromOwnedSlice(line);

            try lines.append(l);
        }
    } else |_| {}

    // not stable
    // const fid = std.hash.murmur.Murmur2_64.hash(filename);

    return Buffer{
        .id = idgen.next(),
        .filename = try a.dupe(u8, filename),
        .lines = lines.moveToUnmanaged(),
        .keymaps = keymaps,
    };
}

pub fn deinit(buffer: *Buffer, a: std.mem.Allocator) void {
    for (buffer.lines.items) |*line| {
        line.deinit(a);
    }
    buffer.lines.deinit(a);

    a.free(buffer.filename);

    buffer.* = undefined;
}

pub fn position(buffer: *Buffer) lib.Vec2 {
    if (buffer.target) |t| return t.end;

    return .{
        .row = buffer.row,
        .col = buffer.col,
    };
}

pub fn insertCharacter(buffer: *Buffer, a: std.mem.Allocator, ch: u8) !void {
    if (ch == '\n') {
        try buffer.newlineInsert(a);
        return;
    }

    var line = &buffer.lines.items[buffer.row];
    try line.insert(a, buffer.col, ch);
    // root.log(@src(), .debug, "inserted character {c} at row {d}, col {d}", .{ ch, buffer.row, buffer.col });
    buffer.col += 1;

    // state.cur_undo.end = buffer.cursor;
}

pub fn bufferDelete(buffer: *Buffer, a: std.mem.Allocator) !void {
    if (buffer.col == 0 and buffer.row == 0) {
        // nothing to delete
        return;
    }

    if (buffer.col == 0) {
        // get the coluimn now before its length changes
        buffer.col = buffer.lines.items[buffer.row - 1].items.len;

        // delete the last character of the previous line
        const line = &buffer.lines.items[buffer.row];
        const prev = &buffer.lines.items[buffer.row - 1];
        try prev.appendSlice(a, line.items);

        var oldline = buffer.lines.orderedRemove(buffer.row);
        oldline.deinit(a);

        buffer.row -= 1;
    } else {
        // delete the character before the cursor
        buffer.col -= 1;

        var line = &buffer.lines.items[buffer.row];
        _ = line.orderedRemove(buffer.col);
    }
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

// pub fn bufferDeleteSelection(buffer: *EditBuffer, selection: Tar) !void {
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

/// Takes a point `start` and moves it right `count` units in the buffers space
pub fn moveRight(buffer: *Buffer, start: lib.Vec2, count: usize) lib.Vec2 {
    var end = start;

    var c = count;
    while (c > 0) {
        if (end.row >= buffer.lines.items.len) break;
        if (end.col + c >= buffer.lines.items[end.row].items.len) {
            c -= buffer.lines.items[end.row].items.len - end.col;
            if (end.row < buffer.lines.items.len - 1) {
                end.col = 0;
                end.row += 1;
            } else {
                // no where left to go
                end.col = buffer.lines.items[end.row].items.len - 1;
                break;
            }
        } else {
            end.col += c;
            c = 0;
        }
    }

    return end;
}

pub fn moveLeft(buffer: *Buffer, start: lib.Vec2, count: usize) lib.Vec2 {
    var end = start;

    var c = count;
    while (c > 0) {
        if (end.col >= c) {
            end.col -= c;
            c = 0;
        } else {
            c -= end.col + 1;
            if (end.row > 0) {
                end.row -= 1;
                end.col = buffer.lines.items[end.row].items.len;
            } else {
                end.col = 0; // can't go left anymore
                c = 0;
            }
        }
    }
    // buffer.desired = end;

    return end;
}

// pub fn skip_to_char(buffer: *EditBuffer, target: u8, right: bool, count: usize) c_int {
//     _ = right; // autofix
//     _ = buffer; // autofix
//     _ = target; // autofix
//     _ = count; // autofix
//     // if (@as(c_int, @bitCast(@as(c_uint, (blk: {
//     //     const tmp = cur_pos;
//     //     if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     // }).*))) == @as(c_int, @bitCast(@as(c_uint, c)))) {
//     //     cur_pos += direction;
//     //     while (((cur_pos > @as(c_int, 0)) and (cur_pos <= @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) and (@as(c_int, @bitCast(@as(c_uint, (blk: {
//     //         const tmp = cur_pos;
//     //         if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     //     }).*))) != @as(c_int, @bitCast(@as(c_uint, c))))) {
//     //         if (((cur_pos > @as(c_int, 1)) and (cur_pos < @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) and (@as(c_int, @bitCast(@as(c_uint, (blk: {
//     //             const tmp = cur_pos;
//     //             if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
//     //         }).*))) == @as(c_int, '\\'))) {
//     //             cur_pos += direction;
//     //         }
//     //         cur_pos += direction;
//     //     }
//     // }
//     // return cur_pos;
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

pub fn newlineInsert(buffer: *Buffer, a: std.mem.Allocator) !void {
    var line = &buffer.lines.items[buffer.row];

    const after = try a.dupe(u8, line.items[buffer.col..]);

    line.items.len = buffer.col;

    const nl = Line{ .items = after, .capacity = after.len };

    buffer.row += 1;
    buffer.col = 0;

    try buffer.lines.insert(a, buffer.row, nl);

    // TODO: indent the cursor
}

pub fn save(buffer: *Buffer) !void {
    const f = try std.fs.cwd().createFile(buffer.filename, .{});
    defer f.close();

    for (buffer.lines.items) |line| {
        try f.writeAll(line.items);
        try f.writer().writeByte('\n');
    }
}

/// using static for id assignment
const idgen = struct {
    var count: usize = 0;
    fn next() usize {
        count += 1;
        return count;
    }
};

// const Target = struct {
//     down: ?isize = null,
//     left: ?isize = null,
// };

pub const ModeId = struct {
    _: usize,

    pub fn from(str: []const u8) ModeId {
        var bytes: usize = 0;
        @memcpy(std.mem.asBytes(&bytes)[0..str.len], str);

        return .{ ._ = bytes };
    }

    pub const new = @compileError("TODO: walk the states maps and find the next a tag greater than 65535");

    pub fn toString(self: ModeId) []const u8 {
        return switch (self._) {
            0 => "NULL",
            'n' => "NORMAL",
            'i' => "INSERT",
            'v' => "VISUAL",
            else => "UNKNOWN",
        };
    }

    // const static = struct {
    //     const id: usize = 65535;
    // };

    pub const Null: ModeId = .{ ._ = 0 };
    pub const Normal: ModeId = .{ ._ = 'n' };
    pub const Visual: ModeId = .{ ._ = 'v' };
    pub const Insert: ModeId = .{ ._ = 'i' };

    test "MapId.from" {
        // I would be interested to see if these work on little endian machines
        try std.testing.expectEqual(ModeId.Normal, ModeId.from("n"));
        try std.testing.expectEqual(ModeId.Visual, ModeId.from("v"));
        try std.testing.expectEqual(ModeId.Insert, ModeId.from("i"));
    }

    test "ModeId comptime" {
        try std.testing.expectEqualStrings("NORMAL", comptime ModeId.from("n").toString());
        try std.testing.expectEqualStrings("VISUAL", comptime ModeId.from("v").toString());
        try std.testing.expectEqualStrings("INSERT", comptime ModeId.from("i").toString());

        try std.testing.expectEqualStrings("UNKNOWN", comptime ModeId.from("x").toString());
    }
};
