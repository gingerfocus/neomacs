const std = @import("std");
const defs = @import("defs.zig");
const vw = @import("view.zig");
const bf = @import("buffer.zig");
const root = @import("root");
const clr = @import("colors.h.zig");
const cmmd = @import("commands.zig");

const scu = @import("scured");
const tr = scu.thermit;

const State = defs.State;
// pub const __dev_t = c_ulong;
// pub const __uid_t = c_uint;
// pub const __gid_t = c_uint;
// pub const __ino_t = c_ulong;
pub const __mode_t = c_uint;
// pub const __nlink_t = c_ulong;
// pub const __off_t = c_long;
// pub const __off64_t = c_long;
// pub const __time_t = c_long;
// pub const __blksize_t = c_long;
// pub const __blkcnt_t = c_long;
// pub const __syscall_slong_t = c_long;
// const struct_dirent = root.struct_dirent;
pub const DT_DIR: c_int = 4;
pub const DT_REG: c_int = 8;
pub const struct___dirstream = opaque {};
pub const DIR = struct___dirstream;
pub extern fn closedir(__dirp: ?*DIR) c_int;
pub extern fn opendir(__name: *const u8) ?*DIR;
// pub extern fn readdir(__dirp: ?*DIR) *struct_dirent;
const struct_stat = root.struct_stat;
const stat = root.stat;
const mkdir = root.mkdir;

pub extern var stderr: *FILE;
pub extern fn fclose(__stream: *FILE) c_int;
pub extern fn fopen(__filename: *const u8, __modes: *const u8) *FILE;
pub extern fn fprintf(__stream: *FILE, __format: *const u8, ...) c_int;
pub extern fn sprintf(__s: *u8, __format: *const u8, ...) c_int;
pub extern fn asprintf(noalias __ptr: **u8, noalias __fmt: *const u8, ...) c_int;
pub extern fn fgets(noalias __s: *u8, __n: c_int, noalias __stream: *FILE) *u8;
pub extern fn fread(__ptr: ?*anyopaque, __size: c_ulong, __n: c_ulong, __stream: *FILE) c_ulong;
pub extern fn fwrite(__ptr: ?*const anyopaque, __size: c_ulong, __n: c_ulong, __s: *FILE) c_ulong;
pub extern fn fseek(__stream: *FILE, __off: c_long, __whence: c_int) c_int;
pub extern fn ftell(__stream: *FILE) c_long;
pub extern fn pclose(__stream: *FILE) c_int;
pub extern fn popen(__command: *const u8, __modes: *const u8) *FILE;
pub extern fn init_color(c_short, c_short, c_short, c_short) c_int;
pub extern fn init_pair(c_short, c_short, c_short) c_int;

const WINDOW = defs.WINDOW;
pub extern fn wrefresh(*WINDOW) c_int;
pub extern var stdscr: *WINDOW;

