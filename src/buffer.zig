pub const __off_t = c_long;
pub const __off64_t = c_long;
pub const chtype = c_uint;
pub const struct__IO_marker = opaque {};
pub const _IO_lock_t = anyopaque;
pub const struct__IO_codecvt = opaque {};
pub const struct__IO_wide_data = opaque {};
pub const struct__IO_FILE = extern struct {
    _flags: c_int = @import("std").mem.zeroes(c_int),
    _IO_read_ptr: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_read_end: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_read_base: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_write_base: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_write_ptr: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_write_end: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_buf_base: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_buf_end: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_save_base: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_backup_base: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _IO_save_end: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    _markers: ?*struct__IO_marker = @import("std").mem.zeroes(?*struct__IO_marker),
    _chain: [*c]struct__IO_FILE = @import("std").mem.zeroes([*c]struct__IO_FILE),
    _fileno: c_int = @import("std").mem.zeroes(c_int),
    _flags2: c_int = @import("std").mem.zeroes(c_int),
    _old_offset: __off_t = @import("std").mem.zeroes(__off_t),
    _cur_column: c_ushort = @import("std").mem.zeroes(c_ushort),
    _vtable_offset: i8 = @import("std").mem.zeroes(i8),
    _shortbuf: [1]u8 = @import("std").mem.zeroes([1]u8),
    _lock: ?*_IO_lock_t = @import("std").mem.zeroes(?*_IO_lock_t),
    _offset: __off64_t = @import("std").mem.zeroes(__off64_t),
    _codecvt: ?*struct__IO_codecvt = @import("std").mem.zeroes(?*struct__IO_codecvt),
    _wide_data: ?*struct__IO_wide_data = @import("std").mem.zeroes(?*struct__IO_wide_data),
    _freeres_list: [*c]struct__IO_FILE = @import("std").mem.zeroes([*c]struct__IO_FILE),
    _freeres_buf: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    __pad5: usize = @import("std").mem.zeroes(usize),
    _mode: c_int = @import("std").mem.zeroes(c_int),
    _unused2: [20]u8 = @import("std").mem.zeroes([20]u8),
};
pub const FILE = struct__IO_FILE;
pub extern var stderr: [*c]FILE;
pub extern fn fprintf(__stream: [*c]FILE, __format: [*c]const u8, ...) c_int;
pub const acs_map: [*c]chtype = @extern([*c]chtype, .{
    .name = "acs_map",
});
// pub const struct_screen = opaque {};
// pub const SCREEN = struct_screen;
pub const attr_t = chtype;
pub const struct_ldat = opaque {};
pub const WINDOW = struct__win_st;
pub const struct_pdat_3 = extern struct {
    _pad_y: c_short = @import("std").mem.zeroes(c_short),
    _pad_x: c_short = @import("std").mem.zeroes(c_short),
    _pad_top: c_short = @import("std").mem.zeroes(c_short),
    _pad_left: c_short = @import("std").mem.zeroes(c_short),
    _pad_bottom: c_short = @import("std").mem.zeroes(c_short),
    _pad_right: c_short = @import("std").mem.zeroes(c_short),
};
pub const struct__win_st = extern struct {
    _cury: c_short = @import("std").mem.zeroes(c_short),
    _curx: c_short = @import("std").mem.zeroes(c_short),
    _maxy: c_short = @import("std").mem.zeroes(c_short),
    _maxx: c_short = @import("std").mem.zeroes(c_short),
    _begy: c_short = @import("std").mem.zeroes(c_short),
    _begx: c_short = @import("std").mem.zeroes(c_short),
    _flags: c_short = @import("std").mem.zeroes(c_short),
    _attrs: attr_t = @import("std").mem.zeroes(attr_t),
    _bkgd: chtype = @import("std").mem.zeroes(chtype),
    _notimeout: bool = @import("std").mem.zeroes(bool),
    _clear: bool = @import("std").mem.zeroes(bool),
    _leaveok: bool = @import("std").mem.zeroes(bool),
    _scroll: bool = @import("std").mem.zeroes(bool),
    _idlok: bool = @import("std").mem.zeroes(bool),
    _idcok: bool = @import("std").mem.zeroes(bool),
    _immed: bool = @import("std").mem.zeroes(bool),
    _sync: bool = @import("std").mem.zeroes(bool),
    _use_keypad: bool = @import("std").mem.zeroes(bool),
    _delay: c_int = @import("std").mem.zeroes(c_int),
    _line: ?*struct_ldat = @import("std").mem.zeroes(?*struct_ldat),
    _regtop: c_short = @import("std").mem.zeroes(c_short),
    _regbottom: c_short = @import("std").mem.zeroes(c_short),
    _parx: c_int = @import("std").mem.zeroes(c_int),
    _pary: c_int = @import("std").mem.zeroes(c_int),
    _parent: [*c]WINDOW = @import("std").mem.zeroes([*c]WINDOW),
    _pad: struct_pdat_3 = @import("std").mem.zeroes(struct_pdat_3),
    _yoffset: c_short = @import("std").mem.zeroes(c_short),
};
pub const _ISalnum: c_int = 8;
pub extern fn __ctype_b_loc() [*c][*c]const c_ushort;

