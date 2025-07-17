

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