// pub const NORMAL: c_int = 0;
// pub const INSERT: c_int = 1;
// pub const SEARCH: c_int = 2;
// pub const COMMAND: c_int = 3;
// pub const VISUAL: c_int = 4;
// pub const MODE_COUNT: c_int = 5;
// pub const Mode = c_uint;
// pub const LEADER_NONE: c_int = 0;
// pub const LEADER_R: c_int = 1;
// pub const LEADER_D: c_int = 2;
// pub const LEADER_Y: c_int = 3;
// pub const LEADER_COUNT: c_int = 4;
// pub const Leader = c_uint;
// pub const NONE: c_int = 0;
// pub const INSERT_CHARS: c_int = 1;
// pub const DELETE_CHAR: c_int = 2;
// pub const DELETE_MULT_CHAR: c_int = 3;
// pub const REPLACE_CHAR: c_int = 4;
// pub const Undo_Type = c_uint;
// pub const NO_ERROR: c_int = 0;
// pub const NOT_ENOUGH_ARGS: c_int = 1;
// pub const INVALID_ARGS: c_int = 2;
// pub const UNKNOWN_COMMAND: c_int = 3;
// pub const INVALID_IDENT: c_int = 4;
// pub const Command_Error = c_uint;
const ThreadArgs = defs.ThreadArgs;
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
//
//
// pub const VAR_INT: c_int = 0;
// pub const VAR_FLOAT: c_int = 1;
// pub const VAR_PTR: c_int = 2;
// pub const Var_Type = c_uint;
// // pub const Variable = extern struct {
// //     name: *u8 = @import("std").mem.zeroes(*u8),
// //     value: Var_Value = @import("std").mem.zeroes(Var_Value),
// //     type: Var_Type = @import("std").mem.zeroes(Var_Type),
// // };
// // pub const Variables = extern struct {
// //     data: *Variable = @import("std").mem.zeroes(*Variable),
// //     count: usize = @import("std").mem.zeroes(usize),
// //     capacity: usize = @import("std").mem.zeroes(usize),
// // };
//
const Brace = defs.Brace;
const Ncurses_Color = defs.Ncurses_Color;
// pub const Syntax_Highlighting = extern struct {
//     row: usize = @import("std").mem.zeroes(usize),
//     col: usize = @import("std").mem.zeroes(usize),
//     size: usize = @import("std").mem.zeroes(usize),
// };
// pub extern var string_modes: [5]*u8;
//
// pub const ptrdiff_t = c_long;
// pub const wchar_t = c_int;
// pub const max_align_t = extern struct {
//     __clang_max_align_nonce1: c_longlong align(8) = @import("std").mem.zeroes(c_longlong),
//     __clang_max_align_nonce2: c_longdouble align(16) = @import("std").mem.zeroes(c_longdouble),
// };
// pub extern fn frontend_init(state: *State) void;
// pub extern fn state_render(state: *State) void;
// pub extern fn frontend_resize_window(state: *State) void;
// pub extern fn frontend_getch(window: *WINDOW) c_int;
// pub extern fn frontend_move_cursor(window: *WINDOW, pos_x: usize, pos_y: usize) void;
// pub extern fn frontend_cursor_visible(value: c_int) void;
pub extern fn frontend_end() void;
// pub const TT_SET_VAR: c_int = 0;
// pub const TT_SET_OUTPUT: c_int = 1;
// pub const TT_SET_MAP: c_int = 2;
// pub const TT_LET: c_int = 3;
// pub const TT_PLUS: c_int = 4;
// pub const TT_MINUS: c_int = 5;
// pub const TT_MULT: c_int = 6;
// pub const TT_DIV: c_int = 7;
// pub const TT_ECHO: c_int = 8;
// pub const TT_SAVE: c_int = 9;
// pub const TT_EXIT: c_int = 10;
// pub const TT_SAVE_EXIT: c_int = 11;
// pub const TT_IDENT: c_int = 12;
// pub const TT_SPECIAL_CHAR: c_int = 13;
// pub const TT_STRING: c_int = 14;
// pub const TT_CONFIG_IDENT: c_int = 15;
// pub const TT_INT_LIT: c_int = 16;
// pub const TT_FLOAT_LIT: c_int = 17;
// pub const TT_COUNT: c_int = 18;
// pub const Command_Type = c_uint;

