// const root = @import("root");
// const std = root.std;
// const scu = root.scu;
// const thr = rot.thr;

// pub fn shift_str_left(arg_str: *u8, arg_str_s: *usize, arg_index_1: usize) void {
//     var str = arg_str;
//     _ = &str;
//     var str_s = arg_str_s;
//     _ = &str_s;
//     var index_1 = arg_index_1;
//     _ = &index_1;
//     {
//         var i: usize = index_1;
//         _ = &i;
//         while (i < str_s.*) : (i +%= 1) {
//             str[i] = str[i +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))];
//         }
//     }
//     str_s.* -%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
// }

// pub fn shift_str_right(arg_str: *u8, arg_str_s: *usize, arg_index_1: usize) void {
//     var str = arg_str;
//     _ = &str;
//     var str_s = arg_str_s;
//     _ = &str_s;
//     var index_1 = arg_index_1;
//     _ = &index_1;
//     str_s.* +%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
//     {
//         var i: usize = str_s.*;
//         _ = &i;
//         while (i > index_1) : (i -%= 1) {
//             str[i] = str[i -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))];
//         }
//     }
// }

// pub fn find_opposite_brace(arg_opening: u8) Brace {
//     var opening = arg_opening;
//     _ = &opening;
//     while (true) {
//         switch (@as(c_int, @bitCast(@as(c_uint, opening)))) {
//             @as(c_int, 40) => return Brace{
//                 .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ')'))))),
//                 .closing = @as(c_int, 0),
//             },
//             @as(c_int, 123) => return Brace{
//                 .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '}'))))),
//                 .closing = @as(c_int, 0),
//             },
//             @as(c_int, 91) => return Brace{
//                 .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ']'))))),
//                 .closing = @as(c_int, 0),
//             },
//             @as(c_int, 41) => return Brace{
//                 .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '('))))),
//                 .closing = @as(c_int, 1),
//             },
//             @as(c_int, 125) => return Brace{
//                 .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '{'))))),
//                 .closing = @as(c_int, 1),
//             },
//             @as(c_int, 93) => return Brace{
//                 .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '['))))),
//                 .closing = @as(c_int, 1),
//             },
//             else => return Brace{
//                 .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '0'))))),
//                 .closing = 0,
//             },
//         }
//         break;
//     }
//     return @import("std").mem.zeroes(Brace);
// }
