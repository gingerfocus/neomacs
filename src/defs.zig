const std = @import("std");
const root = @import("root");

const keys = @import("keys.zig");
const fr = @import("frontend.zig");
const tools = @import("tools.zig");
const lua = @import("lua.zig");

const scu = @import("scured");
const term = scu.thermit;

const luajitsys = root.luajitsys;

pub const UndoType = enum {
    NONE,
    INSERT_CHARS,
    DELETE_CHAR,
    DELETE_MULT_CHAR,
    REPLACE_CHAR,
};

pub const NO_ERROR: c_int = 0;
pub const NOT_ENOUGH_ARGS: c_int = 1;
pub const INVALID_ARGS: c_int = 2;
pub const UNKNOWN_COMMAND: c_int = 3;
pub const INVALID_IDENT: c_int = 4;
pub const Command_Error = c_uint;
pub const ThreadArgs = extern struct {
    path_to_file: *const u8 = @import("std").mem.zeroes(*const u8),
    filename: *const u8 = @import("std").mem.zeroes(*const u8),
    lang: *const u8 = @import("std").mem.zeroes(*const u8),
};
pub const Color = extern struct {
    color_name: [20]u8 = @import("std").mem.zeroes([20]u8),
    is_custom_line_row: bool = @import("std").mem.zeroes(bool),
    is_custom: bool = @import("std").mem.zeroes(bool),
    slot: c_int = @import("std").mem.zeroes(c_int),
    id: c_int = @import("std").mem.zeroes(c_int),
    red: c_int = @import("std").mem.zeroes(c_int),
    green: c_int = @import("std").mem.zeroes(c_int),
    blue: c_int = @import("std").mem.zeroes(c_int),
};
pub const Point = extern struct {
    x: usize = @import("std").mem.zeroes(usize),
    y: usize = @import("std").mem.zeroes(usize),
};
pub const Visual = extern struct {
    start: usize = @import("std").mem.zeroes(usize),
    end: usize = @import("std").mem.zeroes(usize),
    is_line: c_int = @import("std").mem.zeroes(c_int),
};
pub const Row = extern struct {
    start: usize = @import("std").mem.zeroes(usize),
    end: usize = @import("std").mem.zeroes(usize),
};

pub const Rows = std.ArrayListUnmanaged(Row);

pub const Data = std.ArrayListUnmanaged(u8);

pub const Positions = extern struct {
    data: *usize = @import("std").mem.zeroes(*usize),
    count: usize = @import("std").mem.zeroes(usize),
    capacity: usize = @import("std").mem.zeroes(usize),
};

pub const Arg = extern struct {
    size: usize = @import("std").mem.zeroes(usize),
    arg: *u8 = @import("std").mem.zeroes(*u8),
};

pub const Undo = struct {
    type: UndoType = .NONE,
    data: std.ArrayListUnmanaged(u8) = .{},
    start: usize = 0,
    end: usize = 0,
};

pub const Undo_Stack = std.ArrayList(Undo);

// pub const Sized_Str = extern struct {
//     str: *u8 = @import("std").mem.zeroes(*u8),
//     len: usize = @import("std").mem.zeroes(usize),
// };

// pub const Maps = std.ArrayListUnmanaged(Map);
// pub const Map = struct {
//     a: u8,
//     b: []const u8,
// };

pub const Var_Value = extern union {
    as_int: c_int,
    as_float: f32,
    as_ptr: ?*anyopaque,
};
pub const VAR_INT: c_int = 0;
pub const VAR_FLOAT: c_int = 1;
pub const VAR_PTR: c_int = 2;
pub const Var_Type = c_uint;

// pub const Variables = std.ArrayListUnmanaged(Variable);
// pub const Variable = struct {
//     name: []u8,
//     value: Var_Value = @import("std").mem.zeroes(Var_Value),
//     type: Var_Type = @import("std").mem.zeroes(Var_Type),
// };

// pub const Files = std.ArrayListUnmanaged(File);
// pub const File = struct {
//     name: []const u8,
//     path: []const u8,
//     is_directory: bool,
// };

pub const Brace = extern struct {
    brace: u8 = @import("std").mem.zeroes(u8),
    closing: c_int = @import("std").mem.zeroes(c_int),
};

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

// -*- colors.h -*-
// pub const YELLOW_COLOR: c_int = 1;
// pub const BLUE_COLOR: c_int = 2;
// pub const GREEN_COLOR: c_int = 3;
// pub const RED_COLOR: c_int = 4;
// pub const CYAN_COLOR: c_int = 5;
// pub const MAGENTA_COLOR: c_int = 6;
//
// pub const Color_Pairs = c_uint;
// pub const Custom_Color = extern struct {
//     custom_slot: Color_Pairs = @import("std").mem.zeroes(Color_Pairs),
//     custom_id: c_int = @import("std").mem.zeroes(c_int),
//     custom_r: c_int = @import("std").mem.zeroes(c_int),
//     custom_g: c_int = @import("std").mem.zeroes(c_int),
//     custom_b: c_int = @import("std").mem.zeroes(c_int),
// };
// pub const Color_Arr = extern struct {
//     arr: *Custom_Color = @import("std").mem.zeroes(*Custom_Color),
//     arr_s: usize = @import("std").mem.zeroes(usize),
// };