const Command_Token = cmmd.Command_Token;
// pub const Identifier = extern struct {
//     name: String_View = @import("std").mem.zeroes(String_View),
//     value: c_int = @import("std").mem.zeroes(c_int),
// };
// pub const Str_Literal = extern struct {
//     value: String_View = @import("std").mem.zeroes(String_View),
// };
// pub const Expr = extern struct {
//     value: c_int = @import("std").mem.zeroes(c_int),
// };
// pub const OP_NONE: c_int = 0;
// pub const OP_PLUS: c_int = 1;
// pub const OP_MINUS: c_int = 2;
// pub const OP_MULT: c_int = 3;
// pub const OP_DIV: c_int = 4;
// pub const Operator = c_uint;
// pub const struct_Bin_Expr = extern struct {
//     lvalue: Expr = @import("std").mem.zeroes(Expr),
//     right: *struct_Bin_Expr = @import("std").mem.zeroes(*struct_Bin_Expr),
//     rvalue: Expr = @import("std").mem.zeroes(Expr),
//     operator: Operator = @import("std").mem.zeroes(Operator),
// };
// pub const Bin_Expr = struct_Bin_Expr;
//
//
// pub const Node_Val = extern union {
//     as_expr: Expr,
//     as_bin: Bin_Expr,
//     as_keyword: Command_Type,
//     as_str: Str_Literal,
//     as_ident: Identifier,
//     as_config: *Config_Vars,
//     as_int: c_int,
// };
//
// pub const NODE_EXPR: c_int = 0;
// pub const NODE_BIN: c_int = 1;
// pub const NODE_KEYWORD: c_int = 2;
// pub const NODE_STR: c_int = 3;
// pub const NODE_IDENT: c_int = 4;
// pub const NODE_CONFIG: c_int = 5;
// pub const NODE_INT: c_int = 6;
// pub const Node_Type = c_uint;
// pub const struct_Node = extern struct {
//     value: Node_Val = @import("std").mem.zeroes(Node_Val),
//     type: Node_Type = @import("std").mem.zeroes(Node_Type),
//     left: *struct_Node = @import("std").mem.zeroes(*struct_Node),
//     right: *struct_Node = @import("std").mem.zeroes(*struct_Node),
// };
// pub const Node = struct_Node;
// pub const Ctrl_Key = extern struct {
//     name: *u8 = @import("std").mem.zeroes(*u8),
//     value: c_int = @import("std").mem.zeroes(c_int),
// };
// pub extern fn get_token_type(state: *State, view: String_View) Command_Type;
// pub extern fn create_token(state: *State, command: String_View) Command_Token;
const String_View = defs.String_View;
pub extern fn lex_command(state: *State, command: String_View, token_s: *usize) *Command_Token;
// pub extern fn print_token(token: Command_Token) void;
// pub extern fn expect_token(state: *State, token: Command_Token, @"type": Command_Type) c_int;
// pub extern fn create_node(@"type": Node_Type, value: Node_Val) *Node;
// pub extern fn get_operator(token: Command_Token) Operator;
// pub extern fn get_special_char(view: String_View) c_int;
// pub extern fn parse_bin_expr(state: *State, command: *Command_Token, command_s: usize) *Bin_Expr;
// pub extern fn parse_command(state: *State, command: *Command_Token, command_s: usize) *Node;
// pub extern fn interpret_expr(expr: *Bin_Expr) c_int;
// pub extern fn interpret_command(buffer: *Buffer, state: *State, root: *Node) void;
// pub extern fn print_tree(node: *Node, depth: usize) void;
pub extern fn execute_command(buffer: *Buffer, state: *State, command: *Command_Token, command_s: usize) c_int;
//
// const clr = @import("colors.h.zig");
//
// // pub const YELLOW_COLOR: c_int = 1;
// // pub const BLUE_COLOR: c_int = 2;
// // pub const GREEN_COLOR: c_int = 3;
// // pub const RED_COLOR: c_int = 4;
// // pub const CYAN_COLOR: c_int = 5;
// // pub const MAGENTA_COLOR: c_int = 6;
// // pub const Color_Pairs = c_uint;
// // pub const Custom_Color = extern struct {
// //     custom_slot: Color_Pairs = @import("std").mem.zeroes(Color_Pairs),
// //     custom_id: c_int = @import("std").mem.zeroes(c_int),
// //     custom_r: c_int = @import("std").mem.zeroes(c_int),
// //     custom_g: c_int = @import("std").mem.zeroes(c_int),
// //     custom_b: c_int = @import("std").mem.zeroes(c_int),
// // };
// // pub const Color_Arr = extern struct {
// //     arr: *Custom_Color = @import("std").mem.zeroes(*Custom_Color),
// //     arr_s: usize = @import("std").mem.zeroes(usize),
// // };
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
// pub extern fn __ctype_get_mb_cur_max() usize;
// pub extern fn atof(__nptr: *const u8) f64;
// pub extern fn atoi(__nptr: *const u8) c_int;
// pub extern fn atol(__nptr: *const u8) c_long;
// pub extern fn atoll(__nptr: *const u8) c_longlong;
// pub extern fn strtod(__nptr: *const u8, __endptr: **u8) f64;
// pub extern fn strtof(__nptr: *const u8, __endptr: **u8) f32;
// pub extern fn strtold(__nptr: *const u8, __endptr: **u8) c_longdouble;
// pub extern fn strtol(__nptr: *const u8, __endptr: **u8, __base: c_int) c_long;
// pub extern fn strtoul(__nptr: *const u8, __endptr: **u8, __base: c_int) c_ulong;
// pub extern fn strtoq(noalias __nptr: *const u8, noalias __endptr: **u8, __base: c_int) c_longlong;
// pub extern fn strtouq(noalias __nptr: *const u8, noalias __endptr: **u8, __base: c_int) c_ulonglong;
// pub extern fn strtoll(__nptr: *const u8, __endptr: **u8, __base: c_int) c_longlong;
// pub extern fn strtoull(__nptr: *const u8, __endptr: **u8, __base: c_int) c_ulonglong;
// pub extern fn l64a(__n: c_long) *u8;
// pub extern fn a64l(__s: *const u8) c_long;
pub extern fn malloc(__size: c_ulong) ?*anyopaque;
pub extern fn calloc(__nmemb: c_ulong, __size: c_ulong) ?*anyopaque;
pub extern fn realloc(__ptr: ?*anyopaque, __size: c_ulong) ?*anyopaque;
pub extern fn free(__ptr: ?*anyopaque) void;
pub extern fn exit(__status: c_int) noreturn;
pub extern fn getenv(__name: [*c]const u8) *u8;
pub extern fn system(__command: [*c]const u8) c_int;

