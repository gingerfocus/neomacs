const std = @import("std");

const keys = @import("keys.zig");
const vw = @import("view.zig");
const fr = @import("frontend.zig");

const scu = @import("scured");
const term = scu.thermit;

pub const String_View = vw.String_View;

pub const Mode = enum(usize) {
    NORMAL = 0,
    INSERT = 1,
    SEARCH = 2,
    COMMAND = 3,
    VISUAL = 4,

    pub fn toString(self: Mode) []const u8 {
        return switch (self) {
            .NORMAL => "NORMAL",
            .INSERT => "INSERT",
            .SEARCH => "SEARCH",
            .COMMAND => "COMMAND",
            .VISUAL => "VISUAL",
        };
    }
};

pub const Leader = enum(u32) {
    NONE = 0,
    R = 1,
    D = 2,
    Y = 3,
};

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

pub const Buffer = struct {
    data: Data,
    rows: Rows,
    cursor: usize = 0,
    row: usize = 0,
    col: usize = 0,
    filename: []const u8,
    visual: ?Visual = null,

    // pub fn deinit(self: Buffer) void {
    //     self.data.deinit();
    //     const a = std.heap.c_allocator;
    //     a.free(self.filename);
    //     self.row = 0;
    //     self.col = 0;
    // }
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

pub const Repeating = extern struct {
    repeating: bool = false,
    repeating_count: usize = 0,
};

pub const Sized_Str = extern struct {
    str: *u8 = @import("std").mem.zeroes(*u8),
    len: usize = @import("std").mem.zeroes(usize),
};

pub const Map = struct {
    a: u8,
    b: []const u8,
};

pub const Maps = std.ArrayListUnmanaged(Map);

pub const Var_Value = extern union {
    as_int: c_int,
    as_float: f32,
    as_ptr: ?*anyopaque,
};
pub const VAR_INT: c_int = 0;
pub const VAR_FLOAT: c_int = 1;
pub const VAR_PTR: c_int = 2;
pub const Var_Type = c_uint;
pub const Variable = struct {
    name: []u8,
    value: Var_Value = @import("std").mem.zeroes(Var_Value),
    type: Var_Type = @import("std").mem.zeroes(Var_Type),
};
pub const Variables = std.ArrayListUnmanaged(Variable);
pub const File = struct {
    name: []const u8, // = @import("std").mem.zeroes(*u8),
    path: []const u8, // = @import("std").mem.zeroes(*u8),
    is_directory: bool, //= @import("std").mem.zeroes(bool),
};
pub const Files = std.ArrayListUnmanaged(File);

pub const Config_Vars = struct {
    label: String_View = &.{},
    val: *c_int = @import("std").mem.zeroes(*c_int),
};

pub const Config = struct {
    relative_nums: c_int = 1,
    auto_indent: c_int = 1,
    syntax: c_int = 1,
    indent: c_int = 0,
    undo_size: c_int = 16,
    lang: []const u8,
    QUIT: bool = false,
    mode: Mode = .NORMAL,
    background_color: c_int = -1,
    leaders: [4]u8,
    key_maps: Maps,
    // vars: [5]Config_Vars = @import("std").mem.zeroes([5]Config_Vars),

    pub fn init(a: std.mem.Allocator) !Config {
        return Config{
            .lang = try a.dupe(u8, " "),
            .relative_nums = 1,
            .auto_indent = 1,
            .syntax = 1,
            .indent = 0,
            .undo_size = 16,
            .QUIT = false,
            .mode = .NORMAL,
            .background_color = -@as(c_int, 1),
            .leaders = .{ ' ', 'r', 'd', 'y' },
            .key_maps = Maps{},
            // .vars = .{
            //     Config_Vars{
            //         .label = "syntax",
            //         .val = &"syntax",
            //         //     .val = &state.config.syntax,
            //     },
            //     Config_Vars{
            //         //     .label = String_View{
            //         //         .data = @as(*u8, @ptrCast(@volatileCast(@constCast("indent")))),
            //         //         .len = @sizeOf([7]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
            //         //     },
            //         //     .val = &state.config.indent,
            //     },
            //     Config_Vars{
            //         //     .label = String_View{
            //         //         .data = @as(*u8, @ptrCast(@volatileCast(@constCast("auto-indent")))),
            //         //         .len = @sizeOf([12]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
            //         //     },
            //         //     .val = &state.config.auto_indent,
            //     },
            //     Config_Vars{
            //         //     .label = String_View{
            //         //         .data = @as(*u8, @ptrCast(@volatileCast(@constCast("undo-size")))),
            //         //         .len = @sizeOf([10]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
            //         //     },
            //         //     .val = &state.config.undo_size,
            //     },
            //     Config_Vars{
            //         //     .label = String_View{
            //         //         .data = @as(*u8, @ptrCast(@volatileCast(@constCast("relative")))),
            //         //         .len = @sizeOf([9]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
            //         //     },
            //         //     .val = &state.config.relative_nums,
            //     },
            // },

        };
    }

    pub fn deinit(config: Config, a: std.mem.Allocator) void {
        a.free(config.lang);
    }
};

pub const State = struct {
    a: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    term: scu.Term,

    // undo_stack: Undo_Stack,
    // redo_stack: Undo_Stack,
    cur_undo: Undo,
    // num_of_braces: usize = @import("std").mem.zeroes(usize),
    ch: term.KeyEvent = std.mem.zeroes(term.KeyEvent),
    // env: [*:0]u8,
    // command: [*:0]u8,
    // command_s: usize = @import("std").mem.zeroes(usize),
    // variables: Variables,
    repeating: Repeating = .{},
    num: Data,
    leader: Leader = .NONE,

    /// Message to show in the status bar, remains until cleared
    /// must be area allocated
    status_bar_msg: ?[]const u8 = null,

    // x: usize = @import("std").mem.zeroes(usize),
    // y: usize = @import("std").mem.zeroes(usize),
    // normal_pos: usize = @import("std").mem.zeroes(usize),
    key_func: [5]*const fn (*Buffer, *State) anyerror!void = .{
        &keys.handleNormalKeys,
        &keys.handleInsertLeys,
        &keys.handle_search_keys,
        &keys.handle_command_keys,
        &keys.handle_visual_keys,
    },
    // clipboard: ?[]const u8 = null,
    files: Files,
    // is_exploring: bool = false,
    // explore_cursor: usize = 0,
    buffer: ?*Buffer = null,
    // grow: c_int = @import("std").mem.zeroes(c_int),
    // gcol: c_int = @import("std").mem.zeroes(c_int),
    // main_row: c_int = @import("std").mem.zeroes(c_int),
    // main_col: c_int = @import("std").mem.zeroes(c_int),
    // line_num_row: c_int = @import("std").mem.zeroes(c_int),
    // line_num_col: c_int = @import("std").mem.zeroes(c_int),
    // status_bar_row: c_int = @import("std").mem.zeroes(c_int),
    // status_bar_col: c_int = @import("std").mem.zeroes(c_int),
    resized: bool = false,

    line_num_win: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),
    main_win: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),
    status_bar: scu.Term.Screen = std.mem.zeroes(scu.Term.Screen),

    config: Config,

    pub fn init(a: std.mem.Allocator) !State {
        var state = State{
            .a = a,
            .arena = std.heap.ArenaAllocator.init(a),
            .term = try scu.Term.init(a),
            // .undo_stack = Undo_Stack.init(a),
            // .redo_stack = Undo_Stack.init(a),
            .cur_undo = Undo{},
            // .num_of_braces = @import("std").mem.zeroes(usize),
            // .ch = 0,
            // .env = null,
            // .command = try a.allocSentinel(u8, 63, 0),
            // .command_s = @import("std").mem.zeroes(usize),
            // .variables = Variables{},
            // .repeating = @import("std").mem.zeroes(Repeating),
            .num = Data{},
            // .is_print_msg = false,
            // .status_bar_msg = try a.alloc(u8, 128),
            // .x = @import("std").mem.zeroes(usize),
            // .y = @import("std").mem.zeroes(usize),
            // .normal_pos = @import("std").mem.zeroes(usize),
            // .key_func = null,
            // .clipboard = @import("std").mem.zeroes(Sized_Str),
            .files = Files{},
            // .is_exploring = false,
            // .explore_cursor = @import("std").mem.zeroes(usize),
            // .grow = 0,
            // .gcol = 0,
            // .main_row = 0,
            // .main_col = 0,
            // .line_num_row = 0,
            // .line_num_col = 0,
            // .status_bar_row = 0,
            // .status_bar_col = 0,
            .config = try Config.init(a),
        };
        try state.resize();
        return state;
    }

    pub fn deinit(state: *State) void {
        state.term.deinit();

        for (state.files.items) |file| {
            state.a.free(file.name);
            state.a.free(file.path);
        }
        state.files.deinit(state.a);

        state.num.deinit(state.a);

        state.cur_undo.data.deinit(state.a);
        // state.undo_stack.deinit();
        // state.redo_stack.deinit();

        // state.a.free(state.status_bar_msg);

        state.arena.deinit();

        if (state.buffer) |buffer| {
            buffer.data.deinit(state.a);
            buffer.rows.deinit(state.a);
            state.a.free(buffer.filename);
            state.a.destroy(buffer);
        }
        state.config.deinit(state.a);
    }

    pub fn resize(state: *State) !void {
        state.resized = true;
        const x, const y = try term.getWindowSize(state.term.tty.f.handle);

        state.line_num_win = .{
            .x = 0,
            .y = 0,
            .w = fr.sidebarWidth,
            .h = y - fr.statusbarHeight,
        };

        state.status_bar = .{
            .x = 0,
            .y = y - fr.statusbarHeight,
            .w = x,
            .h = fr.statusbarHeight,
        };

        state.main_win = .{
            .x = fr.sidebarWidth,
            .y = 0,
            .w = x - fr.sidebarWidth,
            .h = y - fr.statusbarHeight,
        };
    }
};

pub const Brace = extern struct {
    brace: u8 = @import("std").mem.zeroes(u8),
    closing: c_int = @import("std").mem.zeroes(c_int),
};

pub const Ncurses_Color = extern struct {
    r: c_int = @import("std").mem.zeroes(c_int),
    g: c_int = @import("std").mem.zeroes(c_int),
    b: c_int = @import("std").mem.zeroes(c_int),
};

pub const Syntax_Highlighting = extern struct {
    row: usize = @import("std").mem.zeroes(usize),
    col: usize = @import("std").mem.zeroes(usize),
    size: usize = @import("std").mem.zeroes(usize),
};