pub const String_View = extern struct {
    data: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    len: usize = @import("std").mem.zeroes(usize),
};
pub fn view_create(arg_str: [*c]u8, arg_len: usize) callconv(.C) String_View {
    var str = arg_str;
    _ = &str;
    var len = arg_len;
    _ = &len;
    return String_View{
        .data = str,
        .len = len,
    };
}
pub extern fn view_cmp(a: String_View, b: String_View) c_int;
pub fn view_starts_with_s(arg_a: String_View, arg_b: String_View) callconv(.C) c_int {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return view_cmp(view_create(a.data, b.len), b);
}
pub fn view_ends_with_s(arg_a: String_View, arg_b: String_View) callconv(.C) c_int {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return view_cmp(view_create((a.data + a.len) - b.len, b.len), b);
}
pub extern fn view_to_cstr(view: String_View) [*c]u8;
pub extern fn view_trim_left(view: String_View) String_View;
pub extern fn view_trim_right(view: String_View) String_View;
pub extern fn view_contains(haystack: String_View, needle: String_View) c_int;
pub extern fn view_first_of(view: String_View, target: u8) usize;
pub extern fn view_last_of(view: String_View, target: u8) usize;
pub extern fn view_split(view: String_View, c: u8, arr: [*c]String_View, arr_s: usize) usize;
pub extern fn view_chop(view: String_View, c: u8) String_View;
pub extern fn view_rev(view: String_View, data: [*c]u8, data_s: usize) String_View;
pub extern fn view_find(haystack: String_View, needle: String_View) usize;
pub extern fn view_to_int(view: String_View) c_int;
pub extern fn view_to_float(view: String_View) f32;
pub const NORMAL: c_int = 0;
pub const INSERT: c_int = 1;
pub const SEARCH: c_int = 2;
pub const COMMAND: c_int = 3;
pub const VISUAL: c_int = 4;
pub const MODE_COUNT: c_int = 5;
pub const Mode = c_uint;
pub const LEADER_NONE: c_int = 0;
pub const LEADER_R: c_int = 1;
pub const LEADER_D: c_int = 2;
pub const LEADER_Y: c_int = 3;
pub const LEADER_COUNT: c_int = 4;
pub const Leader = c_uint;
pub const NONE: c_int = 0;
pub const INSERT_CHARS: c_int = 1;
pub const DELETE_CHAR: c_int = 2;
pub const DELETE_MULT_CHAR: c_int = 3;
pub const REPLACE_CHAR: c_int = 4;
pub const Undo_Type = c_uint;
pub const NO_ERROR: c_int = 0;
pub const NOT_ENOUGH_ARGS: c_int = 1;
pub const INVALID_ARGS: c_int = 2;
pub const UNKNOWN_COMMAND: c_int = 3;
pub const INVALID_IDENT: c_int = 4;
pub const Command_Error = c_uint;
pub const ThreadArgs = extern struct {
    path_to_file: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    filename: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    lang: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
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
pub const Rows = extern struct {
    data: [*c]Row = @import("std").mem.zeroes([*c]Row),
    count: usize = @import("std").mem.zeroes(usize),
    capacity: usize = @import("std").mem.zeroes(usize),
};
pub const Data = extern struct {
    data: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    count: usize = @import("std").mem.zeroes(usize),
    capacity: usize = @import("std").mem.zeroes(usize),
};
pub const Positions = extern struct {
    data: [*c]usize = @import("std").mem.zeroes([*c]usize),
    count: usize = @import("std").mem.zeroes(usize),
    capacity: usize = @import("std").mem.zeroes(usize),
};
pub const Buffer = extern struct {
    data: Data = @import("std").mem.zeroes(Data),
    rows: Rows = @import("std").mem.zeroes(Rows),
    cursor: usize = @import("std").mem.zeroes(usize),
    row: usize = @import("std").mem.zeroes(usize),
    col: usize = @import("std").mem.zeroes(usize),
    filename: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    visual: Visual = @import("std").mem.zeroes(Visual),
};
pub const Arg = extern struct {
    size: usize = @import("std").mem.zeroes(usize),
    arg: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};
pub const Undo = extern struct {
    type: Undo_Type = @import("std").mem.zeroes(Undo_Type),
    data: Data = @import("std").mem.zeroes(Data),
    start: usize = @import("std").mem.zeroes(usize),
    end: usize = @import("std").mem.zeroes(usize),
};
pub const Undo_Stack = extern struct {
    data: [*c]Undo = @import("std").mem.zeroes([*c]Undo),
    count: usize = @import("std").mem.zeroes(usize),
    capacity: usize = @import("std").mem.zeroes(usize),
};
pub const Repeating = extern struct {
    repeating: bool = @import("std").mem.zeroes(bool),
    repeating_count: usize = @import("std").mem.zeroes(usize),
};
pub const Sized_Str = extern struct {
    str: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    len: usize = @import("std").mem.zeroes(usize),
};
pub const Map = extern struct {
    a: c_int = @import("std").mem.zeroes(c_int),
    b: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    b_s: usize = @import("std").mem.zeroes(usize),
};
pub const Maps = extern struct {
    data: [*c]Map = @import("std").mem.zeroes([*c]Map),
    count: usize = @import("std").mem.zeroes(usize),
    capacity: usize = @import("std").mem.zeroes(usize),
};
pub const Var_Value = extern union {
    as_int: c_int,
    as_float: f32,
    as_ptr: ?*anyopaque,
};
pub const VAR_INT: c_int = 0;
pub const VAR_FLOAT: c_int = 1;
pub const VAR_PTR: c_int = 2;
pub const Var_Type = c_uint;
pub const Variable = extern struct {
    name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    value: Var_Value = @import("std").mem.zeroes(Var_Value),
    type: Var_Type = @import("std").mem.zeroes(Var_Type),
};
pub const Variables = extern struct {
    data: [*c]Variable = @import("std").mem.zeroes([*c]Variable),
    count: usize = @import("std").mem.zeroes(usize),
    capacity: usize = @import("std").mem.zeroes(usize),
};
pub const File = extern struct {
    name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    path: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    is_directory: bool = @import("std").mem.zeroes(bool),
};
pub const Files = extern struct {
    data: [*c]File = @import("std").mem.zeroes([*c]File),
    count: usize = @import("std").mem.zeroes(usize),
    capacity: usize = @import("std").mem.zeroes(usize),
};
pub const Config_Vars = extern struct {
    label: String_View = @import("std").mem.zeroes(String_View),
    val: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
};
pub const struct__Config_ = extern struct {
    relative_nums: c_int = @import("std").mem.zeroes(c_int),
    auto_indent: c_int = @import("std").mem.zeroes(c_int),
    syntax: c_int = @import("std").mem.zeroes(c_int),
    indent: c_int = @import("std").mem.zeroes(c_int),
    undo_size: c_int = @import("std").mem.zeroes(c_int),
    lang: ?[*:0]const u8 = @import("std").mem.zeroes([*c]u8),
    QUIT: c_int = @import("std").mem.zeroes(c_int),
    mode: Mode = @import("std").mem.zeroes(Mode),
    background_color: c_int = @import("std").mem.zeroes(c_int),
    leaders: [4]u8 = @import("std").mem.zeroes([4]u8),
    key_maps: Maps = @import("std").mem.zeroes(Maps),
    vars: [5]Config_Vars = @import("std").mem.zeroes([5]Config_Vars),
};
pub const Config = struct__Config_;
pub const struct_State = extern struct {
    undo_stack: Undo_Stack = @import("std").mem.zeroes(Undo_Stack),
    redo_stack: Undo_Stack = @import("std").mem.zeroes(Undo_Stack),
    cur_undo: Undo = @import("std").mem.zeroes(Undo),
    num_of_braces: usize = @import("std").mem.zeroes(usize),
    ch: c_int = @import("std").mem.zeroes(c_int),
    env: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    command: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    command_s: usize = @import("std").mem.zeroes(usize),
    variables: Variables = @import("std").mem.zeroes(Variables),
    repeating: Repeating = @import("std").mem.zeroes(Repeating),
    num: Data = @import("std").mem.zeroes(Data),
    leader: Leader = @import("std").mem.zeroes(Leader),
    is_print_msg: bool = @import("std").mem.zeroes(bool),
    status_bar_msg: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    x: usize = @import("std").mem.zeroes(usize),
    y: usize = @import("std").mem.zeroes(usize),
    normal_pos: usize = @import("std").mem.zeroes(usize),
    key_func: [*c]?*const fn ([*c]Buffer, [*c][*c]Buffer, [*c]struct_State) callconv(.C) void = @import("std").mem.zeroes([*c]?*const fn ([*c]Buffer, [*c][*c]Buffer, [*c]struct_State) callconv(.C) void),
    clipboard: Sized_Str = @import("std").mem.zeroes(Sized_Str),
    files: [*c]Files = @import("std").mem.zeroes([*c]Files),
    is_exploring: bool = @import("std").mem.zeroes(bool),
    explore_cursor: usize = @import("std").mem.zeroes(usize),
    buffer: [*c]Buffer = @import("std").mem.zeroes([*c]Buffer),
    grow: c_int = @import("std").mem.zeroes(c_int),
    gcol: c_int = @import("std").mem.zeroes(c_int),
    main_row: c_int = @import("std").mem.zeroes(c_int),
    main_col: c_int = @import("std").mem.zeroes(c_int),
    line_num_row: c_int = @import("std").mem.zeroes(c_int),
    line_num_col: c_int = @import("std").mem.zeroes(c_int),
    status_bar_row: c_int = @import("std").mem.zeroes(c_int),
    status_bar_col: c_int = @import("std").mem.zeroes(c_int),
    line_num_win: [*c]WINDOW = @import("std").mem.zeroes([*c]WINDOW),
    main_win: [*c]WINDOW = @import("std").mem.zeroes([*c]WINDOW),
    status_bar: [*c]WINDOW = @import("std").mem.zeroes([*c]WINDOW),
    config: Config = @import("std").mem.zeroes(Config),
};
pub const State = struct_State;
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
pub extern var string_modes: [5][*c]u8;
pub export fn buffer_calculate_rows(arg_buffer: [*c]Buffer) void {
    var buffer = arg_buffer;
    _ = &buffer;
    buffer.*.rows.count = 0;
    var start: usize = 0;
    _ = &start;
    {
        var i: usize = 0;
        _ = &i;
        while (i < buffer.*.data.count) : (i +%= 1) {
            if (@as(c_int, @bitCast(@as(c_uint, buffer.*.data.data[i]))) == @as(c_int, '\n')) {
                while (true) {
                    if ((&buffer.*.rows).*.count >= (&buffer.*.rows).*.capacity) {
                        (&buffer.*.rows).*.capacity = if ((&buffer.*.rows).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&buffer.*.rows).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
                        var new: ?*anyopaque = calloc((&buffer.*.rows).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(Row));
                        _ = &new;
                        while (true) {
                            if (!(new != null)) {
                                frontend_end();
                                _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 10));
                                _ = fprintf(stderr, "outta ram");
                                _ = fprintf(stderr, "\n");
                                exit(@as(c_int, 1));
                            }
                            if (!false) break;
                        }
                        _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&buffer.*.rows).*.data)), (&buffer.*.rows).*.count);
                        free(@as(?*anyopaque, @ptrCast((&buffer.*.rows).*.data)));
                        (&buffer.*.rows).*.data = @as([*c]Row, @ptrCast(@alignCast(new)));
                    }
                    (&buffer.*.rows).*.data[
                        blk: {
                            const ref = &(&buffer.*.rows).*.count;
                            const tmp = ref.*;
                            ref.* +%= 1;
                            break :blk tmp;
                        }
                    ] = Row{
                        .start = start,
                        .end = i,
                    };
                    if (!false) break;
                }
                start = i +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
            }
        }
    }
    while (true) {
        if ((&buffer.*.rows).*.count >= (&buffer.*.rows).*.capacity) {
            (&buffer.*.rows).*.capacity = if ((&buffer.*.rows).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&buffer.*.rows).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
            var new: ?*anyopaque = calloc((&buffer.*.rows).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(Row));
            _ = &new;
            while (true) {
                if (!(new != null)) {
                    frontend_end();
                    _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 15));
                    _ = fprintf(stderr, "outta ram");
                    _ = fprintf(stderr, "\n");
                    exit(@as(c_int, 1));
                }
                if (!false) break;
            }
            _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&buffer.*.rows).*.data)), (&buffer.*.rows).*.count);
            free(@as(?*anyopaque, @ptrCast((&buffer.*.rows).*.data)));
            (&buffer.*.rows).*.data = @as([*c]Row, @ptrCast(@alignCast(new)));
        }
        (&buffer.*.rows).*.data[
            blk: {
                const ref = &(&buffer.*.rows).*.count;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            }
        ] = Row{
            .start = start,
            .end = buffer.*.data.count,
        };
        if (!false) break;
    }
}
pub export fn buffer_insert_char(arg_state: [*c]State, arg_buffer: [*c]Buffer, arg_ch: u8) void {
    var state = arg_state;
    _ = &state;
    var buffer = arg_buffer;
    _ = &buffer;
    var ch = arg_ch;
    _ = &ch;
    while (true) {
        if (!(buffer != @as([*c]Buffer, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 19));
            _ = fprintf(stderr, "buffer exists");
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    while (true) {
        if (!(state != @as([*c]State, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 20));
            _ = fprintf(stderr, "state exists");
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    if (buffer.*.cursor > buffer.*.data.count) {
        buffer.*.cursor = buffer.*.data.count;
    }
    while (true) {
        if ((&buffer.*.data).*.count >= (&buffer.*.data).*.capacity) {
            (&buffer.*.data).*.capacity = if ((&buffer.*.data).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&buffer.*.data).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
            var new: ?*anyopaque = calloc((&buffer.*.data).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(u8));
            _ = &new;
            while (true) {
                if (!(new != null)) {
                    frontend_end();
                    _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 23));
                    _ = fprintf(stderr, "outta ram");
                    _ = fprintf(stderr, "\n");
                    exit(@as(c_int, 1));
                }
                if (!false) break;
            }
            _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&buffer.*.data).*.data)), (&buffer.*.data).*.count);
            free(@as(?*anyopaque, @ptrCast((&buffer.*.data).*.data)));
            (&buffer.*.data).*.data = @as([*c]u8, @ptrCast(@alignCast(new)));
        }
        (&buffer.*.data).*.data[
            blk: {
                const ref = &(&buffer.*.data).*.count;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            }
        ] = ch;
        if (!false) break;
    }
    _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), (buffer.*.data.count -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) -% buffer.*.cursor);
    buffer.*.data.data[
        blk: {
            const ref = &buffer.*.cursor;
            const tmp = ref.*;
            ref.* +%= 1;
            break :blk tmp;
        }
    ] = ch;
    state.*.cur_undo.end = buffer.*.cursor;
    buffer_calculate_rows(buffer);
}
pub export fn buffer_delete_char(arg_buffer: [*c]Buffer, arg_state: [*c]State) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    _ = &state;
    if (buffer.*.cursor < buffer.*.data.count) {
        _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))])), (buffer.*.data.count -% buffer.*.cursor) -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
        buffer.*.data.count -%= 1;
        buffer_calculate_rows(buffer);
    }
}
pub export fn buffer_delete_ch(arg_buffer: [*c]Buffer, arg_state: [*c]State) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    while (true) {
        var undo: Undo = Undo{
            .type = @as(c_uint, @bitCast(@as(c_int, 0))),
            .data = @import("std").mem.zeroes(Data),
            .start = @import("std").mem.zeroes(usize),
            .end = @import("std").mem.zeroes(usize),
        };
        _ = &undo;
        undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
        undo.start = buffer.*.cursor;
        state.*.cur_undo = undo;
        if (!false) break;
    }
    reset_command(state.*.clipboard.str, &state.*.clipboard.len);
    buffer_yank_char(buffer, state);
    buffer_delete_char(buffer, state);
    state.*.cur_undo.end = buffer.*.cursor;
    undo_push(state, &state.*.undo_stack, state.*.cur_undo);
}
pub export fn buffer_replace_ch(arg_buffer: [*c]Buffer, arg_state: [*c]State) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    while (true) {
        var undo: Undo = Undo{
            .type = @as(c_uint, @bitCast(@as(c_int, 0))),
            .data = @import("std").mem.zeroes(Data),
            .start = @import("std").mem.zeroes(usize),
            .end = @import("std").mem.zeroes(usize),
        };
        _ = &undo;
        undo.type = @as(c_uint, @bitCast(REPLACE_CHAR));
        undo.start = buffer.*.cursor;
        state.*.cur_undo = undo;
        if (!false) break;
    }
    while (true) {
        if ((&state.*.cur_undo.data).*.count >= (&state.*.cur_undo.data).*.capacity) {
            (&state.*.cur_undo.data).*.capacity = if ((&state.*.cur_undo.data).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&state.*.cur_undo.data).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
            var new: ?*anyopaque = calloc((&state.*.cur_undo.data).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(u8));
            _ = &new;
            while (true) {
                if (!(new != null)) {
                    frontend_end();
                    _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 82));
                    _ = fprintf(stderr, "outta ram");
                    _ = fprintf(stderr, "\n");
                    exit(@as(c_int, 1));
                }
                if (!false) break;
            }
            _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&state.*.cur_undo.data).*.data)), (&state.*.cur_undo.data).*.count);
            free(@as(?*anyopaque, @ptrCast((&state.*.cur_undo.data).*.data)));
            (&state.*.cur_undo.data).*.data = @as([*c]u8, @ptrCast(@alignCast(new)));
        }
        (&state.*.cur_undo.data).*.data[
            blk: {
                const ref = &(&state.*.cur_undo.data).*.count;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            }
        ] = buffer.*.data.data[buffer.*.cursor];
        if (!false) break;
    }
    state.*.ch = frontend_getch(state.*.main_win);
    buffer.*.data.data[buffer.*.cursor] = @as(u8, @bitCast(@as(i8, @truncate(state.*.ch))));
    undo_push(state, &state.*.undo_stack, state.*.cur_undo);
}
pub export fn buffer_delete_row(arg_buffer: [*c]Buffer, arg_state: [*c]State) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    var repeat: usize = state.*.repeating.repeating_count;
    _ = &repeat;
    if (repeat == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        repeat = 1;
    }
    if (repeat > (buffer.*.rows.count -% buffer_get_row(buffer))) {
        repeat = buffer.*.rows.count -% buffer_get_row(buffer);
    }
    {
        var i: usize = 0;
        _ = &i;
        while (i < repeat) : (i +%= 1) {
            reset_command(state.*.clipboard.str, &state.*.clipboard.len);
            buffer_yank_line(buffer, state, @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))));
            var row: usize = buffer_get_row(buffer);
            _ = &row;
            var cur: Row = buffer.*.rows.data[row];
            _ = &cur;
            var offset: usize = buffer.*.cursor -% cur.start;
            _ = &offset;
            while (true) {
                var undo: Undo = Undo{
                    .type = @as(c_uint, @bitCast(@as(c_int, 0))),
                    .data = @import("std").mem.zeroes(Data),
                    .start = @import("std").mem.zeroes(usize),
                    .end = @import("std").mem.zeroes(usize),
                };
                _ = &undo;
                undo.type = @as(c_uint, @bitCast(INSERT_CHARS));
                undo.start = cur.start;
                state.*.cur_undo = undo;
                if (!false) break;
            }
            if (row == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
                var end: usize = if (buffer.*.rows.count > @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) cur.end +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))) else cur.end;
                _ = &end;
                buffer_delete_selection(buffer, state, cur.start, end);
            } else {
                state.*.cur_undo.start -%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
                buffer_delete_selection(buffer, state, cur.start -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), cur.end);
            }
            undo_push(state, &state.*.undo_stack, state.*.cur_undo);
            buffer_calculate_rows(buffer);
            if (row >= buffer.*.rows.count) {
                row = buffer.*.rows.count -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
            }
            cur = buffer.*.rows.data[row];
            var pos: usize = cur.start +% offset;
            _ = &pos;
            if (pos > cur.end) {
                pos = cur.end;
            }
            buffer.*.cursor = pos;
        }
    }
    state.*.repeating.repeating_count = 0;
}
pub export fn buffer_get_row(arg_buffer: [*c]const Buffer) usize {
    var buffer = arg_buffer;
    _ = &buffer;
    while (true) {
        if (!(buffer.*.cursor <= buffer.*.data.count)) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 90));
            _ = fprintf(stderr, "cursor: %zu", buffer.*.cursor);
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    while (true) {
        if (!(buffer.*.rows.count >= @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))))) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 91));
            _ = fprintf(stderr, "there must be at least one line");
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    {
        var i: usize = 0;
        _ = &i;
        while (i < buffer.*.rows.count) : (i +%= 1) {
            if ((buffer.*.rows.data[i].start <= buffer.*.cursor) and (buffer.*.cursor <= buffer.*.rows.data[i].end)) {
                return i;
            }
        }
    }
    return 0;
}
pub export fn index_get_row(arg_buffer: [*c]Buffer, arg_index_1: usize) usize {
    var buffer = arg_buffer;
    _ = &buffer;
    var index_1 = arg_index_1;
    _ = &index_1;
    while (true) {
        if (!(index_1 <= buffer.*.data.count)) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 102));
            _ = fprintf(stderr, "index: %zu", index_1);
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    while (true) {
        if (!(buffer.*.rows.count >= @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))))) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 103));
            _ = fprintf(stderr, "there must be at least one line");
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    {
        var i: usize = 0;
        _ = &i;
        while (i < buffer.*.rows.count) : (i +%= 1) {
            if ((buffer.*.rows.data[i].start <= index_1) and (index_1 <= buffer.*.rows.data[i].end)) {
                return i;
            }
        }
    }
    return 0;
}
pub export fn buffer_yank_line(arg_buffer: [*c]Buffer, arg_state: [*c]State, arg_offset: usize) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    var offset = arg_offset;
    _ = &offset;
    var row: usize = buffer_get_row(buffer);
    _ = &row;
    if (offset > index_get_row(buffer, buffer.*.data.count)) return;
    var cur: Row = buffer.*.rows.data[row +% offset];
    _ = &cur;
    var line_offset: c_int = 0;
    _ = &line_offset;
    var initial_s: usize = state.*.clipboard.len;
    _ = &initial_s;
    state.*.clipboard.len = (cur.end -% cur.start) +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    state.*.clipboard.str = @as([*c]u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.clipboard.str)), initial_s +% (state.*.clipboard.len *% @sizeOf(u8))))));
    if (row > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        line_offset = -@as(c_int, 1);
    } else {
        state.*.clipboard.len -%= 1;
        initial_s +%= 1;
        state.*.clipboard.str[@as(c_uint, @intCast(@as(c_int, 0)))] = '\n';
    }
    while (true) {
        if (!(state.*.clipboard.str != @as([*c]u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 129));
            _ = fprintf(stderr, "clipboard was null");
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    _ = strncpy(state.*.clipboard.str + initial_s, (buffer.*.data.data + cur.start) + @as(usize, @bitCast(@as(isize, @intCast(line_offset)))), state.*.clipboard.len);
    state.*.clipboard.len +%= initial_s;
}
pub export fn buffer_yank_char(arg_buffer: [*c]Buffer, arg_state: [*c]State) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    reset_command(state.*.clipboard.str, &state.*.clipboard.len);
    state.*.clipboard.len = 2;
    state.*.clipboard.str = @as([*c]u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.clipboard.str)), state.*.clipboard.len *% @sizeOf(u8)))));
    while (true) {
        if (!(state.*.clipboard.str != @as([*c]u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 140));
            _ = fprintf(stderr, "clipboard was null");
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    _ = strncpy(state.*.clipboard.str, buffer.*.data.data + buffer.*.cursor, state.*.clipboard.len);
}
pub export fn buffer_yank_selection(arg_buffer: [*c]Buffer, arg_state: [*c]State, arg_start: usize, arg_end: usize) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    var start = arg_start;
    _ = &start;
    var end = arg_end;
    _ = &end;
    state.*.clipboard.len = (end -% start) +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    state.*.clipboard.str = @as([*c]u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.clipboard.str)), (state.*.clipboard.len *% @sizeOf(u8)) +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
    while (true) {
        if (!(state.*.clipboard.str != @as([*c]u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 148));
            _ = fprintf(stderr, "clipboard was null %zu", state.*.clipboard.len);
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    _ = strncpy(state.*.clipboard.str, buffer.*.data.data + start, state.*.clipboard.len);
}
pub export fn buffer_delete_selection(arg_buffer: [*c]Buffer, arg_state: [*c]State, arg_start: usize, arg_end: usize) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    var start = arg_start;
    _ = &start;
    var end = arg_end;
    _ = &end;
    buffer_yank_selection(buffer, state, start, end);
    var size: usize = end -% start;
    _ = &size;
    if (size >= buffer.*.data.count) {
        size = buffer.*.data.count;
    }
    buffer.*.cursor = start;
    if ((buffer.*.cursor +% size) > buffer.*.data.count) return;
    if (state.*.cur_undo.data.capacity < size) {
        state.*.cur_undo.data.capacity = size;
        state.*.cur_undo.data.data = @as([*c]u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(state.*.cur_undo.data.data)), @sizeOf(u8) *% size))));
        while (true) {
            if (!(state.*.cur_undo.data.data != @as([*c]u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
                frontend_end();
                _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 166));
                _ = fprintf(stderr, "could not alloc");
                _ = fprintf(stderr, "\n");
                exit(@as(c_int, 1));
            }
            if (!false) break;
        }
    }
    _ = strncpy(state.*.cur_undo.data.data, &buffer.*.data.data[buffer.*.cursor], size);
    state.*.cur_undo.data.count = size;
    _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% size])), buffer.*.data.count -% end);
    buffer.*.data.count -%= size;
    buffer_calculate_rows(buffer);
}
pub export fn buffer_insert_selection(arg_buffer: [*c]Buffer, arg_selection: [*c]Data, arg_start: usize) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var selection = arg_selection;
    _ = &selection;
    var start = arg_start;
    _ = &start;
    buffer.*.cursor = start;
    var size: usize = selection.*.count;
    _ = &size;
    if ((buffer.*.data.count +% size) >= buffer.*.data.capacity) {
        buffer.*.data.capacity +%= size *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
        buffer.*.data.data = @as([*c]u8, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(buffer.*.data.data)), (@sizeOf(u8) *% buffer.*.data.capacity) +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
        while (true) {
            if (!(buffer.*.data.data != @as([*c]u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
                frontend_end();
                _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/buffer.c", @as(c_int, 187));
                _ = fprintf(stderr, "could not alloc");
                _ = fprintf(stderr, "\n");
                exit(@as(c_int, 1));
            }
            if (!false) break;
        }
    }
    _ = memmove(@as(?*anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor +% size])), @as(?*const anyopaque, @ptrCast(&buffer.*.data.data[buffer.*.cursor])), buffer.*.data.count -% buffer.*.cursor);
    _ = strncpy(&buffer.*.data.data[buffer.*.cursor], selection.*.data, size);
    buffer.*.data.count +%= size;
    buffer_calculate_rows(buffer);
}
pub export fn buffer_move_up(arg_buffer: [*c]Buffer) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var row: usize = buffer_get_row(buffer);
    _ = &row;
    var col: usize = buffer.*.cursor -% buffer.*.rows.data[row].start;
    _ = &col;
    if (row > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        buffer.*.cursor = buffer.*.rows.data[row -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].start +% col;
        if (buffer.*.cursor > buffer.*.rows.data[row -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].end) {
            buffer.*.cursor = buffer.*.rows.data[row -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].end;
        }
    }
}
pub export fn buffer_move_down(arg_buffer: [*c]Buffer) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var row: usize = buffer_get_row(buffer);
    _ = &row;
    var col: usize = buffer.*.cursor -% buffer.*.rows.data[row].start;
    _ = &col;
    if (row < (buffer.*.rows.count -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))))) {
        buffer.*.cursor = buffer.*.rows.data[row +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].start +% col;
        if (buffer.*.cursor > buffer.*.rows.data[row +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].end) {
            buffer.*.cursor = buffer.*.rows.data[row +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))].end;
        }
    }
}
pub export fn buffer_move_right(arg_buffer: [*c]Buffer) void {
    var buffer = arg_buffer;
    _ = &buffer;
    if (buffer.*.cursor < buffer.*.data.count) {
        buffer.*.cursor +%= 1;
    }
}
pub export fn buffer_move_left(arg_buffer: [*c]Buffer) void {
    var buffer = arg_buffer;
    _ = &buffer;
    if (buffer.*.cursor > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        buffer.*.cursor -%= 1;
    }
}
pub export fn skip_to_char(arg_buffer: [*c]Buffer, arg_cur_pos: c_int, arg_direction: c_int, arg_c: u8) c_int {
    var buffer = arg_buffer;
    _ = &buffer;
    var cur_pos = arg_cur_pos;
    _ = &cur_pos;
    var direction = arg_direction;
    _ = &direction;
    var c = arg_c;
    _ = &c;
    if (@as(c_int, @bitCast(@as(c_uint, (blk: {
        const tmp = cur_pos;
        if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*))) == @as(c_int, @bitCast(@as(c_uint, c)))) {
        cur_pos += direction;
        while (((cur_pos > @as(c_int, 0)) and (cur_pos <= @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) and (@as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = cur_pos;
            if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))) != @as(c_int, @bitCast(@as(c_uint, c))))) {
            if (((cur_pos > @as(c_int, 1)) and (cur_pos < @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) and (@as(c_int, @bitCast(@as(c_uint, (blk: {
                const tmp = cur_pos;
                if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))) == @as(c_int, '\\'))) {
                cur_pos += direction;
            }
            cur_pos += direction;
        }
    }
    return cur_pos;
}
pub export fn buffer_next_brace(arg_buffer: [*c]Buffer) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var cur_pos: c_int = @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.cursor))));
    _ = &cur_pos;
    var initial_brace: Brace = find_opposite_brace((blk: {
        const tmp = cur_pos;
        if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*);
    _ = &initial_brace;
    var brace_stack: usize = 0;
    _ = &brace_stack;
    if (@as(c_int, @bitCast(@as(c_uint, initial_brace.brace))) == @as(c_int, '0')) return;
    var direction: c_int = if (initial_brace.closing != 0) -@as(c_int, 1) else @as(c_int, 1);
    _ = &direction;
    while ((cur_pos >= @as(c_int, 0)) and (cur_pos <= @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) {
        cur_pos += direction;
        cur_pos = skip_to_char(buffer, cur_pos, direction, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '"'))))));
        cur_pos = skip_to_char(buffer, cur_pos, direction, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\''))))));
        var cur_brace: Brace = find_opposite_brace((blk: {
            const tmp = cur_pos;
            if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*);
        _ = &cur_brace;
        if (@as(c_int, @bitCast(@as(c_uint, cur_brace.brace))) == @as(c_int, '0')) continue;
        if (((cur_brace.closing != 0) and (direction == -@as(c_int, 1))) or (!(cur_brace.closing != 0) and (direction == @as(c_int, 1)))) {
            brace_stack +%= 1;
        } else {
            if (((blk: {
                const ref = &brace_stack;
                const tmp = ref.*;
                ref.* -%= 1;
                break :blk tmp;
            }) == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, cur_brace.brace))) == @as(c_int, @bitCast(@as(c_uint, find_opposite_brace(initial_brace.brace).brace))))) {
                buffer.*.cursor = @as(usize, @bitCast(@as(c_long, cur_pos)));
                break;
            }
        }
    }
}
pub export fn isword(arg_ch: u8) c_int {
    var ch = arg_ch;
    _ = &ch;
    if (((@as(c_int, @bitCast(@as(c_uint, (blk: {
        const tmp = @as(c_int, @bitCast(@as(c_uint, ch)));
        if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISalnum)))))))) != 0) or (@as(c_int, @bitCast(@as(c_uint, ch))) == @as(c_int, '_'))) return 1;
    return 0;
}
pub export fn buffer_create_indent(arg_buffer: [*c]Buffer, arg_state: [*c]State) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    if (state.*.config.indent > @as(c_int, 0)) {
        {
            var i: usize = 0;
            _ = &i;
            while (i < (@as(usize, @bitCast(@as(c_long, state.*.config.indent))) *% state.*.num_of_braces)) : (i +%= 1) {
                buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, ' '))))));
            }
        }
    } else {
        {
            var i: usize = 0;
            _ = &i;
            while (i < state.*.num_of_braces) : (i +%= 1) {
                buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\t'))))));
            }
        }
    }
}
pub export fn buffer_newline_indent(arg_buffer: [*c]Buffer, arg_state: [*c]State) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    buffer_insert_char(state, buffer, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\n'))))));
    buffer_create_indent(buffer, state);
}
pub export fn init_state() State {
    var state: State = State{
        .undo_stack = Undo_Stack{
            .data = null,
            .count = @import("std").mem.zeroes(usize),
            .capacity = @import("std").mem.zeroes(usize),
        },
        .redo_stack = @import("std").mem.zeroes(Undo_Stack),
        .cur_undo = @import("std").mem.zeroes(Undo),
        .num_of_braces = @import("std").mem.zeroes(usize),
        .ch = 0,
        .env = null,
        .command = null,
        .command_s = @import("std").mem.zeroes(usize),
        .variables = @import("std").mem.zeroes(Variables),
        .repeating = @import("std").mem.zeroes(Repeating),
        .num = @import("std").mem.zeroes(Data),
        .leader = @import("std").mem.zeroes(Leader),
        .is_print_msg = false,
        .status_bar_msg = null,
        .x = @import("std").mem.zeroes(usize),
        .y = @import("std").mem.zeroes(usize),
        .normal_pos = @import("std").mem.zeroes(usize),
        .key_func = null,
        .clipboard = @import("std").mem.zeroes(Sized_Str),
        .files = null,
        .is_exploring = false,
        .explore_cursor = @import("std").mem.zeroes(usize),
        .buffer = null,
        .grow = 0,
        .gcol = 0,
        .main_row = 0,
        .main_col = 0,
        .line_num_row = 0,
        .line_num_col = 0,
        .status_bar_row = 0,
        .status_bar_col = 0,
        .line_num_win = null,
        .main_win = null,
        .status_bar = null,
        .config = @import("std").mem.zeroes(Config),
    };
    _ = &state;
    state.config = Config{
        .relative_nums = @as(c_int, 0),
        .auto_indent = 0,
        .syntax = 0,
        .indent = 0,
        .undo_size = 0,
        .lang = null,
        .QUIT = 0,
        .mode = @import("std").mem.zeroes(Mode),
        .background_color = 0,
        .leaders = @import("std").mem.zeroes([4]u8),
        .key_maps = @import("std").mem.zeroes(Maps),
        .vars = @import("std").mem.zeroes([5]Config_Vars),
    };
    state.config.relative_nums = 1;
    state.config.auto_indent = 1;
    state.config.syntax = 1;
    state.config.indent = 0;
    state.config.undo_size = 16;
    state.config.lang = @ptrCast(" ".ptr);
    state.config.QUIT = 0;
    state.config.mode = @as(c_uint, @bitCast(NORMAL));
    state.config.background_color = -@as(c_int, 1);
    state.config.leaders[@as(c_uint, @intCast(@as(c_int, 0)))] = ' ';
    state.config.leaders[@as(c_uint, @intCast(@as(c_int, 1)))] = 'r';
    state.config.leaders[@as(c_uint, @intCast(@as(c_int, 2)))] = 'd';
    state.config.leaders[@as(c_uint, @intCast(@as(c_int, 3)))] = 'y';
    state.config.key_maps = Maps{
        .data = null,
        .count = @import("std").mem.zeroes(usize),
        .capacity = @import("std").mem.zeroes(usize),
    };
    state.config.vars[@as(c_uint, @intCast(@as(c_int, 0)))] = Config_Vars{
        .label = String_View{
            .data = @as([*c]u8, @ptrCast(@volatileCast(@constCast("syntax")))),
            .len = @sizeOf([7]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
        },
        .val = &state.config.syntax,
    };
    state.config.vars[@as(c_uint, @intCast(@as(c_int, 1)))] = Config_Vars{
        .label = String_View{
            .data = @as([*c]u8, @ptrCast(@volatileCast(@constCast("indent")))),
            .len = @sizeOf([7]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
        },
        .val = &state.config.indent,
    };
    state.config.vars[@as(c_uint, @intCast(@as(c_int, 2)))] = Config_Vars{
        .label = String_View{
            .data = @as([*c]u8, @ptrCast(@volatileCast(@constCast("auto-indent")))),
            .len = @sizeOf([12]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
        },
        .val = &state.config.auto_indent,
    };
    state.config.vars[@as(c_uint, @intCast(@as(c_int, 3)))] = Config_Vars{
        .label = String_View{
            .data = @as([*c]u8, @ptrCast(@volatileCast(@constCast("undo-size")))),
            .len = @sizeOf([10]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
        },
        .val = &state.config.undo_size,
    };
    state.config.vars[@as(c_uint, @intCast(@as(c_int, 4)))] = Config_Vars{
        .label = String_View{
            .data = @as([*c]u8, @ptrCast(@volatileCast(@constCast("relative")))),
            .len = @sizeOf([9]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))),
        },
        .val = &state.config.relative_nums,
    };
    return state;
}
pub const wchar_t = c_int;
pub const div_t = extern struct {
    quot: c_int = @import("std").mem.zeroes(c_int),
    rem: c_int = @import("std").mem.zeroes(c_int),
};
pub const ldiv_t = extern struct {
    quot: c_long = @import("std").mem.zeroes(c_long),
    rem: c_long = @import("std").mem.zeroes(c_long),
};
pub const lldiv_t = extern struct {
    quot: c_longlong = @import("std").mem.zeroes(c_longlong),
    rem: c_longlong = @import("std").mem.zeroes(c_longlong),
};
pub extern fn calloc(__nmemb: c_ulong, __size: c_ulong) ?*anyopaque;
pub extern fn realloc(__ptr: ?*anyopaque, __size: c_ulong) ?*anyopaque;
pub extern fn free(__ptr: ?*anyopaque) void;
pub extern fn exit(__status: c_int) noreturn;
pub extern fn memcpy(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
pub extern fn memmove(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
pub extern fn strncpy(__dest: [*c]u8, __src: [*c]const u8, __n: c_ulong) [*c]u8;
pub extern fn frontend_getch(window: [*c]WINDOW) c_int;
pub extern fn frontend_end() void;
pub extern fn undo_push(state: [*c]State, stack: [*c]Undo_Stack, undo: Undo) void;
pub extern fn find_opposite_brace(opening: u8) Brace;
pub extern fn reset_command(command: [*c]u8, command_s: [*c]usize) void;