pub extern fn memcpy(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
pub extern fn memset(__s: ?*anyopaque, __c: c_int, __n: c_ulong) ?*anyopaque;
pub extern fn strcpy(__dest: *u8, __src: *const u8) *u8;
pub extern fn strncpy(__dest: *u8, __src: *const u8, __n: c_ulong) *u8;
pub extern fn strcat(__dest: *u8, __src: *const u8) *u8;
pub extern fn strcmp(__s1: *const u8, __s2: *const u8) c_int;
pub extern fn strcoll(__s1: *const u8, __s2: *const u8) c_int;
pub extern fn strlen(__s: *const u8) c_ulong;
//
// pub const Type_None: c_int = 0;
// pub const Type_Keyword: c_int = 1;
// pub const Type_Type: c_int = 2;
// pub const Type_Preprocessor: c_int = 3;
// pub const Type_String: c_int = 4;
// pub const Type_Comment: c_int = 5;
// pub const Type_Word: c_int = 6;
// pub const Token_Type = c_uint;
// pub const Token = extern struct {
//     type: Token_Type = @import("std").mem.zeroes(Token_Type),
//     index: usize = @import("std").mem.zeroes(usize),
//     size: usize = @import("std").mem.zeroes(usize),
// };
// const String_View = vw.String_View;
// pub extern fn is_keyword(word: *u8, word_s: usize) c_int;
// pub extern fn is_type(word: *u8, word_s: usize) c_int;
pub extern fn strip_off_dot(str: *u8, str_s: usize) *u8;
// pub extern fn read_file_to_str(filename: *u8, contents: **u8) usize;
pub extern fn parse_syntax_file(filename: *u8) clr.Color_Arr;
// pub extern fn is_in_tokens_index(token_arr: *Token, token_s: usize, index: usize, size: *usize, color: *clr.Color_Pairs) c_int;
// pub extern fn generate_word(view: *String_View, contents: *u8) Token;
// pub extern fn generate_tokens(line: *u8, line_s: usize, token_arr: *Token, token_arr_capacity: *usize) usize;
pub extern fn read_file_by_lines(filename: *u8, lines: ***u8, lines_s: *usize) c_int;

const Config_Vars = defs.Config_Vars;
const File = defs.File;
const Files = defs.Files;
pub const Config = defs.Config;
const Buffer = defs.Buffer;
const FILE = defs.FILE;
const Undo_Stack = defs.Undo_Stack;
const Undo = defs.Undo;
const Data = defs.Data;
const Arg = defs.Arg;
const Sized_Str = defs.Sized_Str;
const Maps = defs.Maps;

pub fn dynstr_to_data(str: Sized_Str) Data {
    return Data.fromOwnedSlice(std.heap.c_allocator, str);
}

pub fn handleCursorShape(state: *State) !void {
    try tr.setCursorStyle(state.term.tty.f.writer(), switch (state.config.mode) {
        .INSERT => .SteadyBar,
        else => .SteadyBlock,
    });
    // TODO: refreash screen
}

// pub fn free_buffer(arg_buffer: *Buffer) void {
//     var buffer = arg_buffer;
//     _ = &buffer;
//     free(@as(?*anyopaque, @ptrCast(buffer.*.data.data)));
//     free(@as(?*anyopaque, @ptrCast(buffer.*.rows.data)));
//     free(@as(?*anyopaque, @ptrCast(buffer.*.filename)));
//     buffer.*.data.count = 0;
//     buffer.*.rows.count = 0;
//     buffer.*.data.capacity = 0;
//     buffer.*.rows.capacity = 0;
// }

pub fn free_undo(arg_undo: *Undo) void {
    var undo = arg_undo;
    _ = &undo;
    free(@as(?*anyopaque, @ptrCast(undo.*.data.data)));
}

pub fn free_undo_stack(arg_undo: *Undo_Stack) void {
    var undo = arg_undo;
    _ = &undo;
    {
        var i: usize = 0;
        _ = &i;
        while (i < undo.*.count) : (i +%= 1) {
            free_undo(&undo.*.data[i]);
        }
    }
    free(@as(?*anyopaque, @ptrCast(undo.*.data)));
}

pub fn handle_save(arg_buffer: *Buffer) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var file: *FILE = fopen(buffer.*.filename, "w");
    _ = &file;
    _ = fwrite(@as(?*const anyopaque, @ptrCast(buffer.*.data.data)), buffer.*.data.count, @sizeOf(u8), file);
    _ = fclose(file);
}

pub fn loadBufferFromFile(a: std.mem.Allocator, filename: []const u8) !*Buffer {
    const file = try std.fs.cwd().openFile(filename, .{}); // a+
    defer file.close();

    var list = std.ArrayList(u8).init(a);
    defer list.deinit();
    try file.reader().readAllArrayList(&list, 128 * 1024 * 1024);

    const buffer = try a.create(Buffer);
    buffer.* = .{
        .filename = try a.dupe(u8, filename),
        .data = list.moveToUnmanaged(),
        .rows = .{},
    };
    try bf.buffer_calculate_rows(a, buffer);

    return buffer;
}

