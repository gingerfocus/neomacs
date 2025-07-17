

// pub const UndoType = enum {
//     NONE,
//     INSERT_CHARS,
//     DELETE_CHAR,
//     DELETE_MULT_CHAR,
//     REPLACE_CHAR,
// };
// pub const Undo = struct {
//     type: UndoType = .NONE,
//     data: std.ArrayListUnmanaged(u8) = .{},
//     start: usize = 0,
//     end: usize = 0,
// };
// pub const Undo_Stack = std.ArrayList(Undo);
//
// pub const Files = std.ArrayListUnmanaged(File);
// pub const File = struct {
//     name: []const u8,
//     path: []const u8,
//     is_directory: bool,
// };
// pub const Brace = extern struct {
//     brace: u8 = @import("std").mem.zeroes(u8),
//     closing: c_int = @import("std").mem.zeroes(c_int),
// };
//
// #define CREATE_UNDO(t, p) do {    \
//     Undo undo = {0};         \
//     undo.type = (t);         \
//     undo.start = (p);        \
//     state->cur_undo = undo;   \
// } while(0)
//
// pub fn undo_push(arg_state: *State, arg_stack: *Undo_Stack, arg_undo: Undo) void {
//     var state = arg_state;
//     _ = &state;
//     var stack = arg_stack;
//     _ = &stack;
//     var undo = arg_undo;
//     _ = &undo;
//     while (true) {
//         if (stack.*.count >= stack.*.capacity) {
//             stack.*.capacity = if (stack.*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else stack.*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
//             var new: ?*anyopaque = calloc(stack.*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(Undo));
//             _ = &new;
//             while (true) {
//                 if (!(new != null)) {
//                     frontend_end();
//                     _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/tools.c", @as(c_int, 105));
//                     _ = fprintf(stderr, "outta ram");
//                     _ = fprintf(stderr, "\n");
//                     exit(@as(c_int, 1));
//                 }
//                 if (!false) break;
//             }
//             _ = memcpy(new, @as(?*const anyopaque, @ptrCast(stack.*.data)), stack.*.count);
//             free(@as(?*anyopaque, @ptrCast(stack.*.data)));
//             stack.*.data = @as(*Undo, @ptrCast(@alignCast(new)));
//         }
//         stack.*.data[
//             blk: {
//                 const ref = &stack.*.count;
//                 const tmp = ref.*;
//                 ref.* +%= 1;
//                 break :blk tmp;
//             }
//         ] = undo;
//         if (!false) break;
//     }
//     state.*.cur_undo = Undo{
//         .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//         .data = @import("std").mem.zeroes(Data),
//         .start = @import("std").mem.zeroes(usize),
//         .end = @import("std").mem.zeroes(usize),
//     };
// }
// pub fn undo_pop(arg_stack: *Undo_Stack) Undo {
//     var stack = arg_stack;
//     _ = &stack;
//     if (stack.*.count <= @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) return Undo{
//         .type = @as(c_uint, @bitCast(@as(c_int, 0))),
//         .data = @import("std").mem.zeroes(Data),
//         .start = @import("std").mem.zeroes(usize),
//         .end = @import("std").mem.zeroes(usize),
//     };
//     return stack.*.data[
//         blk: {
//             const ref = &stack.*.count;
//             ref.* -%= 1;
//             break :blk ref.*;
//         }
//     ];
// }

// pub fn buffer_handle_undo(arg_state: *State, _: km.KeyFunctionDataValue, arg_undo: *Undo) void {
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