pub fn shift_str_left(arg_str: *u8, arg_str_s: *usize, arg_index_1: usize) void {
    var str = arg_str;
    _ = &str;
    var str_s = arg_str_s;
    _ = &str_s;
    var index_1 = arg_index_1;
    _ = &index_1;
    {
        var i: usize = index_1;
        _ = &i;
        while (i < str_s.*) : (i +%= 1) {
            str[i] = str[i +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))];
        }
    }
    str_s.* -%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
}
pub fn shift_str_right(arg_str: *u8, arg_str_s: *usize, arg_index_1: usize) void {
    var str = arg_str;
    _ = &str;
    var str_s = arg_str_s;
    _ = &str_s;
    var index_1 = arg_index_1;
    _ = &index_1;
    str_s.* +%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    {
        var i: usize = str_s.*;
        _ = &i;
        while (i > index_1) : (i -%= 1) {
            str[i] = str[i -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))];
        }
    }
}
pub fn undo_push(arg_state: *State, arg_stack: *Undo_Stack, arg_undo: Undo) void {
    var state = arg_state;
    _ = &state;
    var stack = arg_stack;
    _ = &stack;
    var undo = arg_undo;
    _ = &undo;
    while (true) {
        if (stack.*.count >= stack.*.capacity) {
            stack.*.capacity = if (stack.*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else stack.*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
            var new: ?*anyopaque = calloc(stack.*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(Undo));
            _ = &new;
            while (true) {
                if (!(new != null)) {
                    frontend_end();
                    _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/tools.c", @as(c_int, 105));
                    _ = fprintf(stderr, "outta ram");
                    _ = fprintf(stderr, "\n");
                    exit(@as(c_int, 1));
                }
                if (!false) break;
            }
            _ = memcpy(new, @as(?*const anyopaque, @ptrCast(stack.*.data)), stack.*.count);
            free(@as(?*anyopaque, @ptrCast(stack.*.data)));
            stack.*.data = @as(*Undo, @ptrCast(@alignCast(new)));
        }
        stack.*.data[
            blk: {
                const ref = &stack.*.count;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            }
        ] = undo;
        if (!false) break;
    }
    state.*.cur_undo = Undo{
        .type = @as(c_uint, @bitCast(@as(c_int, 0))),
        .data = @import("std").mem.zeroes(Data),
        .start = @import("std").mem.zeroes(usize),
        .end = @import("std").mem.zeroes(usize),
    };
}
pub fn undo_pop(arg_stack: *Undo_Stack) Undo {
    var stack = arg_stack;
    _ = &stack;
    if (stack.*.count <= @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) return Undo{
        .type = @as(c_uint, @bitCast(@as(c_int, 0))),
        .data = @import("std").mem.zeroes(Data),
        .start = @import("std").mem.zeroes(usize),
        .end = @import("std").mem.zeroes(usize),
    };
    return stack.*.data[
        blk: {
            const ref = &stack.*.count;
            ref.* -%= 1;
            break :blk ref.*;
        }
    ];
}
pub fn find_opposite_brace(arg_opening: u8) Brace {
    var opening = arg_opening;
    _ = &opening;
    while (true) {
        switch (@as(c_int, @bitCast(@as(c_uint, opening)))) {
            @as(c_int, 40) => return Brace{
                .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ')'))))),
                .closing = @as(c_int, 0),
            },
            @as(c_int, 123) => return Brace{
                .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '}'))))),
                .closing = @as(c_int, 0),
            },
            @as(c_int, 91) => return Brace{
                .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ']'))))),
                .closing = @as(c_int, 0),
            },
            @as(c_int, 41) => return Brace{
                .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '('))))),
                .closing = @as(c_int, 1),
            },
            @as(c_int, 125) => return Brace{
                .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '{'))))),
                .closing = @as(c_int, 1),
            },
            @as(c_int, 93) => return Brace{
                .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '['))))),
                .closing = @as(c_int, 1),
            },
            else => return Brace{
                .brace = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '0'))))),
                .closing = 0,
            },
        }
        break;
    }
    return @import("std").mem.zeroes(Brace);
}

/// Looks through config defined key maps and runs the relevant ones
pub fn check_keymaps(buffer: *Buffer, state: *State) bool {
    _ = buffer; // autofix

    for (state.config.key_maps.items) |key_map| {
        if (state.ch.character.b() == key_map.a) {
            // var j: usize = 0;
            // while (j < key_map.b_s) : (j += 1) {
            //     state.*.ch = @as(c_int, @bitCast(@as(c_uint, state.*.config.key_maps.data[i].b[j])));
            //     state.key_func[state.*.config.mode](buffer, &buffer, state);
            // }
            return true;
        }
    }
    return false;
}

fn compareName(ctx: void, leftp: File, rightp: File) bool {
    _ = ctx;
    return std.mem.lessThan(u8, leftp.name, rightp.name);
}

pub fn scanFiles(state: *State, directory: []const u8) !void {
    var dp = try std.fs.cwd().openDir(directory, .{ .iterate = true });
    defer dp.close();

    var iter = dp.iterate();
    while (try iter.next()) |dent| {
        if (std.mem.eql(u8, dent.name, ".")) continue;
        const path = try std.fmt.allocPrint(state.a, "{s}/{s}", .{ directory, dent.name });
        switch (dent.kind) {
            .directory => {
                const name = try std.fmt.allocPrint(state.a, "{s}/", .{dent.name});
                try state.files.append(state.a, File{ .name = name, .path = path, .is_directory = true });
            },
            .file => {
                const name = try state.a.dupe(u8, dent.name);
                try state.files.append(state.a, File{ .name = name, .path = path, .is_directory = false });
            },
            else => {
                std.log.warn("Unknown file ({s}) type: {}", .{ path, dent.kind });
                state.a.free(path);
            },
        }
    }
    std.mem.sort(File, state.files.items, {}, compareName);
}

// pub fn free_files(arg_files: **Files) void {
//     var files = arg_files;
//     _ = &files;
//     {
//         var i: usize = 0;
//         _ = &i;
//         while (i < files.*.*.count) : (i +%= 1) {
//             free(@as(?*anyopaque, @ptrCast(files.*.*.data[i].name)));
//             free(@as(?*anyopaque, @ptrCast(files.*.*.data[i].path)));
//         }
//     }
//     free(@as(?*anyopaque, @ptrCast(files.*.*.data)));
//     free(@as(?*anyopaque, @ptrCast(files.*)));
// }

pub fn load_config_from_file(state: *State, buffer: *Buffer, config_file: ?[*:0]const u8, syntax_filename: ?[*:0]u8) void {
    _ = buffer; // autofix
    _ = syntax_filename; // autofix
    _ = state; // autofix
    _ = config_file; // autofix
    // var config_dir: *u8 = undefined;
    // _ = &config_dir;
    //
    // const config_filename = config_file orelse {
    //     if (state.*.env == @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
    //         var env: *u8 = getenv("HOME");
    //         _ = &env;
    //         if (env == @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) while (true) {
    //             frontend_end();
    //             _ = fprintf(stderr, "could not get HOME\n");
    //             exit(@as(c_int, 1));
    //             if (!false) break;
    //         };
    //         state.*.env = env;
    //     }
    //     std.fmt.allocPrint()
    //     _ = asprintf(&config_dir, "%s/.config/cano", state.*.env);
    //     var st: struct_stat = undefined;
    //     _ = &st;
    //     if (stat(config_dir, &st) == -@as(c_int, 1)) {
    //         _ = mkdir(config_dir, @as(__mode_t, @bitCast(@as(c_int, 493))));
    //     }
    //     if (!((st.st_mode & @as(__mode_t, @bitCast(@as(c_int, 61440)))) == @as(__mode_t, @bitCast(@as(c_int, 16384))))) while (true) {
    //         frontend_end();
    //         _ = fprintf(stderr, "a file conflict with the config directory.\n");
    //         exit(@as(c_int, 1));
    //         if (!false) break;
    //     };
    //     _ = asprintf(&config_filename, "%s/config.cano", config_dir);
    //     var language: *u8 = strip_off_dot(buffer.*.filename, strlen(buffer.*.filename));
    //     _ = &language;
    //     if (language != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
    //         _ = asprintf(&syntax_filename, "%s/%s.cyntax", config_dir, language);
    //         free(@as(?*anyopaque, @ptrCast(language)));
    //     }
    // }
    //
    // var lines: **u8 = @as(**u8, @ptrCast(@alignCast(calloc(@as(c_ulong, @bitCast(@as(c_long, @as(c_int, 2)))), @sizeOf(*u8)))));
    // _ = &lines;
    // var lines_s: usize = 0;
    // _ = &lines_s;
    // var err: c_int = read_file_by_lines(config_filename, &lines, &lines_s);
    // _ = &err;
    // if (err == @as(c_int, 0)) {
    //     {
    //         var i: usize = 0;
    //         _ = &i;
    //         while (i < lines_s) : (i +%= 1) {
    //             var cmd_s: usize = 0;
    //             _ = &cmd_s;
    //             var cmd: *Command_Token = lex_command(state, vw.view_create(lines[i], strlen(lines[i])), &cmd_s);
    //             _ = &cmd;
    //             _ = execute_command(buffer, state, cmd, cmd_s);
    //             free(@as(?*anyopaque, @ptrCast(lines[i])));
    //         }
    //     }
    // }
    // free(@as(?*anyopaque, @ptrCast(lines)));
    // if (syntax_filename != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
    //     var color_arr: clr.Color_Arr = parse_syntax_file(syntax_filename);
    //     _ = &color_arr;
    //     if (color_arr.arr != @as(*clr.Custom_Color, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
    //         {
    //             var i: usize = 0;
    //             _ = &i;
    //             while (i < color_arr.arr_s) : (i +%= 1) {
    //                 _ = init_pair(@as(c_short, @bitCast(@as(c_ushort, @truncate(color_arr.arr[i].custom_slot)))), @as(c_short, @bitCast(@as(c_short, @truncate(color_arr.arr[i].custom_id)))), @as(c_short, @bitCast(@as(c_short, @truncate(state.*.config.background_color)))));
    //                 init_ncurses_color(color_arr.arr[i].custom_id, color_arr.arr[i].custom_r, color_arr.arr[i].custom_g, color_arr.arr[i].custom_b);
    //             }
    //         }
    //         free(@as(?*anyopaque, @ptrCast(color_arr.arr)));
    //     }
    // }
}

// pub fn contains_c_extension(str: [*:0]const u8) c_int {
//     const extension: [*:0]const u8 = ".c";
//
//     const str_len = std.mem.span(str).len;
//
//     var extension_len: usize = strlen(extension);
//     _ = &extension_len;
//     if (str_len >= extension_len) {
//         var suffix: *const u8 = str + (str_len -% extension_len);
//         _ = &suffix;
//         if (strcmp(suffix, extension) == @as(c_int, 0)) {
//             return 1;
//         }
//     }
//     return 0;
// }

pub fn check_for_errors(arg_args: ?*anyopaque) ?*anyopaque {
    var args = arg_args;
    _ = &args;
    var threadArgs: *ThreadArgs = @as(*ThreadArgs, @ptrCast(@alignCast(args)));
    _ = &threadArgs;
    var loop: bool = @as(c_int, 1) != 0;
    _ = &loop;
    while (loop) {
        var path: [1035]u8 = undefined;
        _ = &path;
        var command: [1024]u8 = undefined;
        _ = &command;
        _ = sprintf(@as(*u8, @ptrCast(@alignCast(&command))), "gcc %s -o /dev/null -Wall -Wextra -Werror -std=c99 2> errors.cano && echo $? > success.cano", threadArgs.*.path_to_file);
        var fp: *FILE = popen(@as(*u8, @ptrCast(@alignCast(&command))), "r");
        _ = &fp;
        if (fp == @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
            loop = @as(c_int, 0) != 0;
            const return_message = struct {
                var static: [21:0]u8 = "Failed to run command".*;
            };
            _ = &return_message;
            while (true) {
                var file: *FILE = fopen("logs/cano.log", "a");
                _ = &file;
                if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                    _ = fprintf(file, "%s:%d: Failed to run command\n", "src/tools.c", @as(c_int, 285));
                    _ = fclose(file);
                }
                if (!false) break;
            }
            return @as(?*anyopaque, @ptrCast(@as(*u8, @ptrCast(@alignCast(&return_message.static)))));
        }
        _ = pclose(fp);
        var should_check_for_errors: *FILE = fopen("success.cano", "r");
        _ = &should_check_for_errors;
        if (should_check_for_errors == @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
            loop = @as(c_int, 0) != 0;
            while (true) {
                var file: *FILE = fopen("logs/cano.log", "a");
                _ = &file;
                if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                    _ = fprintf(file, "%s:%d: Failed to open file\n", "src/tools.c", @as(c_int, 294));
                    _ = fclose(file);
                }
                if (!false) break;
            }
            return @as(?*anyopaque, @ptrFromInt(@as(c_int, 0)));
        }
        while (fgets(@as(*u8, @ptrCast(@alignCast(&path))), @as(c_int, @bitCast(@as(c_uint, @truncate(@sizeOf([1035]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))))), should_check_for_errors) != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
            while (true) {
                var file: *FILE = fopen("logs/cano.log", "a");
                _ = &file;
                if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                    _ = fprintf(file, "%s:%d: return code: %s\n", "src/tools.c", @as(c_int, 298), @as(*u8, @ptrCast(@alignCast(&path))));
                    _ = fclose(file);
                }
                if (!false) break;
            }
            if (!(strcmp(@as(*u8, @ptrCast(@alignCast(&path))), "0") == @as(c_int, 0))) {
                var file_contents: *FILE = fopen("errors.cano", "r");
                _ = &file_contents;
                if (fp == @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                    loop = @as(c_int, 0) != 0;
                    while (true) {
                        var file: *FILE = fopen("logs/cano.log", "a");
                        _ = &file;
                        if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                            _ = fprintf(file, "%s:%d: Failed to open file\n", "src/tools.c", @as(c_int, 303));
                            _ = fclose(file);
                        }
                        if (!false) break;
                    }
                    return @as(?*anyopaque, @ptrFromInt(@as(c_int, 0)));
                }
                _ = fseek(file_contents, @as(c_long, @bitCast(@as(c_long, @as(c_int, 0)))), @as(c_int, 2));
                var filesize: c_long = ftell(file_contents);
                _ = &filesize;
                _ = fseek(file_contents, @as(c_long, @bitCast(@as(c_long, @as(c_int, 0)))), @as(c_int, 0));
                var buffer: *u8 = @as(*u8, @ptrCast(@alignCast(malloc(@as(c_ulong, @bitCast(filesize + @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))))))));
                _ = &buffer;
                if (buffer == @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                    while (true) {
                        var file: *FILE = fopen("logs/cano.log", "a");
                        _ = &file;
                        if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                            _ = fprintf(file, "%s:%d: Failed to allocate memory\n", "src/tools.c", @as(c_int, 313));
                            _ = fclose(file);
                        }
                        if (!false) break;
                    }
                    return @as(?*anyopaque, @ptrFromInt(@as(c_int, 0)));
                }
                _ = fread(@as(?*anyopaque, @ptrCast(buffer)), @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))), @as(c_ulong, @bitCast(filesize)), file_contents);
                (blk: {
                    const tmp = filesize;
                    if (tmp >= 0) break :blk buffer + @as(usize, @intCast(tmp)) else break :blk buffer - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* = '\x00';
                var bufffer: *u8 = @as(*u8, @ptrCast(@alignCast(malloc(@as(c_ulong, @bitCast(filesize + @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))))))));
                _ = &bufffer;
                while (fgets(@as(*u8, @ptrCast(@alignCast(&path))), @as(c_int, @bitCast(@as(c_uint, @truncate(@sizeOf([1035]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))))), file_contents) != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                    _ = strcat(bufffer, @as(*u8, @ptrCast(@alignCast(&path))));
                    _ = strcat(buffer, "\n");
                }
                var return_message: *u8 = @as(*u8, @ptrCast(@alignCast(malloc(@as(c_ulong, @bitCast(filesize + @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))))))));
                _ = &return_message;
                if (return_message == @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                    while (true) {
                        var file: *FILE = fopen("logs/cano.log", "a");
                        _ = &file;
                        if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                            _ = fprintf(file, "%s:%d: Failed to allocate memory\n", "src/tools.c", @as(c_int, 328));
                            _ = fclose(file);
                        }
                        if (!false) break;
                    }
                    free(@as(?*anyopaque, @ptrCast(buffer)));
                    return @as(?*anyopaque, @ptrFromInt(@as(c_int, 0)));
                }
                _ = strcpy(return_message, buffer);
                free(@as(?*anyopaque, @ptrCast(buffer)));
                loop = @as(c_int, 0) != 0;
                _ = fclose(file_contents);
                return @as(?*anyopaque, @ptrCast(return_message));
            } else {
                loop = @as(c_int, 0) != 0;
                const return_message = struct {
                    var static: [15:0]u8 = "No errors found".*;
                };
                _ = &return_message;
                return @as(?*anyopaque, @ptrCast(@as(*u8, @ptrCast(@alignCast(&return_message.static)))));
            }
        }
    }
    return @as(?*anyopaque, @ptrFromInt(@as(c_int, 0)));
}
pub fn rgb_to_ncurses(arg_r: c_int, arg_g: c_int, arg_b: c_int) Ncurses_Color {
    var r = arg_r;
    _ = &r;
    var g = arg_g;
    _ = &g;
    var b = arg_b;
    _ = &b;
    var color: Ncurses_Color = Ncurses_Color{
        .r = @as(c_int, 0),
        .g = 0,
        .b = 0,
    };
    _ = &color;
    color.r = @as(c_int, @intFromFloat((@as(f64, @floatFromInt(r)) / 256.0) * @as(f64, @floatFromInt(@as(c_int, 1000)))));
    color.g = @as(c_int, @intFromFloat((@as(f64, @floatFromInt(g)) / 256.0) * @as(f64, @floatFromInt(@as(c_int, 1000)))));
    color.b = @as(c_int, @intFromFloat((@as(f64, @floatFromInt(b)) / 256.0) * @as(f64, @floatFromInt(@as(c_int, 1000)))));
    return color;
}

pub fn init_ncurses_color(arg_id: c_int, arg_r: c_int, arg_g: c_int, arg_b: c_int) void {
    var id = arg_id;
    _ = &id;
    var r = arg_r;
    _ = &r;
    var g = arg_g;
    _ = &g;
    var b = arg_b;
    _ = &b;
    var color: Ncurses_Color = rgb_to_ncurses(r, g, b);
    _ = &color;
    _ = init_color(@as(c_short, @bitCast(@as(c_short, @truncate(id)))), @as(c_short, @bitCast(@as(c_short, @truncate(color.r)))), @as(c_short, @bitCast(@as(c_short, @truncate(color.g)))), @as(c_short, @bitCast(@as(c_short, @truncate(color.b)))));
}

pub fn reset_command(command: [*:0]u8, command_s: *usize) void {
    const cmd = command[0..command_s.*];
    @memset(cmd, 0);
    command_s.* = 0;
}
