const vw = @import("view.zig");
const defs = @import("defs.zig");

const std = @import("std");

pub const State = defs.State;
pub const String_View = defs.String_View;
const Config_Vars = defs.Config_Vars;

const Buffer = defs.Buffer;
const Map = defs.Map;

// pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
// pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
// pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
// pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
// pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
// pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
// pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
// pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
// pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
// pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
// pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
// pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
// pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
// pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
// pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
// pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
// pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
// pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
// pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
// pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
// pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
// pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
// pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
// pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
// pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
// pub const __builtin_labs = @import("std").zig.c_builtins.__builtin_labs;
// pub const __builtin_llabs = @import("std").zig.c_builtins.__builtin_llabs;
// pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
// pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
// pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
// pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
// pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
// pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
// pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
// pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
// pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
// pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
// pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
// pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
// pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
// pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
// pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
// pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
// pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
// pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
// pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
// pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
// pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
// pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
// pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
// pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
// pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
// pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
// pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
// pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
// pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
// pub const __u_char = u8;
// pub const __u_short = c_ushort;
// pub const __u_int = c_uint;
// pub const __u_long = c_ulong;
// pub const __int8_t = i8;
// pub const __uint8_t = u8;
// pub const __int16_t = c_short;
// pub const __uint16_t = c_ushort;
// pub const __int32_t = c_int;
// pub const __uint32_t = c_uint;
// pub const __int64_t = c_long;
// pub const __uint64_t = c_ulong;
// pub const __int_least8_t = __int8_t;
// pub const __uint_least8_t = __uint8_t;
// pub const __int_least16_t = __int16_t;
// pub const __uint_least16_t = __uint16_t;
// pub const __int_least32_t = __int32_t;
// pub const __uint_least32_t = __uint32_t;
// pub const __int_least64_t = __int64_t;
// pub const __uint_least64_t = __uint64_t;
// pub const __quad_t = c_long;
// pub const __u_quad_t = c_ulong;
// pub const __intmax_t = c_long;
// pub const __uintmax_t = c_ulong;
// pub const __dev_t = c_ulong;
// pub const __uid_t = c_uint;
// pub const __gid_t = c_uint;
// pub const __ino_t = c_ulong;
// pub const __ino64_t = c_ulong;
// pub const __mode_t = c_uint;
// pub const __nlink_t = c_ulong;
// pub const __off_t = c_long;
// pub const __off64_t = c_long;
// pub const __pid_t = c_int;
// pub const __fsid_t = extern struct {
//     __val: [2]c_int = @import("std").mem.zeroes([2]c_int),
// };
// pub const __clock_t = c_long;
// pub const __rlim_t = c_ulong;
// pub const __rlim64_t = c_ulong;
// pub const __id_t = c_uint;
// pub const __time_t = c_long;
// pub const __useconds_t = c_uint;
// pub const __suseconds_t = c_long;
// pub const __suseconds64_t = c_long;
// pub const __daddr_t = c_int;
// pub const __key_t = c_int;
// pub const __clockid_t = c_int;
// pub const __timer_t = ?*anyopaque;
// pub const __blksize_t = c_long;
// pub const __blkcnt_t = c_long;
// pub const __blkcnt64_t = c_long;
// pub const __fsblkcnt_t = c_ulong;
// pub const __fsblkcnt64_t = c_ulong;
// pub const __fsfilcnt_t = c_ulong;
// pub const __fsfilcnt64_t = c_ulong;
// pub const __fsword_t = c_long;
// pub const __ssize_t = c_long;
// pub const __syscall_slong_t = c_long;
// pub const __syscall_ulong_t = c_ulong;
// pub const __loff_t = __off64_t;
// pub const __caddr_t = *u8;
// pub const __intptr_t = c_long;
// pub const __socklen_t = c_uint;
// pub const __sig_atomic_t = c_int;
// pub const int_least8_t = __int_least8_t;
// pub const int_least16_t = __int_least16_t;
// pub const int_least32_t = __int_least32_t;
// pub const int_least64_t = __int_least64_t;
// pub const uint_least8_t = __uint_least8_t;
// pub const uint_least16_t = __uint_least16_t;
// pub const uint_least32_t = __uint_least32_t;
// pub const uint_least64_t = __uint_least64_t;
// pub const int_fast8_t = i8;
// pub const int_fast16_t = c_long;
// pub const int_fast32_t = c_long;
// pub const int_fast64_t = c_long;
// pub const uint_fast8_t = u8;
// pub const uint_fast16_t = c_ulong;
// pub const uint_fast32_t = c_ulong;
// pub const uint_fast64_t = c_ulong;
// pub const intmax_t = __intmax_t;
// pub const uintmax_t = __uintmax_t;
// pub const chtype = c_uint;
// pub const mmask_t = c_uint;
// pub const struct___va_list_tag_1 = extern struct {
//     gp_offset: c_uint = @import("std").mem.zeroes(c_uint),
//     fp_offset: c_uint = @import("std").mem.zeroes(c_uint),
//     overflow_arg_area: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
//     reg_save_area: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
// };
// pub const __builtin_va_list = [1]struct___va_list_tag_1;
// pub const __gnuc_va_list = __builtin_va_list;
// const union_unnamed_2 = extern union {
//     __wch: c_uint,
//     __wchb: [4]u8,
// };
// pub const __mbstate_t = extern struct {
//     __count: c_int = @import("std").mem.zeroes(c_int),
//     __value: union_unnamed_2 = @import("std").mem.zeroes(union_unnamed_2),
// };
// pub const struct__G_fpos_t = extern struct {
//     __pos: __off_t = @import("std").mem.zeroes(__off_t),
//     __state: __mbstate_t = @import("std").mem.zeroes(__mbstate_t),
// };
// pub const __fpos_t = struct__G_fpos_t;
// pub const struct__G_fpos64_t = extern struct {
//     __pos: __off64_t = @import("std").mem.zeroes(__off64_t),
//     __state: __mbstate_t = @import("std").mem.zeroes(__mbstate_t),
// };
// pub const __fpos64_t = struct__G_fpos64_t;
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
// pub const __FILE = struct__IO_FILE;
pub const FILE = std.c.FILE;
// pub const cookie_read_function_t = fn (?*anyopaque, *u8, usize) callconv(.C) __ssize_t;
// pub const cookie_write_function_t = fn (?*anyopaque, *const u8, usize) callconv(.C) __ssize_t;
// pub const cookie_seek_function_t = fn (?*anyopaque, *__off64_t, c_int) callconv(.C) c_int;
// pub const cookie_close_function_t = fn (?*anyopaque) callconv(.C) c_int;
// pub const struct__IO_cookie_io_functions_t = extern struct {
//     read: ?*const cookie_read_function_t = @import("std").mem.zeroes(?*const cookie_read_function_t),
//     write: ?*const cookie_write_function_t = @import("std").mem.zeroes(?*const cookie_write_function_t),
//     seek: ?*const cookie_seek_function_t = @import("std").mem.zeroes(?*const cookie_seek_function_t),
//     close: ?*const cookie_close_function_t = @import("std").mem.zeroes(?*const cookie_close_function_t),
// };
// pub const cookie_io_functions_t = struct__IO_cookie_io_functions_t;
// pub const va_list = __gnuc_va_list;
// pub const off_t = __off_t;
// pub const fpos_t = __fpos_t;
// pub extern var stdin: *FILE;
// pub extern var stdout: *FILE;
pub extern var stderr: *FILE;
// pub extern fn remove(__filename: *const u8) c_int;
// pub extern fn rename(__old: *const u8, __new: *const u8) c_int;
// pub extern fn renameat(__oldfd: c_int, __old: *const u8, __newfd: c_int, __new: *const u8) c_int;
pub extern fn fclose(__stream: *FILE) c_int;
// pub extern fn tmpfile() *FILE;
// pub extern fn tmpnam(*u8) *u8;
// pub extern fn tmpnam_r(__s: *u8) *u8;
// pub extern fn tempnam(__dir: *const u8, __pfx: *const u8) *u8;
// pub extern fn fflush(__stream: *FILE) c_int;
// pub extern fn fflush_unlocked(__stream: *FILE) c_int;
pub extern fn fopen(__filename: *const u8, __modes: *const u8) *FILE;
// pub extern fn freopen(noalias __filename: *const u8, noalias __modes: *const u8, noalias __stream: *FILE) *FILE;
// pub extern fn fdopen(__fd: c_int, __modes: *const u8) *FILE;
// pub extern fn fopencookie(noalias __magic_cookie: ?*anyopaque, noalias __modes: *const u8, __io_funcs: cookie_io_functions_t) *FILE;
// pub extern fn fmemopen(__s: ?*anyopaque, __len: usize, __modes: *const u8) *FILE;
// pub extern fn open_memstream(__bufloc: **u8, __sizeloc: *usize) *FILE;
// pub extern fn setbuf(noalias __stream: *FILE, noalias __buf: *u8) void;
// pub extern fn setvbuf(noalias __stream: *FILE, noalias __buf: *u8, __modes: c_int, __n: usize) c_int;
// pub extern fn setbuffer(noalias __stream: *FILE, noalias __buf: *u8, __size: usize) void;
// pub extern fn setlinebuf(__stream: *FILE) void;
pub extern fn fprintf(__stream: *FILE, __format: *const u8, ...) c_int;
pub extern fn printf(__format: *const u8, ...) c_int;
pub extern fn sprintf(__s: *u8, __format: *const u8, ...) c_int;
// pub extern fn vfprintf(__s: *FILE, __format: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn vprintf(__format: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn vsprintf(__s: *u8, __format: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn snprintf(__s: *u8, __maxlen: c_ulong, __format: *const u8, ...) c_int;
// pub extern fn vsnprintf(__s: *u8, __maxlen: c_ulong, __format: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn vasprintf(noalias __ptr: **u8, noalias __f: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn __asprintf(noalias __ptr: **u8, noalias __fmt: *const u8, ...) c_int;
// pub extern fn asprintf(noalias __ptr: **u8, noalias __fmt: *const u8, ...) c_int;
// pub extern fn vdprintf(__fd: c_int, noalias __fmt: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn dprintf(__fd: c_int, noalias __fmt: *const u8, ...) c_int;
// pub extern fn fscanf(noalias __stream: *FILE, noalias __format: *const u8, ...) c_int;
// pub extern fn scanf(noalias __format: *const u8, ...) c_int;
// pub extern fn sscanf(noalias __s: *const u8, noalias __format: *const u8, ...) c_int;
// pub const _Float32 = f32;
// pub const _Float64 = f64;
// pub const _Float32x = f64;
// pub const _Float64x = c_longdouble;
// pub extern fn vfscanf(noalias __s: *FILE, noalias __format: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn vscanf(noalias __format: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn vsscanf(noalias __s: *const u8, noalias __format: *const u8, __arg: *struct___va_list_tag_1) c_int;
// pub extern fn fgetc(__stream: *FILE) c_int;
// pub extern fn getc(__stream: *FILE) c_int;
// pub extern fn getchar() c_int;
// pub extern fn getc_unlocked(__stream: *FILE) c_int;
// pub extern fn getchar_unlocked() c_int;
// pub extern fn fgetc_unlocked(__stream: *FILE) c_int;
// pub extern fn fputc(__c: c_int, __stream: *FILE) c_int;
// pub extern fn putc(__c: c_int, __stream: *FILE) c_int;
// pub extern fn putchar(__c: c_int) c_int;
// pub extern fn fputc_unlocked(__c: c_int, __stream: *FILE) c_int;
// pub extern fn putc_unlocked(__c: c_int, __stream: *FILE) c_int;
// pub extern fn putchar_unlocked(__c: c_int) c_int;
// pub extern fn getw(__stream: *FILE) c_int;
// pub extern fn putw(__w: c_int, __stream: *FILE) c_int;
// pub extern fn fgets(noalias __s: *u8, __n: c_int, noalias __stream: *FILE) *u8;
// pub extern fn __getdelim(noalias __lineptr: **u8, noalias __n: *usize, __delimiter: c_int, noalias __stream: *FILE) __ssize_t;
// pub extern fn getdelim(noalias __lineptr: **u8, noalias __n: *usize, __delimiter: c_int, noalias __stream: *FILE) __ssize_t;
// pub extern fn getline(noalias __lineptr: **u8, noalias __n: *usize, noalias __stream: *FILE) __ssize_t;
// pub extern fn fputs(noalias __s: *const u8, noalias __stream: *FILE) c_int;
// pub extern fn puts(__s: *const u8) c_int;
// pub extern fn ungetc(__c: c_int, __stream: *FILE) c_int;
// pub extern fn fread(__ptr: ?*anyopaque, __size: c_ulong, __n: c_ulong, __stream: *FILE) c_ulong;
// pub extern fn fwrite(__ptr: ?*const anyopaque, __size: c_ulong, __n: c_ulong, __s: *FILE) c_ulong;
// pub extern fn fread_unlocked(noalias __ptr: ?*anyopaque, __size: usize, __n: usize, noalias __stream: *FILE) usize;
// pub extern fn fwrite_unlocked(noalias __ptr: ?*const anyopaque, __size: usize, __n: usize, noalias __stream: *FILE) usize;
// pub extern fn fseek(__stream: *FILE, __off: c_long, __whence: c_int) c_int;
// pub extern fn ftell(__stream: *FILE) c_long;
// pub extern fn rewind(__stream: *FILE) void;
// pub extern fn fseeko(__stream: *FILE, __off: __off_t, __whence: c_int) c_int;
// pub extern fn ftello(__stream: *FILE) __off_t;
// pub extern fn fgetpos(noalias __stream: *FILE, noalias __pos: *fpos_t) c_int;
// pub extern fn fsetpos(__stream: *FILE, __pos: *const fpos_t) c_int;
// pub extern fn clearerr(__stream: *FILE) void;
// pub extern fn feof(__stream: *FILE) c_int;
// pub extern fn ferror(__stream: *FILE) c_int;
// pub extern fn clearerr_unlocked(__stream: *FILE) void;
// pub extern fn feof_unlocked(__stream: *FILE) c_int;
// pub extern fn ferror_unlocked(__stream: *FILE) c_int;
// pub extern fn perror(__s: *const u8) void;
// pub extern fn fileno(__stream: *FILE) c_int;
// pub extern fn fileno_unlocked(__stream: *FILE) c_int;
// pub extern fn pclose(__stream: *FILE) c_int;
// pub extern fn popen(__command: *const u8, __modes: *const u8) *FILE;
// pub extern fn ctermid(__s: *u8) *u8;
// pub extern fn flockfile(__stream: *FILE) void;
// pub extern fn ftrylockfile(__stream: *FILE) c_int;
// pub extern fn funlockfile(__stream: *FILE) void;
// pub extern fn __uflow(*FILE) c_int;
// pub extern fn __overflow(*FILE, c_int) c_int;
// pub const NCURSES_BOOL = u8;
// pub const acs_map: *chtype = @extern(*chtype, .{
//     .name = "acs_map",
// });
// pub const struct_screen = opaque {};
// pub const SCREEN = struct_screen;
// pub const attr_t = chtype;
// pub const struct_ldat = opaque {};
// pub const WINDOW = struct__win_st;
// pub const struct_pdat_3 = extern struct {
//     _pad_y: c_short = @import("std").mem.zeroes(c_short),
//     _pad_x: c_short = @import("std").mem.zeroes(c_short),
//     _pad_top: c_short = @import("std").mem.zeroes(c_short),
//     _pad_left: c_short = @import("std").mem.zeroes(c_short),
//     _pad_bottom: c_short = @import("std").mem.zeroes(c_short),
//     _pad_right: c_short = @import("std").mem.zeroes(c_short),
// };
// pub const struct__win_st = extern struct {
//     _cury: c_short = @import("std").mem.zeroes(c_short),
//     _curx: c_short = @import("std").mem.zeroes(c_short),
//     _maxy: c_short = @import("std").mem.zeroes(c_short),
//     _maxx: c_short = @import("std").mem.zeroes(c_short),
//     _begy: c_short = @import("std").mem.zeroes(c_short),
//     _begx: c_short = @import("std").mem.zeroes(c_short),
//     _flags: c_short = @import("std").mem.zeroes(c_short),
//     _attrs: attr_t = @import("std").mem.zeroes(attr_t),
//     _bkgd: chtype = @import("std").mem.zeroes(chtype),
//     _notimeout: bool = @import("std").mem.zeroes(bool),
//     _clear: bool = @import("std").mem.zeroes(bool),
//     _leaveok: bool = @import("std").mem.zeroes(bool),
//     _scroll: bool = @import("std").mem.zeroes(bool),
//     _idlok: bool = @import("std").mem.zeroes(bool),
//     _idcok: bool = @import("std").mem.zeroes(bool),
//     _immed: bool = @import("std").mem.zeroes(bool),
//     _sync: bool = @import("std").mem.zeroes(bool),
//     _use_keypad: bool = @import("std").mem.zeroes(bool),
//     _delay: c_int = @import("std").mem.zeroes(c_int),
//     _line: ?*struct_ldat = @import("std").mem.zeroes(?*struct_ldat),
//     _regtop: c_short = @import("std").mem.zeroes(c_short),
//     _regbottom: c_short = @import("std").mem.zeroes(c_short),
//     _parx: c_int = @import("std").mem.zeroes(c_int),
//     _pary: c_int = @import("std").mem.zeroes(c_int),
//     _parent: *WINDOW = @import("std").mem.zeroes(*WINDOW),
//     _pad: struct_pdat_3 = @import("std").mem.zeroes(struct_pdat_3),
//     _yoffset: c_short = @import("std").mem.zeroes(c_short),
// };
// pub const NCURSES_OUTC = ?*const fn (c_int) callconv(.C) c_int;
// pub extern fn addch(chtype) c_int;
// pub extern fn addchnstr(*const chtype, c_int) c_int;
// pub extern fn addchstr(*const chtype) c_int;
// pub extern fn addnstr(*const u8, c_int) c_int;
// pub extern fn addstr(*const u8) c_int;
// pub extern fn attroff(c_int) c_int;
// pub extern fn attron(c_int) c_int;
// pub extern fn attrset(c_int) c_int;
// pub extern fn attr_get(*attr_t, *c_short, ?*anyopaque) c_int;
// pub extern fn attr_off(attr_t, ?*anyopaque) c_int;
// pub extern fn attr_on(attr_t, ?*anyopaque) c_int;
// pub extern fn attr_set(attr_t, c_short, ?*anyopaque) c_int;
// pub extern fn baudrate() c_int;
// pub extern fn beep() c_int;
// pub extern fn bkgd(chtype) c_int;
// pub extern fn bkgdset(chtype) void;
// pub extern fn border(chtype, chtype, chtype, chtype, chtype, chtype, chtype, chtype) c_int;
// pub extern fn box(*WINDOW, chtype, chtype) c_int;
// pub extern fn can_change_color() bool;
// pub extern fn cbreak() c_int;
// pub extern fn chgat(c_int, attr_t, c_short, ?*const anyopaque) c_int;
// pub extern fn clear() c_int;
// pub extern fn clearok(*WINDOW, bool) c_int;
// pub extern fn clrtobot() c_int;
// pub extern fn clrtoeol() c_int;
// pub extern fn color_content(c_short, *c_short, *c_short, *c_short) c_int;
// pub extern fn color_set(c_short, ?*anyopaque) c_int;
// pub extern fn COLOR_PAIR(c_int) c_int;
// pub extern fn copywin(*const WINDOW, *WINDOW, c_int, c_int, c_int, c_int, c_int, c_int, c_int) c_int;
// pub extern fn curs_set(c_int) c_int;
// pub extern fn def_prog_mode() c_int;
// pub extern fn def_shell_mode() c_int;
// pub extern fn delay_output(c_int) c_int;
// pub extern fn delch() c_int;
// pub extern fn delscreen(?*SCREEN) void;
// pub extern fn delwin(*WINDOW) c_int;
// pub extern fn deleteln() c_int;
// pub extern fn derwin(*WINDOW, c_int, c_int, c_int, c_int) *WINDOW;
// pub extern fn doupdate() c_int;
// pub extern fn dupwin(*WINDOW) *WINDOW;
// pub extern fn echo() c_int;
// pub extern fn echochar(chtype) c_int;
// pub extern fn erase() c_int;
// pub extern fn endwin() c_int;
// pub extern fn erasechar() u8;
// pub extern fn filter() void;
// pub extern fn flash() c_int;
// pub extern fn flushinp() c_int;
// pub extern fn getbkgd(*WINDOW) chtype;
// pub extern fn getch() c_int;
// pub extern fn getnstr(*u8, c_int) c_int;
// pub extern fn getstr(*u8) c_int;
// pub extern fn getwin(*FILE) *WINDOW;
// pub extern fn halfdelay(c_int) c_int;
// pub extern fn has_colors() bool;
// pub extern fn has_ic() bool;
// pub extern fn has_il() bool;
// pub extern fn hline(chtype, c_int) c_int;
// pub extern fn idcok(*WINDOW, bool) void;
// pub extern fn idlok(*WINDOW, bool) c_int;
// pub extern fn immedok(*WINDOW, bool) void;
// pub extern fn inch() chtype;
// pub extern fn inchnstr(*chtype, c_int) c_int;
// pub extern fn inchstr(*chtype) c_int;
// pub extern fn initscr() *WINDOW;
// pub extern fn init_color(c_short, c_short, c_short, c_short) c_int;
// pub extern fn init_pair(c_short, c_short, c_short) c_int;
// pub extern fn innstr(*u8, c_int) c_int;
// pub extern fn insch(chtype) c_int;
// pub extern fn insdelln(c_int) c_int;
// pub extern fn insertln() c_int;
// pub extern fn insnstr(*const u8, c_int) c_int;
// pub extern fn insstr(*const u8) c_int;
// pub extern fn instr(*u8) c_int;
// pub extern fn intrflush(*WINDOW, bool) c_int;
// pub extern fn isendwin() bool;
// pub extern fn is_linetouched(*WINDOW, c_int) bool;
// pub extern fn is_wintouched(*WINDOW) bool;
// pub extern fn keyname(c_int) *const u8;
// pub extern fn keypad(*WINDOW, bool) c_int;
// pub extern fn killchar() u8;
// pub extern fn leaveok(*WINDOW, bool) c_int;
// pub extern fn longname() *u8;
// pub extern fn meta(*WINDOW, bool) c_int;
// pub extern fn move(c_int, c_int) c_int;
// pub extern fn mvaddch(c_int, c_int, chtype) c_int;
// pub extern fn mvaddchnstr(c_int, c_int, *const chtype, c_int) c_int;
// pub extern fn mvaddchstr(c_int, c_int, *const chtype) c_int;
// pub extern fn mvaddnstr(c_int, c_int, *const u8, c_int) c_int;
// pub extern fn mvaddstr(c_int, c_int, *const u8) c_int;
// pub extern fn mvchgat(c_int, c_int, c_int, attr_t, c_short, ?*const anyopaque) c_int;
// pub extern fn mvcur(c_int, c_int, c_int, c_int) c_int;
// pub extern fn mvdelch(c_int, c_int) c_int;
// pub extern fn mvderwin(*WINDOW, c_int, c_int) c_int;
// pub extern fn mvgetch(c_int, c_int) c_int;
// pub extern fn mvgetnstr(c_int, c_int, *u8, c_int) c_int;
// pub extern fn mvgetstr(c_int, c_int, *u8) c_int;
// pub extern fn mvhline(c_int, c_int, chtype, c_int) c_int;
// pub extern fn mvinch(c_int, c_int) chtype;
// pub extern fn mvinchnstr(c_int, c_int, *chtype, c_int) c_int;
// pub extern fn mvinchstr(c_int, c_int, *chtype) c_int;
// pub extern fn mvinnstr(c_int, c_int, *u8, c_int) c_int;
// pub extern fn mvinsch(c_int, c_int, chtype) c_int;
// pub extern fn mvinsnstr(c_int, c_int, *const u8, c_int) c_int;
// pub extern fn mvinsstr(c_int, c_int, *const u8) c_int;
// pub extern fn mvinstr(c_int, c_int, *u8) c_int;
// pub extern fn mvprintw(c_int, c_int, *const u8, ...) c_int;
// pub extern fn mvscanw(c_int, c_int, *const u8, ...) c_int;
// pub extern fn mvvline(c_int, c_int, chtype, c_int) c_int;
// pub extern fn mvwaddch(*WINDOW, c_int, c_int, chtype) c_int;
// pub extern fn mvwaddchnstr(*WINDOW, c_int, c_int, *const chtype, c_int) c_int;
// pub extern fn mvwaddchstr(*WINDOW, c_int, c_int, *const chtype) c_int;
// pub extern fn mvwaddnstr(*WINDOW, c_int, c_int, *const u8, c_int) c_int;
// pub extern fn mvwaddstr(*WINDOW, c_int, c_int, *const u8) c_int;
// pub extern fn mvwchgat(*WINDOW, c_int, c_int, c_int, attr_t, c_short, ?*const anyopaque) c_int;
// pub extern fn mvwdelch(*WINDOW, c_int, c_int) c_int;
// pub extern fn mvwgetch(*WINDOW, c_int, c_int) c_int;
// pub extern fn mvwgetnstr(*WINDOW, c_int, c_int, *u8, c_int) c_int;
// pub extern fn mvwgetstr(*WINDOW, c_int, c_int, *u8) c_int;
// pub extern fn mvwhline(*WINDOW, c_int, c_int, chtype, c_int) c_int;
// pub extern fn mvwin(*WINDOW, c_int, c_int) c_int;
// pub extern fn mvwinch(*WINDOW, c_int, c_int) chtype;
// pub extern fn mvwinchnstr(*WINDOW, c_int, c_int, *chtype, c_int) c_int;
// pub extern fn mvwinchstr(*WINDOW, c_int, c_int, *chtype) c_int;
// pub extern fn mvwinnstr(*WINDOW, c_int, c_int, *u8, c_int) c_int;
// pub extern fn mvwinsch(*WINDOW, c_int, c_int, chtype) c_int;
// pub extern fn mvwinsnstr(*WINDOW, c_int, c_int, *const u8, c_int) c_int;
// pub extern fn mvwinsstr(*WINDOW, c_int, c_int, *const u8) c_int;
// pub extern fn mvwinstr(*WINDOW, c_int, c_int, *u8) c_int;
// pub extern fn mvwprintw(*WINDOW, c_int, c_int, *const u8, ...) c_int;
// pub extern fn mvwscanw(*WINDOW, c_int, c_int, *const u8, ...) c_int;
// pub extern fn mvwvline(*WINDOW, c_int, c_int, chtype, c_int) c_int;
// pub extern fn napms(c_int) c_int;
// pub extern fn newpad(c_int, c_int) *WINDOW;
// pub extern fn newterm(*const u8, *FILE, *FILE) ?*SCREEN;
// pub extern fn newwin(c_int, c_int, c_int, c_int) *WINDOW;
// pub extern fn nl() c_int;
// pub extern fn nocbreak() c_int;
// pub extern fn nodelay(*WINDOW, bool) c_int;
// pub extern fn noecho() c_int;
// pub extern fn nonl() c_int;
// pub extern fn noqiflush() void;
// pub extern fn noraw() c_int;
// pub extern fn notimeout(*WINDOW, bool) c_int;
// pub extern fn overlay(*const WINDOW, *WINDOW) c_int;
// pub extern fn overwrite(*const WINDOW, *WINDOW) c_int;
// pub extern fn pair_content(c_short, *c_short, *c_short) c_int;
// pub extern fn PAIR_NUMBER(c_int) c_int;
// pub extern fn pechochar(*WINDOW, chtype) c_int;
// pub extern fn pnoutrefresh(*WINDOW, c_int, c_int, c_int, c_int, c_int, c_int) c_int;
// pub extern fn prefresh(*WINDOW, c_int, c_int, c_int, c_int, c_int, c_int) c_int;
// pub extern fn printw(*const u8, ...) c_int;
// pub extern fn putwin(*WINDOW, *FILE) c_int;
// pub extern fn qiflush() void;
// pub extern fn raw() c_int;
// pub extern fn redrawwin(*WINDOW) c_int;
// pub extern fn refresh() c_int;
// pub extern fn resetty() c_int;
// pub extern fn reset_prog_mode() c_int;
// pub extern fn reset_shell_mode() c_int;
// pub extern fn ripoffline(c_int, ?*const fn (*WINDOW, c_int) callconv(.C) c_int) c_int;
// pub extern fn savetty() c_int;
// pub extern fn scanw(*const u8, ...) c_int;
// pub extern fn scr_dump(*const u8) c_int;
// pub extern fn scr_init(*const u8) c_int;
// pub extern fn scrl(c_int) c_int;
// pub extern fn scroll(*WINDOW) c_int;
// pub extern fn scrollok(*WINDOW, bool) c_int;
// pub extern fn scr_restore(*const u8) c_int;
// pub extern fn scr_set(*const u8) c_int;
// pub extern fn setscrreg(c_int, c_int) c_int;
// pub extern fn set_term(?*SCREEN) ?*SCREEN;
// pub extern fn slk_attroff(chtype) c_int;
// pub extern fn slk_attr_off(attr_t, ?*anyopaque) c_int;
// pub extern fn slk_attron(chtype) c_int;
// pub extern fn slk_attr_on(attr_t, ?*anyopaque) c_int;
// pub extern fn slk_attrset(chtype) c_int;
// pub extern fn slk_attr() attr_t;
// pub extern fn slk_attr_set(attr_t, c_short, ?*anyopaque) c_int;
// pub extern fn slk_clear() c_int;
// pub extern fn slk_color(c_short) c_int;
// pub extern fn slk_init(c_int) c_int;
// pub extern fn slk_label(c_int) *u8;
// pub extern fn slk_noutrefresh() c_int;
// pub extern fn slk_refresh() c_int;
// pub extern fn slk_restore() c_int;
// pub extern fn slk_set(c_int, *const u8, c_int) c_int;
// pub extern fn slk_touch() c_int;
// pub extern fn standout() c_int;
// pub extern fn standend() c_int;
// pub extern fn start_color() c_int;
// pub extern fn subpad(*WINDOW, c_int, c_int, c_int, c_int) *WINDOW;
// pub extern fn subwin(*WINDOW, c_int, c_int, c_int, c_int) *WINDOW;
// pub extern fn syncok(*WINDOW, bool) c_int;
// pub extern fn termattrs() chtype;
// pub extern fn termname() *u8;
// pub extern fn timeout(c_int) void;
// pub extern fn touchline(*WINDOW, c_int, c_int) c_int;
// pub extern fn touchwin(*WINDOW) c_int;
// pub extern fn typeahead(c_int) c_int;
// pub extern fn ungetch(c_int) c_int;
// pub extern fn untouchwin(*WINDOW) c_int;
// pub extern fn use_env(bool) void;
// pub extern fn use_tioctl(bool) void;
// pub extern fn vidattr(chtype) c_int;
// pub extern fn vidputs(chtype, NCURSES_OUTC) c_int;
// pub extern fn vline(chtype, c_int) c_int;
// pub extern fn vwprintw(*WINDOW, *const u8, *struct___va_list_tag_1) c_int;
// pub extern fn vw_printw(*WINDOW, *const u8, *struct___va_list_tag_1) c_int;
// pub extern fn vwscanw(*WINDOW, *const u8, *struct___va_list_tag_1) c_int;
// pub extern fn vw_scanw(*WINDOW, *const u8, *struct___va_list_tag_1) c_int;
// pub extern fn waddch(*WINDOW, chtype) c_int;
// pub extern fn waddchnstr(*WINDOW, *const chtype, c_int) c_int;
// pub extern fn waddchstr(*WINDOW, *const chtype) c_int;
// pub extern fn waddnstr(*WINDOW, *const u8, c_int) c_int;
// pub extern fn waddstr(*WINDOW, *const u8) c_int;
// pub extern fn wattron(*WINDOW, c_int) c_int;
// pub extern fn wattroff(*WINDOW, c_int) c_int;
// pub extern fn wattrset(*WINDOW, c_int) c_int;
// pub extern fn wattr_get(*WINDOW, *attr_t, *c_short, ?*anyopaque) c_int;
// pub extern fn wattr_on(*WINDOW, attr_t, ?*anyopaque) c_int;
// pub extern fn wattr_off(*WINDOW, attr_t, ?*anyopaque) c_int;
// pub extern fn wattr_set(*WINDOW, attr_t, c_short, ?*anyopaque) c_int;
// pub extern fn wbkgd(*WINDOW, chtype) c_int;
// pub extern fn wbkgdset(*WINDOW, chtype) void;
// pub extern fn wborder(*WINDOW, chtype, chtype, chtype, chtype, chtype, chtype, chtype, chtype) c_int;
// pub extern fn wchgat(*WINDOW, c_int, attr_t, c_short, ?*const anyopaque) c_int;
// pub extern fn wclear(*WINDOW) c_int;
// pub extern fn wclrtobot(*WINDOW) c_int;
// pub extern fn wclrtoeol(*WINDOW) c_int;
// pub extern fn wcolor_set(*WINDOW, c_short, ?*anyopaque) c_int;
// pub extern fn wcursyncup(*WINDOW) void;
// pub extern fn wdelch(*WINDOW) c_int;
// pub extern fn wdeleteln(*WINDOW) c_int;
// pub extern fn wechochar(*WINDOW, chtype) c_int;
// pub extern fn werase(*WINDOW) c_int;
// pub extern fn wgetch(*WINDOW) c_int;
// pub extern fn wgetnstr(*WINDOW, *u8, c_int) c_int;
// pub extern fn wgetstr(*WINDOW, *u8) c_int;
// pub extern fn whline(*WINDOW, chtype, c_int) c_int;
// pub extern fn winch(*WINDOW) chtype;
// pub extern fn winchnstr(*WINDOW, *chtype, c_int) c_int;
// pub extern fn winchstr(*WINDOW, *chtype) c_int;
// pub extern fn winnstr(*WINDOW, *u8, c_int) c_int;
// pub extern fn winsch(*WINDOW, chtype) c_int;
// pub extern fn winsdelln(*WINDOW, c_int) c_int;
// pub extern fn winsertln(*WINDOW) c_int;
// pub extern fn winsnstr(*WINDOW, *const u8, c_int) c_int;
// pub extern fn winsstr(*WINDOW, *const u8) c_int;
// pub extern fn winstr(*WINDOW, *u8) c_int;
// pub extern fn wmove(*WINDOW, c_int, c_int) c_int;
// pub extern fn wnoutrefresh(*WINDOW) c_int;
// pub extern fn wprintw(*WINDOW, *const u8, ...) c_int;
// pub extern fn wredrawln(*WINDOW, c_int, c_int) c_int;
// pub extern fn wrefresh(*WINDOW) c_int;
// pub extern fn wscanw(*WINDOW, *const u8, ...) c_int;
// pub extern fn wscrl(*WINDOW, c_int) c_int;
// pub extern fn wsetscrreg(*WINDOW, c_int, c_int) c_int;
// pub extern fn wstandout(*WINDOW) c_int;
// pub extern fn wstandend(*WINDOW) c_int;
// pub extern fn wsyncdown(*WINDOW) void;
// pub extern fn wsyncup(*WINDOW) void;
// pub extern fn wtimeout(*WINDOW, c_int) void;
// pub extern fn wtouchln(*WINDOW, c_int, c_int, c_int) c_int;
// pub extern fn wvline(*WINDOW, chtype, c_int) c_int;
// pub extern fn tigetflag(*const u8) c_int;
// pub extern fn tigetnum(*const u8) c_int;
// pub extern fn tigetstr(*const u8) *u8;
// pub extern fn putp(*const u8) c_int;
// pub extern fn tparm(*const u8, ...) *u8;
// pub extern fn tiparm(*const u8, ...) *u8;
// pub extern fn getattrs(*const WINDOW) c_int;
// pub extern fn getcurx(*const WINDOW) c_int;
// pub extern fn getcury(*const WINDOW) c_int;
// pub extern fn getbegx(*const WINDOW) c_int;
// pub extern fn getbegy(*const WINDOW) c_int;
// pub extern fn getmaxx(*const WINDOW) c_int;
// pub extern fn getmaxy(*const WINDOW) c_int;
// pub extern fn getparx(*const WINDOW) c_int;
// pub extern fn getpary(*const WINDOW) c_int;
// pub const NCURSES_WINDOW_CB = ?*const fn (*WINDOW, ?*anyopaque) callconv(.C) c_int;
// pub const NCURSES_SCREEN_CB = ?*const fn (?*SCREEN, ?*anyopaque) callconv(.C) c_int;
// pub extern fn is_term_resized(c_int, c_int) bool;
// pub extern fn keybound(c_int, c_int) *u8;
// pub extern fn curses_version() *const u8;
// pub extern fn alloc_pair(c_int, c_int) c_int;
// pub extern fn assume_default_colors(c_int, c_int) c_int;
// pub extern fn define_key(*const u8, c_int) c_int;
// pub extern fn extended_color_content(c_int, *c_int, *c_int, *c_int) c_int;
// pub extern fn extended_pair_content(c_int, *c_int, *c_int) c_int;
// pub extern fn extended_slk_color(c_int) c_int;
// pub extern fn find_pair(c_int, c_int) c_int;
// pub extern fn free_pair(c_int) c_int;
// pub extern fn get_escdelay() c_int;
// pub extern fn init_extended_color(c_int, c_int, c_int, c_int) c_int;
// pub extern fn init_extended_pair(c_int, c_int, c_int) c_int;
// pub extern fn key_defined(*const u8) c_int;
// pub extern fn keyok(c_int, bool) c_int;
// pub extern fn reset_color_pairs() void;
// pub extern fn resize_term(c_int, c_int) c_int;
// pub extern fn resizeterm(c_int, c_int) c_int;
// pub extern fn set_escdelay(c_int) c_int;
// pub extern fn set_tabsize(c_int) c_int;
// pub extern fn use_default_colors() c_int;
// pub extern fn use_extended_names(bool) c_int;
// pub extern fn use_legacy_coding(c_int) c_int;
// pub extern fn use_screen(?*SCREEN, NCURSES_SCREEN_CB, ?*anyopaque) c_int;
// pub extern fn use_window(*WINDOW, NCURSES_WINDOW_CB, ?*anyopaque) c_int;
// pub extern fn wresize(*WINDOW, c_int, c_int) c_int;
// pub extern fn nofilter() void;
// pub extern fn wgetparent(*const WINDOW) *WINDOW;
// pub extern fn is_cleared(*const WINDOW) bool;
// pub extern fn is_idcok(*const WINDOW) bool;
// pub extern fn is_idlok(*const WINDOW) bool;
// pub extern fn is_immedok(*const WINDOW) bool;
// pub extern fn is_keypad(*const WINDOW) bool;
// pub extern fn is_leaveok(*const WINDOW) bool;
// pub extern fn is_nodelay(*const WINDOW) bool;
// pub extern fn is_notimeout(*const WINDOW) bool;
// pub extern fn is_pad(*const WINDOW) bool;
// pub extern fn is_scrollok(*const WINDOW) bool;
// pub extern fn is_subwin(*const WINDOW) bool;
// pub extern fn is_syncok(*const WINDOW) bool;
// pub extern fn wgetdelay(*const WINDOW) c_int;
// pub extern fn wgetscrreg(*const WINDOW, *c_int, *c_int) c_int;
// pub const NCURSES_OUTC_sp = ?*const fn (?*SCREEN, c_int) callconv(.C) c_int;
// pub extern fn new_prescr() ?*SCREEN;
// pub extern fn baudrate_sp(?*SCREEN) c_int;
// pub extern fn beep_sp(?*SCREEN) c_int;
// pub extern fn can_change_color_sp(?*SCREEN) bool;
// pub extern fn cbreak_sp(?*SCREEN) c_int;
// pub extern fn curs_set_sp(?*SCREEN, c_int) c_int;
// pub extern fn color_content_sp(?*SCREEN, c_short, *c_short, *c_short, *c_short) c_int;
// pub extern fn def_prog_mode_sp(?*SCREEN) c_int;
// pub extern fn def_shell_mode_sp(?*SCREEN) c_int;
// pub extern fn delay_output_sp(?*SCREEN, c_int) c_int;
// pub extern fn doupdate_sp(?*SCREEN) c_int;
// pub extern fn echo_sp(?*SCREEN) c_int;
// pub extern fn endwin_sp(?*SCREEN) c_int;
// pub extern fn erasechar_sp(?*SCREEN) u8;
// pub extern fn filter_sp(?*SCREEN) void;
// pub extern fn flash_sp(?*SCREEN) c_int;
// pub extern fn flushinp_sp(?*SCREEN) c_int;
// pub extern fn getwin_sp(?*SCREEN, *FILE) *WINDOW;
// pub extern fn halfdelay_sp(?*SCREEN, c_int) c_int;
// pub extern fn has_colors_sp(?*SCREEN) bool;
// pub extern fn has_ic_sp(?*SCREEN) bool;
// pub extern fn has_il_sp(?*SCREEN) bool;
// pub extern fn init_color_sp(?*SCREEN, c_short, c_short, c_short, c_short) c_int;
// pub extern fn init_pair_sp(?*SCREEN, c_short, c_short, c_short) c_int;
// pub extern fn intrflush_sp(?*SCREEN, *WINDOW, bool) c_int;
// pub extern fn isendwin_sp(?*SCREEN) bool;
// pub extern fn keyname_sp(?*SCREEN, c_int) *const u8;
// pub extern fn killchar_sp(?*SCREEN) u8;
// pub extern fn longname_sp(?*SCREEN) *u8;
// pub extern fn mvcur_sp(?*SCREEN, c_int, c_int, c_int, c_int) c_int;
// pub extern fn napms_sp(?*SCREEN, c_int) c_int;
// pub extern fn newpad_sp(?*SCREEN, c_int, c_int) *WINDOW;
// pub extern fn newterm_sp(?*SCREEN, *const u8, *FILE, *FILE) ?*SCREEN;
// pub extern fn newwin_sp(?*SCREEN, c_int, c_int, c_int, c_int) *WINDOW;
// pub extern fn nl_sp(?*SCREEN) c_int;
// pub extern fn nocbreak_sp(?*SCREEN) c_int;
// pub extern fn noecho_sp(?*SCREEN) c_int;
// pub extern fn nonl_sp(?*SCREEN) c_int;
// pub extern fn noqiflush_sp(?*SCREEN) void;
// pub extern fn noraw_sp(?*SCREEN) c_int;
// pub extern fn pair_content_sp(?*SCREEN, c_short, *c_short, *c_short) c_int;
// pub extern fn qiflush_sp(?*SCREEN) void;
// pub extern fn raw_sp(?*SCREEN) c_int;
// pub extern fn reset_prog_mode_sp(?*SCREEN) c_int;
// pub extern fn reset_shell_mode_sp(?*SCREEN) c_int;
// pub extern fn resetty_sp(?*SCREEN) c_int;
// pub extern fn ripoffline_sp(?*SCREEN, c_int, ?*const fn (*WINDOW, c_int) callconv(.C) c_int) c_int;
// pub extern fn savetty_sp(?*SCREEN) c_int;
// pub extern fn scr_init_sp(?*SCREEN, *const u8) c_int;
// pub extern fn scr_restore_sp(?*SCREEN, *const u8) c_int;
// pub extern fn scr_set_sp(?*SCREEN, *const u8) c_int;
// pub extern fn slk_attroff_sp(?*SCREEN, chtype) c_int;
// pub extern fn slk_attron_sp(?*SCREEN, chtype) c_int;
// pub extern fn slk_attrset_sp(?*SCREEN, chtype) c_int;
// pub extern fn slk_attr_sp(?*SCREEN) attr_t;
// pub extern fn slk_attr_set_sp(?*SCREEN, attr_t, c_short, ?*anyopaque) c_int;
// pub extern fn slk_clear_sp(?*SCREEN) c_int;
// pub extern fn slk_color_sp(?*SCREEN, c_short) c_int;
// pub extern fn slk_init_sp(?*SCREEN, c_int) c_int;
// pub extern fn slk_label_sp(?*SCREEN, c_int) *u8;
// pub extern fn slk_noutrefresh_sp(?*SCREEN) c_int;
// pub extern fn slk_refresh_sp(?*SCREEN) c_int;
// pub extern fn slk_restore_sp(?*SCREEN) c_int;
// pub extern fn slk_set_sp(?*SCREEN, c_int, *const u8, c_int) c_int;
// pub extern fn slk_touch_sp(?*SCREEN) c_int;
// pub extern fn start_color_sp(?*SCREEN) c_int;
// pub extern fn termattrs_sp(?*SCREEN) chtype;
// pub extern fn termname_sp(?*SCREEN) *u8;
// pub extern fn typeahead_sp(?*SCREEN, c_int) c_int;
// pub extern fn ungetch_sp(?*SCREEN, c_int) c_int;
// pub extern fn use_env_sp(?*SCREEN, bool) void;
// pub extern fn use_tioctl_sp(?*SCREEN, bool) void;
// pub extern fn vidattr_sp(?*SCREEN, chtype) c_int;
// pub extern fn vidputs_sp(?*SCREEN, chtype, NCURSES_OUTC_sp) c_int;
// pub extern fn keybound_sp(?*SCREEN, c_int, c_int) *u8;
// pub extern fn alloc_pair_sp(?*SCREEN, c_int, c_int) c_int;
// pub extern fn assume_default_colors_sp(?*SCREEN, c_int, c_int) c_int;
// pub extern fn define_key_sp(?*SCREEN, *const u8, c_int) c_int;
// pub extern fn extended_color_content_sp(?*SCREEN, c_int, *c_int, *c_int, *c_int) c_int;
// pub extern fn extended_pair_content_sp(?*SCREEN, c_int, *c_int, *c_int) c_int;
// pub extern fn extended_slk_color_sp(?*SCREEN, c_int) c_int;
// pub extern fn get_escdelay_sp(?*SCREEN) c_int;
// pub extern fn find_pair_sp(?*SCREEN, c_int, c_int) c_int;
// pub extern fn free_pair_sp(?*SCREEN, c_int) c_int;
// pub extern fn init_extended_color_sp(?*SCREEN, c_int, c_int, c_int, c_int) c_int;
// pub extern fn init_extended_pair_sp(?*SCREEN, c_int, c_int, c_int) c_int;
// pub extern fn is_term_resized_sp(?*SCREEN, c_int, c_int) bool;
// pub extern fn key_defined_sp(?*SCREEN, *const u8) c_int;
// pub extern fn keyok_sp(?*SCREEN, c_int, bool) c_int;
// pub extern fn nofilter_sp(?*SCREEN) void;
// pub extern fn reset_color_pairs_sp(?*SCREEN) void;
// pub extern fn resize_term_sp(?*SCREEN, c_int, c_int) c_int;
// pub extern fn resizeterm_sp(?*SCREEN, c_int, c_int) c_int;
// pub extern fn set_escdelay_sp(?*SCREEN, c_int) c_int;
// pub extern fn set_tabsize_sp(?*SCREEN, c_int) c_int;
// pub extern fn use_default_colors_sp(?*SCREEN) c_int;
// pub extern fn use_legacy_coding_sp(?*SCREEN, c_int) c_int;
// pub extern var curscr: *WINDOW;
// pub extern var newscr: *WINDOW;
// pub extern var stdscr: *WINDOW;
// pub const ttytype: *u8 = @extern(*u8, .{
//     .name = "ttytype",
// });
// pub extern var COLORS: c_int;
// pub extern var COLOR_PAIRS: c_int;
// pub extern var COLS: c_int;
// pub extern var ESCDELAY: c_int;
// pub extern var LINES: c_int;
// pub extern var TABSIZE: c_int;
// pub const MEVENT = extern struct {
//     id: c_short = @import("std").mem.zeroes(c_short),
//     x: c_int = @import("std").mem.zeroes(c_int),
//     y: c_int = @import("std").mem.zeroes(c_int),
//     z: c_int = @import("std").mem.zeroes(c_int),
//     bstate: mmask_t = @import("std").mem.zeroes(mmask_t),
// };
// pub extern fn has_mouse() bool;
// pub extern fn getmouse(*MEVENT) c_int;
// pub extern fn ungetmouse(*MEVENT) c_int;
// pub extern fn mousemask(mmask_t, *mmask_t) mmask_t;
// pub extern fn wenclose(*const WINDOW, c_int, c_int) bool;
// pub extern fn mouseinterval(c_int) c_int;
// pub extern fn wmouse_trafo(*const WINDOW, *c_int, *c_int, bool) bool;
// pub extern fn mouse_trafo(*c_int, *c_int, bool) bool;
// pub extern fn has_mouse_sp(?*SCREEN) bool;
// pub extern fn getmouse_sp(?*SCREEN, *MEVENT) c_int;
// pub extern fn ungetmouse_sp(?*SCREEN, *MEVENT) c_int;
// pub extern fn mousemask_sp(?*SCREEN, mmask_t, *mmask_t) mmask_t;
// pub extern fn mouseinterval_sp(?*SCREEN, c_int) c_int;
// pub extern fn mcprint(*u8, c_int) c_int;
// pub extern fn has_key(c_int) c_int;
// pub extern fn has_key_sp(?*SCREEN, c_int) c_int;
// pub extern fn mcprint_sp(?*SCREEN, *u8, c_int) c_int;
// pub extern fn _tracef(*const u8, ...) void;
// pub extern fn _traceattr(attr_t) *u8;
// pub extern fn _traceattr2(c_int, chtype) *u8;
// pub extern fn _tracechar(c_int) *u8;
// pub extern fn _tracechtype(chtype) *u8;
// pub extern fn _tracechtype2(c_int, chtype) *u8;
// pub extern fn trace(c_uint) void;
// pub extern fn curses_trace(c_uint) c_uint;
// pub extern fn exit_curses(c_int) void;
// pub extern fn unctrl(chtype) *const u8;
// pub extern fn unctrl_sp(?*SCREEN, chtype) *const u8;
// pub const ptrdiff_t = c_long;
// pub const wchar_t = c_int;
// pub const max_align_t = extern struct {
//     __clang_max_align_nonce1: c_longlong align(8) = @import("std").mem.zeroes(c_longlong),
//     __clang_max_align_nonce2: c_longdouble align(16) = @import("std").mem.zeroes(c_longdouble),
// };
// pub const _ISupper: c_int = 256;
// pub const _ISlower: c_int = 512;
// pub const _ISalpha: c_int = 1024;
pub const _ISdigit: c_int = 2048;
// pub const _ISxdigit: c_int = 4096;
// pub const _ISspace: c_int = 8192;
// pub const _ISprint: c_int = 16384;
// pub const _ISgraph: c_int = 32768;
// pub const _ISblank: c_int = 1;
// pub const _IScntrl: c_int = 2;
// pub const _ISpunct: c_int = 4;
// pub const _ISalnum: c_int = 8;
// const enum_unnamed_4 = c_uint;
pub extern fn __ctype_b_loc() **const c_ushort;
// pub extern fn __ctype_tolower_loc() **const __int32_t;
// pub extern fn __ctype_toupper_loc() **const __int32_t;
// pub extern fn isalnum(c_int) c_int;
// pub extern fn isalpha(c_int) c_int;
// pub extern fn iscntrl(c_int) c_int;
// pub extern fn isdigit(c_int) c_int;
// pub extern fn islower(c_int) c_int;
// pub extern fn isgraph(c_int) c_int;
// pub extern fn isprint(c_int) c_int;
// pub extern fn ispunct(c_int) c_int;
// pub extern fn isspace(c_int) c_int;
// pub extern fn isupper(c_int) c_int;
// pub extern fn isxdigit(c_int) c_int;
// pub extern fn tolower(__c: c_int) c_int;
// pub extern fn toupper(__c: c_int) c_int;
// pub extern fn isblank(c_int) c_int;
// pub extern fn isascii(__c: c_int) c_int;
// pub extern fn toascii(__c: c_int) c_int;
// pub extern fn _toupper(c_int) c_int;
// pub extern fn _tolower(c_int) c_int;
// pub const struct___locale_data_5 = opaque {};
// pub const struct___locale_struct = extern struct {
//     __locales: [13]?*struct___locale_data_5 = @import("std").mem.zeroes([13]?*struct___locale_data_5),
//     __ctype_b: *const c_ushort = @import("std").mem.zeroes(*const c_ushort),
//     __ctype_tolower: *const c_int = @import("std").mem.zeroes(*const c_int),
//     __ctype_toupper: *const c_int = @import("std").mem.zeroes(*const c_int),
//     __names: [13]*const u8 = @import("std").mem.zeroes([13]*const u8),
// };
// pub const __locale_t = *struct___locale_struct;
// pub const locale_t = __locale_t;
// pub extern fn isalnum_l(c_int, locale_t) c_int;
// pub extern fn isalpha_l(c_int, locale_t) c_int;
// pub extern fn iscntrl_l(c_int, locale_t) c_int;
// pub extern fn isdigit_l(c_int, locale_t) c_int;
// pub extern fn islower_l(c_int, locale_t) c_int;
// pub extern fn isgraph_l(c_int, locale_t) c_int;
// pub extern fn isprint_l(c_int, locale_t) c_int;
// pub extern fn ispunct_l(c_int, locale_t) c_int;
// pub extern fn isspace_l(c_int, locale_t) c_int;
// pub extern fn isupper_l(c_int, locale_t) c_int;
// pub extern fn isxdigit_l(c_int, locale_t) c_int;
// pub extern fn isblank_l(c_int, locale_t) c_int;
// pub extern fn __tolower_l(__c: c_int, __l: locale_t) c_int;
// pub extern fn tolower_l(__c: c_int, __l: locale_t) c_int;
// pub extern fn __toupper_l(__c: c_int, __l: locale_t) c_int;
// pub extern fn toupper_l(__c: c_int, __l: locale_t) c_int;
//
// const defs = @import("defs.zig");
// const String_View = defs.String_View;
//
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
// pub const Row = extern struct {
//     start: usize = @import("std").mem.zeroes(usize),
//     end: usize = @import("std").mem.zeroes(usize),
// };
// pub const Rows = extern struct {
//     data: *Row = @import("std").mem.zeroes(*Row),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
// };
// pub const Data = extern struct {
//     data: *u8 = @import("std").mem.zeroes(*u8),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
// };
// pub const Positions = extern struct {
//     data: *usize = @import("std").mem.zeroes(*usize),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
// };
// pub const Arg = extern struct {
//     size: usize = @import("std").mem.zeroes(usize),
//     arg: *u8 = @import("std").mem.zeroes(*u8),
// };
// pub const Undo = extern struct {
//     type: Undo_Type = @import("std").mem.zeroes(Undo_Type),
//     data: Data = @import("std").mem.zeroes(Data),
//     start: usize = @import("std").mem.zeroes(usize),
//     end: usize = @import("std").mem.zeroes(usize),
// };
// pub const Undo_Stack = extern struct {
//     data: *Undo = @import("std").mem.zeroes(*Undo),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
// };
// pub const Repeating = extern struct {
//     repeating: bool = @import("std").mem.zeroes(bool),
//     repeating_count: usize = @import("std").mem.zeroes(usize),
// };
// pub const Sized_Str = extern struct {
//     str: *u8 = @import("std").mem.zeroes(*u8),
//     len: usize = @import("std").mem.zeroes(usize),
// };
// pub const Map = extern struct {
//     a: c_int = @import("std").mem.zeroes(c_int),
//     b: *u8 = @import("std").mem.zeroes(*u8),
//     b_s: usize = @import("std").mem.zeroes(usize),
// };
// pub const Maps = extern struct {
//     data: *Map = @import("std").mem.zeroes(*Map),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
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
pub const Variable = defs.Variable;
// pub const Variables = extern struct {
//     data: *Variable = @import("std").mem.zeroes(*Variable),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
// };
// pub const File = extern struct {
//     name: *u8 = @import("std").mem.zeroes(*u8),
//     path: *u8 = @import("std").mem.zeroes(*u8),
//     is_directory: bool = @import("std").mem.zeroes(bool),
// };
// pub const Files = extern struct {
//     data: *File = @import("std").mem.zeroes(*File),
//     count: usize = @import("std").mem.zeroes(usize),
//     capacity: usize = @import("std").mem.zeroes(usize),
// };
// pub const Config_Vars = extern struct {
//     label: String_View = @import("std").mem.zeroes(String_View),
//     val: *c_int = @import("std").mem.zeroes(*c_int),
// };
// pub const struct__Config_ = extern struct {
//     relative_nums: c_int = @import("std").mem.zeroes(c_int),
//     auto_indent: c_int = @import("std").mem.zeroes(c_int),
//     syntax: c_int = @import("std").mem.zeroes(c_int),
//     indent: c_int = @import("std").mem.zeroes(c_int),
//     undo_size: c_int = @import("std").mem.zeroes(c_int),
//     lang: *u8 = @import("std").mem.zeroes(*u8),
//     QUIT: c_int = @import("std").mem.zeroes(c_int),
//     mode: Mode = @import("std").mem.zeroes(Mode),
//     background_color: c_int = @import("std").mem.zeroes(c_int),
//     leaders: [4]u8 = @import("std").mem.zeroes([4]u8),
//     key_maps: Maps = @import("std").mem.zeroes(Maps),
//     vars: [5]Config_Vars = @import("std").mem.zeroes([5]Config_Vars),
// };
// pub const Config = struct__Config_;
// pub const struct_State = extern struct {
//     undo_stack: Undo_Stack = @import("std").mem.zeroes(Undo_Stack),
//     redo_stack: Undo_Stack = @import("std").mem.zeroes(Undo_Stack),
//     cur_undo: Undo = @import("std").mem.zeroes(Undo),
//     num_of_braces: usize = @import("std").mem.zeroes(usize),
//     ch: c_int = @import("std").mem.zeroes(c_int),
//     env: *u8 = @import("std").mem.zeroes(*u8),
//     command: *u8 = @import("std").mem.zeroes(*u8),
//     command_s: usize = @import("std").mem.zeroes(usize),
//     variables: Variables = @import("std").mem.zeroes(Variables),
//     repeating: Repeating = @import("std").mem.zeroes(Repeating),
//     num: Data = @import("std").mem.zeroes(Data),
//     leader: Leader = @import("std").mem.zeroes(Leader),
//     is_print_msg: bool = @import("std").mem.zeroes(bool),
//     status_bar_msg: *u8 = @import("std").mem.zeroes(*u8),
//     x: usize = @import("std").mem.zeroes(usize),
//     y: usize = @import("std").mem.zeroes(usize),
//     normal_pos: usize = @import("std").mem.zeroes(usize),
//     key_func: *?*const fn (*Buffer, **Buffer, *struct_State) callconv(.C) void = @import("std").mem.zeroes(*?*const fn (*Buffer, **Buffer, *struct_State) callconv(.C) void),
//     clipboard: Sized_Str = @import("std").mem.zeroes(Sized_Str),
//     files: *Files = @import("std").mem.zeroes(*Files),
//     is_exploring: bool = @import("std").mem.zeroes(bool),
//     explore_cursor: usize = @import("std").mem.zeroes(usize),
//     buffer: *Buffer = @import("std").mem.zeroes(*Buffer),
//     grow: c_int = @import("std").mem.zeroes(c_int),
//     gcol: c_int = @import("std").mem.zeroes(c_int),
//     main_row: c_int = @import("std").mem.zeroes(c_int),
//     main_col: c_int = @import("std").mem.zeroes(c_int),
//     line_num_row: c_int = @import("std").mem.zeroes(c_int),
//     line_num_col: c_int = @import("std").mem.zeroes(c_int),
//     status_bar_row: c_int = @import("std").mem.zeroes(c_int),
//     status_bar_col: c_int = @import("std").mem.zeroes(c_int),
//     line_num_win: *WINDOW = @import("std").mem.zeroes(*WINDOW),
//     main_win: *WINDOW = @import("std").mem.zeroes(*WINDOW),
//     status_bar: *WINDOW = @import("std").mem.zeroes(*WINDOW),
//     config: Config = @import("std").mem.zeroes(Config),
// };
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
// pub extern fn frontend_init(state: *State) void;
// pub extern fn state_render(state: *State) void;
// pub extern fn frontend_resize_window(state: *State) void;
// pub extern fn frontend_getch(window: *WINDOW) c_int;
// pub extern fn frontend_move_cursor(window: *WINDOW, pos_x: usize, pos_y: usize) void;
// pub extern fn frontend_cursor_visible(value: c_int) void;
pub extern fn frontend_end() void;
pub const TT_SET_VAR: c_int = 0;
pub const TT_SET_OUTPUT: c_int = 1;
pub const TT_SET_MAP: c_int = 2;
pub const TT_LET: c_int = 3;
pub const TT_PLUS: c_int = 4;
pub const TT_MINUS: c_int = 5;
pub const TT_MULT: c_int = 6;
pub const TT_DIV: c_int = 7;
pub const TT_ECHO: c_int = 8;
pub const TT_SAVE: c_int = 9;
pub const TT_EXIT: c_int = 10;
pub const TT_SAVE_EXIT: c_int = 11;
pub const TT_IDENT: c_int = 12;
pub const TT_SPECIAL_CHAR: c_int = 13;
pub const TT_STRING: c_int = 14;
pub const TT_CONFIG_IDENT: c_int = 15;
pub const TT_INT_LIT: c_int = 16;
pub const TT_FLOAT_LIT: c_int = 17;
pub const TT_COUNT: c_int = 18;
pub const Command_Type = c_uint;

pub const Command_Token = extern struct {
    type: Command_Type = @import("std").mem.zeroes(Command_Type),
    value: String_View = @import("std").mem.zeroes(String_View),
    location: usize = @import("std").mem.zeroes(usize),
};
pub const Identifier = extern struct {
    name: String_View = @import("std").mem.zeroes(String_View),
    value: c_int = @import("std").mem.zeroes(c_int),
};
pub const Str_Literal = extern struct {
    value: String_View = @import("std").mem.zeroes(String_View),
};
pub const Expr = extern struct {
    value: c_int = @import("std").mem.zeroes(c_int),
};
pub const OP_NONE: c_int = 0;
pub const OP_PLUS: c_int = 1;
pub const OP_MINUS: c_int = 2;
pub const OP_MULT: c_int = 3;
pub const OP_DIV: c_int = 4;
pub const Operator = c_uint;
pub const struct_Bin_Expr = extern struct {
    lvalue: Expr = @import("std").mem.zeroes(Expr),
    right: *struct_Bin_Expr = @import("std").mem.zeroes(*struct_Bin_Expr),
    rvalue: Expr = @import("std").mem.zeroes(Expr),
    operator: Operator = @import("std").mem.zeroes(Operator),
};
pub const Bin_Expr = struct_Bin_Expr;
pub const Node_Val = extern union {
    as_expr: Expr,
    as_bin: Bin_Expr,
    as_keyword: Command_Type,
    as_str: Str_Literal,
    as_ident: Identifier,
    as_config: *Config_Vars,
    as_int: c_int,
};
pub const NODE_EXPR: c_int = 0;
pub const NODE_BIN: c_int = 1;
pub const NODE_KEYWORD: c_int = 2;
pub const NODE_STR: c_int = 3;
pub const NODE_IDENT: c_int = 4;
pub const NODE_CONFIG: c_int = 5;
pub const NODE_INT: c_int = 6;
pub const Node_Type = c_uint;
pub const struct_Node = extern struct {
    value: Node_Val = @import("std").mem.zeroes(Node_Val),
    type: Node_Type = @import("std").mem.zeroes(Node_Type),
    left: *struct_Node = @import("std").mem.zeroes(*struct_Node),
    right: *struct_Node = @import("std").mem.zeroes(*struct_Node),
};
pub const Node = struct_Node;
pub const Ctrl_Key = extern struct {
    name: *u8 = @import("std").mem.zeroes(*u8),
    value: c_int = @import("std").mem.zeroes(c_int),
};

pub fn get_token_type(arg_state: *State, arg_view: String_View) Command_Type {
    var state = arg_state;
    _ = &state;
    var view = arg_view;
    _ = &view;
    if ((@as(c_int, @bitCast(@as(c_uint, (blk: {
        const tmp = @as(c_int, @bitCast(@as(c_uint, view.data.*)));
        if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISdigit)))))))) != 0) {
        {
            var i: usize = 0;
            _ = &i;
            while (i < view.len) : (i +%= 1) {
                if (@as(c_int, @bitCast(@as(c_uint, view.data[i]))) == @as(c_int, ' ')) {
                    break;
                }
                if (@as(c_int, @bitCast(@as(c_uint, view.data[i]))) == @as(c_int, '.')) {
                    return @as(c_uint, @bitCast(TT_FLOAT_LIT));
                }
            }
        }
        return @as(c_uint, @bitCast(TT_INT_LIT));
    } else if (@as(c_int, @bitCast(@as(c_uint, view.data.*))) == @as(c_int, '"')) {
        return @as(c_uint, @bitCast(TT_STRING));
    } else if (@as(c_int, @bitCast(@as(c_uint, view.data.*))) == @as(c_int, '<')) {
        return @as(c_uint, @bitCast(TT_SPECIAL_CHAR));
    } else if (@as(c_int, @bitCast(@as(c_uint, view.data.*))) == @as(c_int, '+')) {
        return @as(c_uint, @bitCast(TT_PLUS));
    } else if (@as(c_int, @bitCast(@as(c_uint, view.data.*))) == @as(c_int, '-')) {
        return @as(c_uint, @bitCast(TT_MINUS));
    } else if (@as(c_int, @bitCast(@as(c_uint, view.data.*))) == @as(c_int, '*')) {
        return @as(c_uint, @bitCast(TT_MULT));
    } else if (@as(c_int, @bitCast(@as(c_uint, view.data.*))) == @as(c_int, '/')) {
        return @as(c_uint, @bitCast(TT_DIV));
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("let")))), @sizeOf([4]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return @as(c_uint, @bitCast(TT_LET));
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("echo")))), @sizeOf([5]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return @as(c_uint, @bitCast(TT_ECHO));
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("set-var")))), @sizeOf([8]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return @as(c_uint, @bitCast(TT_SET_VAR));
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("w")))), @sizeOf([2]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return @as(c_uint, @bitCast(TT_SAVE));
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("e")))), @sizeOf([2]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return @as(c_uint, @bitCast(TT_EXIT));
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("we")))), @sizeOf([3]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return @as(c_uint, @bitCast(TT_SAVE_EXIT));
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("set-output")))), @sizeOf([11]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return @as(c_uint, @bitCast(TT_SET_OUTPUT));
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("set-map")))), @sizeOf([8]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return @as(c_uint, @bitCast(TT_SET_MAP));
    } else {
        {
            var i: usize = 0;
            _ = &i;
            while (i < @as(usize, @bitCast(@as(c_long, @as(c_int, 5))))) : (i +%= 1) {
                if (vw.view_cmp(view, state.*.config.vars[i].label) != 0) {
                    return @as(c_uint, @bitCast(TT_CONFIG_IDENT));
                }
            }
        }
        return @as(c_uint, @bitCast(TT_IDENT));
    }
    return @import("std").mem.zeroes(Command_Type);
}
pub fn create_token(arg_state: *State, arg_command: String_View) Command_Token {
    var state = arg_state;
    _ = &state;
    var command = arg_command;
    _ = &command;
    var starting: String_View = command;
    _ = &starting;
    while ((command.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, command.data.*))) != @as(c_int, ' '))) {
        if (@as(c_int, @bitCast(@as(c_uint, command.data.*))) == @as(c_int, '"')) {
            command = view_chop_left(command, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
            while ((command.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, command.data.*))) != @as(c_int, '"'))) {
                command = view_chop_left(command, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
            }
        }
        if (@as(c_int, @bitCast(@as(c_uint, command.data.*))) == @as(c_int, '<')) {
            command = view_chop_left(command, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
            while ((command.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, command.data.*))) != @as(c_int, '>'))) {
                command = view_chop_left(command, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
            }
        }
        command = view_chop_left(command, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    }
    var result: String_View = String_View{
        .data = starting.data,
        .len = starting.len -% command.len,
    };
    _ = &result;
    var token: Command_Token = Command_Token{
        .type = @import("std").mem.zeroes(Command_Type),
        .value = result,
        .location = @import("std").mem.zeroes(usize),
    };
    _ = &token;
    token.type = get_token_type(state, result);
    return token;
}
pub fn lex_command(arg_state: *State, arg_command: String_View, arg_token_s: *usize) *Command_Token {
    var state = arg_state;
    _ = &state;
    var command = arg_command;
    _ = &command;
    var token_s = arg_token_s;
    _ = &token_s;
    var count: usize = 0;
    _ = &count;
    {
        var i: usize = 0;
        _ = &i;
        while (i < command.len) : (i +%= 1) {
            if (@as(c_int, @bitCast(@as(c_uint, command.data[i]))) == @as(c_int, '"')) {
                i +%= 1;
                while ((i < command.len) and (@as(c_int, @bitCast(@as(c_uint, command.data[i]))) != @as(c_int, '"'))) {
                    i +%= 1;
                }
            }
            if (@as(c_int, @bitCast(@as(c_uint, command.data[i]))) == @as(c_int, ' ')) {
                count +%= 1;
            }
        }
    }
    token_s.* = count +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    var result: *Command_Token = @as(*Command_Token, @ptrCast(@alignCast(malloc(@sizeOf(Command_Token) *% token_s.*))));
    _ = &result;
    var result_s: usize = 0;
    _ = &result_s;
    var starting: String_View = command;
    _ = &starting;
    while (command.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        _ = blk: {
            _ = @sizeOf(c_int);
            break :blk blk_1: {
                break :blk_1 if (result_s <= token_s.*) {} else {
                    __assert_fail("result_s <= *token_s", "src/commands.c", @as(c_uint, @bitCast(@as(c_int, 160))), "Command_Token *lex_command(State *, String_View, size_t *)");
                };
            };
        };
        var loc: usize = @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(command.data) -% @intFromPtr(starting.data))), @sizeOf(u8))));
        _ = &loc;
        var token: Command_Token = create_token(state, command);
        _ = &token;
        token.location = loc;
        command = view_chop_left(command, token.value.len +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
        _ = view_chop_left(command, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
        result[
            blk: {
                const ref = &result_s;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            }
        ] = token;
    }
    return result;
}
pub fn print_token(arg_token: Command_Token) void {
    var token = arg_token;
    _ = &token;
    _ = printf("location: %zu, type: %d, value: %.*s\n", token.location, token.type, @as(c_int, @bitCast(@as(c_uint, @truncate(token.value.len)))), token.value.data);
}
pub fn expect_token(arg_state: *State, arg_token: Command_Token, arg_type: Command_Type) c_int {
    var state = arg_state;
    _ = &state;
    var token = arg_token;
    _ = &token;
    var @"type" = arg_type;
    _ = &@"type";
    if (token.type != @"type") {
        _ = sprintf(state.*.status_bar_msg, "Invalid arg, expected %s but found %s", tt_string[@"type"], tt_string[token.type]);
        state.*.is_print_msg = @as(c_int, 1) != 0;
    }
    return @intFromBool(token.type == @"type");
}
pub fn create_node(arg_type: Node_Type, arg_value: Node_Val) *Node {
    var @"type" = arg_type;
    _ = &@"type";
    var value = arg_value;
    _ = &value;
    var node: *Node = @as(*Node, @ptrCast(@alignCast(malloc(@sizeOf(Node)))));
    _ = &node;
    node.*.type = @"type";
    node.*.value = value;
    node.*.left = null;
    node.*.right = null;
    return node;
}
pub fn get_operator(arg_token: Command_Token) Operator {
    var token = arg_token;
    _ = &token;
    while (true) {
        switch (token.type) {
            @as(c_uint, @bitCast(@as(c_int, 4))) => return @as(c_uint, @bitCast(OP_PLUS)),
            @as(c_uint, @bitCast(@as(c_int, 5))) => return @as(c_uint, @bitCast(OP_MINUS)),
            @as(c_uint, @bitCast(@as(c_int, 6))) => return @as(c_uint, @bitCast(OP_MULT)),
            @as(c_uint, @bitCast(@as(c_int, 7))) => return @as(c_uint, @bitCast(OP_DIV)),
            else => return @as(c_uint, @bitCast(OP_NONE)),
        }
        break;
    }
    return @import("std").mem.zeroes(Operator);
}
pub fn get_special_char(arg_view: String_View) c_int {
    var view = arg_view;
    _ = &view;
    if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("<space>")))), @sizeOf([8]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return 32;
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("<esc>")))), @sizeOf([6]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return 27;
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("<backspace>")))), @sizeOf([12]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return 263;
    } else if (vw.view_cmp(view, vw.view_create(@as(*u8, @ptrCast(@volatileCast(@constCast("<enter>")))), @sizeOf([8]u8) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) != 0) {
        return 10;
    } else {
        {
            var i: usize = 0;
            _ = &i;
            while (i < (@sizeOf([26]Ctrl_Key) / @sizeOf(Ctrl_Key))) : (i +%= 1) {
                if (vw.view_cmp(view, vw.view_create(ctrl_keys[i].name, strlen(ctrl_keys[i].name))) != 0) {
                    return ctrl_keys[i].value;
                }
            }
        }
        return -@as(c_int, 1);
    }
    return 0;
}
pub fn parse_bin_expr(arg_state: *State, arg_command: *Command_Token, arg_command_s: usize) *Bin_Expr {
    var state = arg_state;
    _ = &state;
    var command = arg_command;
    _ = &command;
    var command_s = arg_command_s;
    _ = &command_s;
    if (command_s == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) return null;
    var expr: *Bin_Expr = @as(*Bin_Expr, @ptrCast(@alignCast(calloc(@as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(Bin_Expr)))));
    _ = &expr;
    expr.*.lvalue = Expr{
        .value = vw.view_to_int(command[@as(c_uint, @intCast(@as(c_int, 0)))].value),
    };
    if (command_s <= @as(usize, @bitCast(@as(c_long, @as(c_int, 2))))) return expr;
    expr.*.operator = get_operator(command[@as(c_uint, @intCast(@as(c_int, 1)))]);
    if (expr.*.operator == @as(c_uint, @bitCast(OP_NONE))) return null;
    if (!(expect_token(state, command[@as(c_uint, @intCast(@as(c_int, 2)))], @as(c_uint, @bitCast(TT_INT_LIT))) != 0)) return null;
    expr.*.rvalue = Expr{
        .value = vw.view_to_int(command[@as(c_uint, @intCast(@as(c_int, 2)))].value),
    };
    if (command_s > @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) {
        expr.*.right = parse_bin_expr(state, command + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 4))))), command_s -% @as(usize, @bitCast(@as(c_long, @as(c_int, 4)))));
        expr.*.right.*.operator = get_operator(command[@as(c_uint, @intCast(@as(c_int, 3)))]);
    }
    return expr;
}
pub fn parse_command(arg_state: *State, arg_command: *Command_Token, arg_command_s: usize) *Node {
    var state = arg_state;
    _ = &state;
    var command = arg_command;
    _ = &command;
    var command_s = arg_command_s;
    _ = &command_s;
    var root: *Node = null;
    _ = &root;
    var val: Node_Val = undefined;
    _ = &val;
    val.as_keyword = command[@as(c_uint, @intCast(@as(c_int, 0)))].type;
    root = create_node(@as(c_uint, @bitCast(NODE_KEYWORD)), val);
    while (true) {
        switch (command[@as(c_uint, @intCast(@as(c_int, 0)))].type) {
            @as(c_uint, @bitCast(@as(c_int, 0))) => {
                if (command_s < @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) {
                    _ = sprintf(state.*.status_bar_msg, "Not enough args");
                    state.*.is_print_msg = @as(c_int, 1) != 0;
                    return null;
                }
                if (!(expect_token(state, command[@as(c_uint, @intCast(@as(c_int, 1)))], @as(c_uint, @bitCast(TT_CONFIG_IDENT))) != 0) or !(expect_token(state, command[@as(c_uint, @intCast(@as(c_int, 2)))], @as(c_uint, @bitCast(TT_INT_LIT))) != 0)) return null;
                {
                    var i: usize = 0;
                    _ = &i;
                    while (i < @as(usize, @bitCast(@as(c_long, @as(c_int, 5))))) : (i +%= 1) {
                        if (vw.view_cmp(command[@as(c_uint, @intCast(@as(c_int, 1)))].value, state.*.config.vars[i].label) != 0) {
                            val.as_config = &state.*.config.vars[i];
                        }
                    }
                }
                var left: *Node = create_node(@as(c_uint, @bitCast(NODE_CONFIG)), val);
                _ = &left;
                root.*.left = left;
                if (command_s == @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) {
                    var value: c_int = vw.view_to_int(command[@as(c_uint, @intCast(@as(c_int, 2)))].value);
                    _ = &value;
                    val.as_expr = Expr{
                        .value = value,
                    };
                    var right: *Node = create_node(@as(c_uint, @bitCast(NODE_EXPR)), val);
                    _ = &right;
                    root.*.right = right;
                    break;
                } else {
                    var expr: *Bin_Expr = parse_bin_expr(state, command + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 2))))), command_s -% @as(usize, @bitCast(@as(c_long, @as(c_int, 2)))));
                    _ = &expr;
                    val.as_bin = expr.*;
                    root.*.right = create_node(@as(c_uint, @bitCast(NODE_BIN)), val);
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 1))) => {
                if (command_s < @as(usize, @bitCast(@as(c_long, @as(c_int, 2))))) {
                    _ = sprintf(state.*.status_bar_msg, "Not enough args");
                    state.*.is_print_msg = @as(c_int, 1) != 0;
                    return null;
                } else if (command_s > @as(usize, @bitCast(@as(c_long, @as(c_int, 2))))) {
                    _ = sprintf(state.*.status_bar_msg, "Too many args");
                    state.*.is_print_msg = @as(c_int, 1) != 0;
                    return null;
                }
                val.as_str = Str_Literal{
                    .value = view_string_internals(command[@as(c_uint, @intCast(@as(c_int, 1)))].value),
                };
                root.*.right = create_node(@as(c_uint, @bitCast(NODE_STR)), val);
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 2))) => {
                if (command_s < @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) {
                    _ = sprintf(state.*.status_bar_msg, "Not enough args");
                    state.*.is_print_msg = @as(c_int, 1) != 0;
                    return null;
                } else if (command_s > @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) {
                    _ = sprintf(state.*.status_bar_msg, "Not enough args");
                    state.*.is_print_msg = @as(c_int, 1) != 0;
                    return null;
                }
                if (!(expect_token(state, command[@as(c_uint, @intCast(@as(c_int, 2)))], @as(c_uint, @bitCast(TT_STRING))) != 0)) return null;
                if (command[@as(c_uint, @intCast(@as(c_int, 1)))].type == @as(c_uint, @bitCast(TT_SPECIAL_CHAR))) {
                    var special: c_int = get_special_char(command[@as(c_uint, @intCast(@as(c_int, 1)))].value);
                    _ = &special;
                    if (special == -@as(c_int, 1)) {
                        _ = sprintf(state.*.status_bar_msg, "Invalid special key");
                        state.*.is_print_msg = @as(c_int, 1) != 0;
                        return null;
                    }
                    val.as_int = special;
                    root.*.left = create_node(@as(c_uint, @bitCast(NODE_INT)), val);
                } else {
                    val.as_ident = Identifier{
                        .name = command[@as(c_uint, @intCast(@as(c_int, 1)))].value,
                        .value = 0,
                    };
                    root.*.left = create_node(@as(c_uint, @bitCast(NODE_IDENT)), val);
                }
                val.as_str = Str_Literal{
                    .value = view_string_internals(command[@as(c_uint, @intCast(@as(c_int, 2)))].value),
                };
                root.*.right = create_node(@as(c_uint, @bitCast(NODE_STR)), val);
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 3))) => {
                if (command_s < @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) {
                    _ = sprintf(state.*.status_bar_msg, "Not enough args");
                    state.*.is_print_msg = @as(c_int, 1) != 0;
                    return null;
                }
                if (!(expect_token(state, command[@as(c_uint, @intCast(@as(c_int, 1)))], @as(c_uint, @bitCast(TT_IDENT))) != 0) or !(expect_token(state, command[@as(c_uint, @intCast(@as(c_int, 2)))], @as(c_uint, @bitCast(TT_INT_LIT))) != 0)) return null;
                val.as_ident = Identifier{
                    .name = command[@as(c_uint, @intCast(@as(c_int, 1)))].value,
                    .value = 0,
                };
                root.*.left = create_node(@as(c_uint, @bitCast(NODE_IDENT)), val);
                if (command_s == @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) {
                    var value: c_int = vw.view_to_int(command[@as(c_uint, @intCast(@as(c_int, 2)))].value);
                    _ = &value;
                    val.as_expr = Expr{
                        .value = value,
                    };
                    var right: *Node = create_node(@as(c_uint, @bitCast(NODE_EXPR)), val);
                    _ = &right;
                    root.*.right = right;
                    break;
                } else {
                    var expr: *Bin_Expr = parse_bin_expr(state, command + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 2))))), command_s -% @as(usize, @bitCast(@as(c_long, @as(c_int, 2)))));
                    _ = &expr;
                    val.as_bin = expr.*;
                    root.*.right = create_node(@as(c_uint, @bitCast(NODE_BIN)), val);
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 8))) => {
                if (command_s > @as(usize, @bitCast(@as(c_long, @as(c_int, 2))))) {
                    _ = sprintf(state.*.status_bar_msg, "Too many args");
                    state.*.is_print_msg = @as(c_int, 1) != 0;
                    return null;
                }
                if (command_s < @as(usize, @bitCast(@as(c_long, @as(c_int, 2))))) {
                    _ = sprintf(state.*.status_bar_msg, "Not enough args");
                    state.*.is_print_msg = @as(c_int, 1) != 0;
                    return null;
                }
                if (!(expect_token(state, command[@as(c_uint, @intCast(@as(c_int, 1)))], @as(c_uint, @bitCast(TT_IDENT))) != 0) and !(expect_token(state, command[@as(c_uint, @intCast(@as(c_int, 1)))], @as(c_uint, @bitCast(TT_STRING))) != 0)) return null;
                if (command[@as(c_uint, @intCast(@as(c_int, 1)))].type == @as(c_uint, @bitCast(TT_STRING))) {
                    val.as_str = Str_Literal{
                        .value = view_string_internals(command[@as(c_uint, @intCast(@as(c_int, 1)))].value),
                    };
                    root.*.right = create_node(@as(c_uint, @bitCast(NODE_STR)), val);
                } else {
                    val.as_ident = Identifier{
                        .name = command[@as(c_uint, @intCast(@as(c_int, 1)))].value,
                        .value = 0,
                    };
                    root.*.right = create_node(@as(c_uint, @bitCast(NODE_IDENT)), val);
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 4))), @as(c_uint, @bitCast(@as(c_int, 5))), @as(c_uint, @bitCast(@as(c_int, 6))), @as(c_uint, @bitCast(@as(c_int, 7))), @as(c_uint, @bitCast(@as(c_int, 9))), @as(c_uint, @bitCast(@as(c_int, 10))), @as(c_uint, @bitCast(@as(c_int, 11))), @as(c_uint, @bitCast(@as(c_int, 12))), @as(c_uint, @bitCast(@as(c_int, 14))), @as(c_uint, @bitCast(@as(c_int, 15))), @as(c_uint, @bitCast(@as(c_int, 16))), @as(c_uint, @bitCast(@as(c_int, 13))), @as(c_uint, @bitCast(@as(c_int, 17))) => break,
            @as(c_uint, @bitCast(@as(c_int, 18))) => {
                _ = blk: {
                    _ = @sizeOf(c_int);
                    break :blk blk_1: {
                        break :blk_1 if (false and (@intFromPtr("UNREACHABLE") != 0)) {} else {
                            __assert_fail("0 && \"UNREACHABLE\"", "src/commands.c", @as(c_uint, @bitCast(@as(c_int, 377))), "Node *parse_command(State *, Command_Token *, size_t)");
                        };
                    };
                };
            },
            else => {},
        }
        break;
    }
    return root;
}
pub fn interpret_expr(arg_expr: *Bin_Expr) c_int {
    var expr = arg_expr;
    _ = &expr;
    var value: c_int = expr.*.lvalue.value;
    _ = &value;
    if ((expr.*.rvalue.value != @as(c_int, 0)) and (expr.*.operator != @as(c_uint, @bitCast(OP_NONE)))) {
        while (true) {
            switch (expr.*.operator) {
                @as(c_uint, @bitCast(@as(c_int, 1))) => {
                    value += expr.*.rvalue.value;
                    break;
                },
                @as(c_uint, @bitCast(@as(c_int, 2))) => {
                    value -= expr.*.rvalue.value;
                    break;
                },
                @as(c_uint, @bitCast(@as(c_int, 3))) => {
                    value *= expr.*.rvalue.value;
                    break;
                },
                @as(c_uint, @bitCast(@as(c_int, 4))) => {
                    value = @divTrunc(value, expr.*.rvalue.value);
                    break;
                },
                else => {
                    _ = blk: {
                        _ = @sizeOf(c_int);
                        break :blk blk_1: {
                            break :blk_1 if (false and (@intFromPtr("unreachable") != 0)) {} else {
                                __assert_fail("0 && \"unreachable\"", "src/commands.c", @as(c_uint, @bitCast(@as(c_int, 399))), "int interpret_expr(Bin_Expr *)");
                            };
                        };
                    };
                },
            }
            break;
        }
    }
    if (expr.*.right != @as(*struct_Bin_Expr, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
        while (true) {
            switch (expr.*.right.*.operator) {
                @as(c_uint, @bitCast(@as(c_int, 1))) => {
                    value += interpret_expr(expr.*.right);
                    break;
                },
                @as(c_uint, @bitCast(@as(c_int, 2))) => {
                    value -= interpret_expr(expr.*.right);
                    break;
                },
                @as(c_uint, @bitCast(@as(c_int, 3))) => {
                    value *= interpret_expr(expr.*.right);
                    break;
                },
                @as(c_uint, @bitCast(@as(c_int, 4))) => {
                    value = @divTrunc(value, interpret_expr(expr.*.right));
                    break;
                },
                else => {
                    _ = blk: {
                        _ = @sizeOf(c_int);
                        break :blk blk_1: {
                            break :blk_1 if (false and (@intFromPtr("unreachable") != 0)) {} else {
                                __assert_fail("0 && \"unreachable\"", "src/commands.c", @as(c_uint, @bitCast(@as(c_int, 418))), "int interpret_expr(Bin_Expr *)");
                            };
                        };
                    };
                },
            }
            break;
        }
    }
    return value;
}
pub fn interpret_command(arg_buffer: *Buffer, arg_state: *State, arg_root: *Node) void {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    var root = arg_root;
    _ = &root;
    if (root == @as(*Node, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) return;
    while (true) {
        switch (root.*.type) {
            @as(c_uint, @bitCast(@as(c_int, 0))) => break,
            @as(c_uint, @bitCast(@as(c_int, 1))) => break,
            @as(c_uint, @bitCast(@as(c_int, 2))) => {
                while (true) {
                    switch (root.*.value.as_keyword) {
                        @as(c_uint, @bitCast(@as(c_int, 0))) => {
                            {
                                var @"var": *Config_Vars = root.*.left.*.value.as_config;
                                _ = &@"var";
                                if (root.*.right.*.type == @as(c_uint, @bitCast(NODE_EXPR))) {
                                    @"var".*.val.* = root.*.right.*.value.as_expr.value;
                                } else {
                                    var node: *Node = root.*.right;
                                    _ = &node;
                                    var value: c_int = interpret_expr(&node.*.value.as_bin);
                                    _ = &value;
                                    @"var".*.val.* = value;
                                }
                                return;
                            }
                        },
                        @as(c_uint, @bitCast(@as(c_int, 1))) => {
                            buffer.*.filename = vw.view_to_cstr(root.*.right.*.value.as_str.value);
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 2))) => {
                            {
                                var str: *u8 = vw.view_to_cstr(root.*.right.*.value.as_str.value);
                                _ = &str;
                                var map: Map = Map{
                                    .a = 0,
                                    .b = str,
                                    .b_s = root.*.right.*.value.as_str.value.len +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))),
                                };
                                _ = &map;
                                if (root.*.left.*.type == @as(c_uint, @bitCast(NODE_IDENT))) {
                                    map.a = @as(c_int, @bitCast(@as(c_uint, root.*.left.*.value.as_ident.name.data[@as(c_uint, @intCast(@as(c_int, 0)))])));
                                } else {
                                    map.a = root.*.left.*.value.as_int;
                                }
                                while (true) {
                                    if ((&state.*.config.key_maps).*.count >= (&state.*.config.key_maps).*.capacity) {
                                        (&state.*.config.key_maps).*.capacity = if ((&state.*.config.key_maps).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&state.*.config.key_maps).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
                                        var new: ?*anyopaque = calloc((&state.*.config.key_maps).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(Map));
                                        _ = &new;
                                        while (true) {
                                            if (!(new != null)) {
                                                frontend_end();
                                                _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/commands.c", @as(c_int, 456));
                                                _ = fprintf(stderr, "outta ram");
                                                _ = fprintf(stderr, "\n");
                                                exit(@as(c_int, 1));
                                            }
                                            if (!false) break;
                                        }
                                        _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&state.*.config.key_maps).*.data)), (&state.*.config.key_maps).*.count);
                                        free(@as(?*anyopaque, @ptrCast((&state.*.config.key_maps).*.data)));
                                        (&state.*.config.key_maps).*.data = @as(*Map, @ptrCast(@alignCast(new)));
                                    }
                                    (&state.*.config.key_maps).*.data[
                                        blk: {
                                            const ref = &(&state.*.config.key_maps).*.count;
                                            const tmp = ref.*;
                                            ref.* +%= 1;
                                            break :blk tmp;
                                        }
                                    ] = map;
                                    if (!false) break;
                                }
                            }
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 3))) => {
                            {
                                var @"var": Variable = Variable{
                                    .name = null,
                                    .value = @import("std").mem.zeroes(Var_Value),
                                    .type = @import("std").mem.zeroes(Var_Type),
                                };
                                _ = &@"var";
                                @"var".name = vw.view_to_cstr(root.*.left.*.value.as_ident.name);
                                @"var".type = @as(c_uint, @bitCast(VAR_INT));
                                if (root.*.right.*.type == @as(c_uint, @bitCast(NODE_EXPR))) {
                                    @"var".value.as_int = root.*.right.*.value.as_expr.value;
                                } else {
                                    var node: *Node = root.*.right;
                                    _ = &node;
                                    var value: c_int = interpret_expr(&node.*.value.as_bin);
                                    _ = &value;
                                    @"var".value.as_int = value;
                                }
                                while (true) {
                                    if ((&state.*.variables).*.count >= (&state.*.variables).*.capacity) {
                                        (&state.*.variables).*.capacity = if ((&state.*.variables).*.capacity == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) @as(usize, @bitCast(@as(c_long, @as(c_int, 1024)))) else (&state.*.variables).*.capacity *% @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
                                        var new: ?*anyopaque = calloc((&state.*.variables).*.capacity +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))), @sizeOf(Variable));
                                        _ = &new;
                                        while (true) {
                                            if (!(new != null)) {
                                                frontend_end();
                                                _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/commands.c", @as(c_int, 469));
                                                _ = fprintf(stderr, "outta ram");
                                                _ = fprintf(stderr, "\n");
                                                exit(@as(c_int, 1));
                                            }
                                            if (!false) break;
                                        }
                                        _ = memcpy(new, @as(?*const anyopaque, @ptrCast((&state.*.variables).*.data)), (&state.*.variables).*.count);
                                        free(@as(?*anyopaque, @ptrCast((&state.*.variables).*.data)));
                                        (&state.*.variables).*.data = @as(*Variable, @ptrCast(@alignCast(new)));
                                    }
                                    (&state.*.variables).*.data[
                                        blk: {
                                            const ref = &(&state.*.variables).*.count;
                                            const tmp = ref.*;
                                            ref.* +%= 1;
                                            break :blk tmp;
                                        }
                                    ] = @"var";
                                    if (!false) break;
                                }
                            }
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 8))) => {
                            state.*.is_print_msg = @as(c_int, 1) != 0;
                            if (root.*.right.*.type == @as(c_uint, @bitCast(NODE_STR))) {
                                var str: String_View = root.*.right.*.value.as_str.value;
                                _ = &str;
                                state.*.status_bar_msg = vw.view_to_cstr(str);
                            } else {
                                {
                                    var i: usize = 0;
                                    _ = &i;
                                    while (i < state.*.variables.count) : (i +%= 1) {
                                        var @"var": String_View = vw.view_create(state.*.variables.data[i].name, strlen(state.*.variables.data[i].name));
                                        _ = &@"var";
                                        if (vw.view_cmp(root.*.right.*.value.as_ident.name, @"var") != 0) {
                                            if (state.*.variables.data[i].type == @as(c_uint, @bitCast(VAR_INT))) {
                                                _ = sprintf(state.*.status_bar_msg, "%d", state.*.variables.data[i].value.as_int);
                                            } else if (state.*.variables.data[i].type == @as(c_uint, @bitCast(VAR_FLOAT))) {
                                                _ = sprintf(state.*.status_bar_msg, "%f", @as(f64, @floatCast(state.*.variables.data[i].value.as_float)));
                                            }
                                            return;
                                        }
                                    }
                                }
                            }
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 9))) => {
                            handle_save(buffer);
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 10))) => {
                            state.*.config.QUIT = 1;
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 11))) => {
                            handle_save(buffer);
                            state.*.config.QUIT = 1;
                            break;
                        },
                        else => return,
                    }
                    break;
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 3))), @as(c_uint, @bitCast(@as(c_int, 4))), @as(c_uint, @bitCast(@as(c_int, 6))), @as(c_uint, @bitCast(@as(c_int, 5))) => break,
            else => {},
        }
        break;
    }
    interpret_command(buffer, state, root.*.left);
    interpret_command(buffer, state, root.*.right);
}
pub fn print_tree(arg_node: *Node, arg_depth: usize) void {
    var node = arg_node;
    _ = &node;
    var depth = arg_depth;
    _ = &depth;
    if (node == @as(*Node, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) return;
    if (node.*.right != @as(*struct_Node, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) while (true) {
        var file: *FILE = fopen("logs/cano.log", "a");
        _ = &file;
        if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
            _ = fprintf(file, "%s:%d: NODE->RIGHT\n", "src/commands.c", @as(c_int, 514));
            _ = fclose(file);
        }
        if (!false) break;
    };
    if (node.*.left != @as(*struct_Node, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) while (true) {
        var file: *FILE = fopen("logs/cano.log", "a");
        _ = &file;
        if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
            _ = fprintf(file, "%s:%d: NODE->LEFT\n", "src/commands.c", @as(c_int, 515));
            _ = fclose(file);
        }
        if (!false) break;
    };
    while (true) {
        switch (node.*.type) {
            @as(c_uint, @bitCast(@as(c_int, 0))) => {
                while (true) {
                    var file: *FILE = fopen("logs/cano.log", "a");
                    _ = &file;
                    if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                        _ = fprintf(file, "%s:%d: EXPR\n", "src/commands.c", @as(c_int, 518));
                        _ = fclose(file);
                    }
                    if (!false) break;
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 1))) => {
                while (true) {
                    var file: *FILE = fopen("logs/cano.log", "a");
                    _ = &file;
                    if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                        _ = fprintf(file, "%s:%d: BIN\n", "src/commands.c", @as(c_int, 521));
                        _ = fclose(file);
                    }
                    if (!false) break;
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 2))) => {
                while (true) {
                    var file: *FILE = fopen("logs/cano.log", "a");
                    _ = &file;
                    if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                        _ = fprintf(file, "%s:%d: KEYWORD\n", "src/commands.c", @as(c_int, 524));
                        _ = fclose(file);
                    }
                    if (!false) break;
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 3))) => {
                while (true) {
                    var file: *FILE = fopen("logs/cano.log", "a");
                    _ = &file;
                    if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                        _ = fprintf(file, "%s:%d: STR\n", "src/commands.c", @as(c_int, 527));
                        _ = fclose(file);
                    }
                    if (!false) break;
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 4))) => {
                while (true) {
                    var file: *FILE = fopen("logs/cano.log", "a");
                    _ = &file;
                    if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                        _ = fprintf(file, "%s:%d: IDENT\n", "src/commands.c", @as(c_int, 530));
                        _ = fclose(file);
                    }
                    if (!false) break;
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 5))) => {
                while (true) {
                    var file: *FILE = fopen("logs/cano.log", "a");
                    _ = &file;
                    if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                        _ = fprintf(file, "%s:%d: CONFIG\n", "src/commands.c", @as(c_int, 533));
                        _ = fclose(file);
                    }
                    if (!false) break;
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 6))) => {
                while (true) {
                    var file: *FILE = fopen("logs/cano.log", "a");
                    _ = &file;
                    if (file != @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                        _ = fprintf(file, "%s:%d: INT\n", "src/commands.c", @as(c_int, 536));
                        _ = fclose(file);
                    }
                    if (!false) break;
                }
                break;
            },
            else => {},
        }
        break;
    }
    print_tree(node.*.left, depth +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    print_tree(node.*.right, depth +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
}
pub fn execute_command(arg_buffer: *Buffer, arg_state: *State, arg_command: *Command_Token, arg_command_s: usize) c_int {
    var buffer = arg_buffer;
    _ = &buffer;
    var state = arg_state;
    _ = &state;
    var command = arg_command;
    _ = &command;
    var command_s = arg_command_s;
    _ = &command_s;
    while (true) {
        if (!(command_s > @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))))) {
            frontend_end();
            _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/commands.c", @as(c_int, 544));
            _ = fprintf(stderr, "Invalid command size");
            _ = fprintf(stderr, "\n");
            exit(@as(c_int, 1));
        }
        if (!false) break;
    }
    var root: *Node = parse_command(state, command, command_s);
    _ = &root;
    if (root == @as(*Node, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) return 1;
    print_tree(root, @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))));
    interpret_command(buffer, state, root);
    return 0;
}
pub const YELLOW_COLOR: c_int = 1;
pub const BLUE_COLOR: c_int = 2;
pub const GREEN_COLOR: c_int = 3;
pub const RED_COLOR: c_int = 4;
pub const CYAN_COLOR: c_int = 5;
pub const MAGENTA_COLOR: c_int = 6;
pub const Color_Pairs = c_uint;
pub const Custom_Color = extern struct {
    custom_slot: Color_Pairs = @import("std").mem.zeroes(Color_Pairs),
    custom_id: c_int = @import("std").mem.zeroes(c_int),
    custom_r: c_int = @import("std").mem.zeroes(c_int),
    custom_g: c_int = @import("std").mem.zeroes(c_int),
    custom_b: c_int = @import("std").mem.zeroes(c_int),
};
pub const Color_Arr = extern struct {
    arr: *Custom_Color = @import("std").mem.zeroes(*Custom_Color),
    arr_s: usize = @import("std").mem.zeroes(usize),
};
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
pub extern fn __ctype_get_mb_cur_max() usize;
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
// pub const u_char = __u_char;
// pub const u_short = __u_short;
// pub const u_int = __u_int;
// pub const u_long = __u_long;
// pub const quad_t = __quad_t;
// pub const u_quad_t = __u_quad_t;
// pub const fsid_t = __fsid_t;
// pub const loff_t = __loff_t;
// pub const ino_t = __ino_t;
// pub const dev_t = __dev_t;
// pub const gid_t = __gid_t;
// pub const mode_t = __mode_t;
// pub const nlink_t = __nlink_t;
// pub const uid_t = __uid_t;
// pub const pid_t = __pid_t;
// pub const id_t = __id_t;
// pub const daddr_t = __daddr_t;
// pub const caddr_t = __caddr_t;
// pub const key_t = __key_t;
// pub const clock_t = __clock_t;
// pub const clockid_t = __clockid_t;
// pub const time_t = __time_t;
// pub const timer_t = __timer_t;
// pub const ulong = c_ulong;
// pub const ushort = c_ushort;
// pub const uint = c_uint;
// pub const u_int8_t = __uint8_t;
// pub const u_int16_t = __uint16_t;
// pub const u_int32_t = __uint32_t;
// pub const u_int64_t = __uint64_t;
// pub const register_t = c_long;
// pub fn __bswap_16(arg___bsx: __uint16_t) callconv(.C) __uint16_t {
//     var __bsx = arg___bsx;
//     _ = &__bsx;
//     return @as(__uint16_t, @bitCast(@as(c_short, @truncate(((@as(c_int, @bitCast(@as(c_uint, __bsx))) >> @intCast(8)) & @as(c_int, 255)) | ((@as(c_int, @bitCast(@as(c_uint, __bsx))) & @as(c_int, 255)) << @intCast(8))))));
// }
// pub fn __bswap_32(arg___bsx: __uint32_t) callconv(.C) __uint32_t {
//     var __bsx = arg___bsx;
//     _ = &__bsx;
//     return ((((__bsx & @as(c_uint, 4278190080)) >> @intCast(24)) | ((__bsx & @as(c_uint, 16711680)) >> @intCast(8))) | ((__bsx & @as(c_uint, 65280)) << @intCast(8))) | ((__bsx & @as(c_uint, 255)) << @intCast(24));
// }
// pub fn __bswap_64(arg___bsx: __uint64_t) callconv(.C) __uint64_t {
//     var __bsx = arg___bsx;
//     _ = &__bsx;
//     return @as(__uint64_t, @bitCast(@as(c_ulong, @truncate(((((((((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 18374686479671623680)) >> @intCast(56)) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 71776119061217280)) >> @intCast(40))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 280375465082880)) >> @intCast(24))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 1095216660480)) >> @intCast(8))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 4278190080)) << @intCast(8))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 16711680)) << @intCast(24))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 65280)) << @intCast(40))) | ((@as(c_ulonglong, @bitCast(@as(c_ulonglong, __bsx))) & @as(c_ulonglong, 255)) << @intCast(56))))));
// }
// pub fn __uint16_identity(arg___x: __uint16_t) callconv(.C) __uint16_t {
//     var __x = arg___x;
//     _ = &__x;
//     return __x;
// }
// pub fn __uint32_identity(arg___x: __uint32_t) callconv(.C) __uint32_t {
//     var __x = arg___x;
//     _ = &__x;
//     return __x;
// }
// pub fn __uint64_identity(arg___x: __uint64_t) callconv(.C) __uint64_t {
//     var __x = arg___x;
//     _ = &__x;
//     return __x;
// }
// pub const __sigset_t = extern struct {
//     __val: [16]c_ulong = @import("std").mem.zeroes([16]c_ulong),
// };
// pub const sigset_t = __sigset_t;
// pub const struct_timeval = extern struct {
//     tv_sec: __time_t = @import("std").mem.zeroes(__time_t),
//     tv_usec: __suseconds_t = @import("std").mem.zeroes(__suseconds_t),
// };
// pub const struct_timespec = extern struct {
//     tv_sec: __time_t = @import("std").mem.zeroes(__time_t),
//     tv_nsec: __syscall_slong_t = @import("std").mem.zeroes(__syscall_slong_t),
// };
// pub const suseconds_t = __suseconds_t;
// pub const __fd_mask = c_long;
// pub const fd_set = extern struct {
//     __fds_bits: [16]__fd_mask = @import("std").mem.zeroes([16]__fd_mask),
// };
// pub const fd_mask = __fd_mask;
// pub extern fn select(__nfds: c_int, noalias __readfds: *fd_set, noalias __writefds: *fd_set, noalias __exceptfds: *fd_set, noalias __timeout: *struct_timeval) c_int;
// pub extern fn pselect(__nfds: c_int, noalias __readfds: *fd_set, noalias __writefds: *fd_set, noalias __exceptfds: *fd_set, noalias __timeout: *const struct_timespec, noalias __sigmask: *const __sigset_t) c_int;
// pub const blksize_t = __blksize_t;
// pub const blkcnt_t = __blkcnt_t;
// pub const fsblkcnt_t = __fsblkcnt_t;
// pub const fsfilcnt_t = __fsfilcnt_t;
// const struct_unnamed_6 = extern struct {
//     __low: c_uint = @import("std").mem.zeroes(c_uint),
//     __high: c_uint = @import("std").mem.zeroes(c_uint),
// };
// pub const __atomic_wide_counter = extern union {
//     __value64: c_ulonglong,
//     __value32: struct_unnamed_6,
// };
// pub const struct___pthread_internal_list = extern struct {
//     __prev: *struct___pthread_internal_list = @import("std").mem.zeroes(*struct___pthread_internal_list),
//     __next: *struct___pthread_internal_list = @import("std").mem.zeroes(*struct___pthread_internal_list),
// };
// pub const __pthread_list_t = struct___pthread_internal_list;
// pub const struct___pthread_internal_slist = extern struct {
//     __next: *struct___pthread_internal_slist = @import("std").mem.zeroes(*struct___pthread_internal_slist),
// };
// pub const __pthread_slist_t = struct___pthread_internal_slist;
// pub const struct___pthread_mutex_s = extern struct {
//     __lock: c_int = @import("std").mem.zeroes(c_int),
//     __count: c_uint = @import("std").mem.zeroes(c_uint),
//     __owner: c_int = @import("std").mem.zeroes(c_int),
//     __nusers: c_uint = @import("std").mem.zeroes(c_uint),
//     __kind: c_int = @import("std").mem.zeroes(c_int),
//     __spins: c_short = @import("std").mem.zeroes(c_short),
//     __elision: c_short = @import("std").mem.zeroes(c_short),
//     __list: __pthread_list_t = @import("std").mem.zeroes(__pthread_list_t),
// };
// pub const struct___pthread_rwlock_arch_t = extern struct {
//     __readers: c_uint = @import("std").mem.zeroes(c_uint),
//     __writers: c_uint = @import("std").mem.zeroes(c_uint),
//     __wrphase_futex: c_uint = @import("std").mem.zeroes(c_uint),
//     __writers_futex: c_uint = @import("std").mem.zeroes(c_uint),
//     __pad3: c_uint = @import("std").mem.zeroes(c_uint),
//     __pad4: c_uint = @import("std").mem.zeroes(c_uint),
//     __cur_writer: c_int = @import("std").mem.zeroes(c_int),
//     __shared: c_int = @import("std").mem.zeroes(c_int),
//     __rwelision: i8 = @import("std").mem.zeroes(i8),
//     __pad1: [7]u8 = @import("std").mem.zeroes([7]u8),
//     __pad2: c_ulong = @import("std").mem.zeroes(c_ulong),
//     __flags: c_uint = @import("std").mem.zeroes(c_uint),
// };
// pub const struct___pthread_cond_s = extern struct {
//     __wseq: __atomic_wide_counter = @import("std").mem.zeroes(__atomic_wide_counter),
//     __g1_start: __atomic_wide_counter = @import("std").mem.zeroes(__atomic_wide_counter),
//     __g_refs: [2]c_uint = @import("std").mem.zeroes([2]c_uint),
//     __g_size: [2]c_uint = @import("std").mem.zeroes([2]c_uint),
//     __g1_orig_size: c_uint = @import("std").mem.zeroes(c_uint),
//     __wrefs: c_uint = @import("std").mem.zeroes(c_uint),
//     __g_signals: [2]c_uint = @import("std").mem.zeroes([2]c_uint),
// };
// pub const __tss_t = c_uint;
// pub const __thrd_t = c_ulong;
// pub const __once_flag = extern struct {
//     __data: c_int = @import("std").mem.zeroes(c_int),
// };
// pub const pthread_t = c_ulong;
// pub const pthread_mutexattr_t = extern union {
//     __size: [4]u8,
//     __align: c_int,
// };
// pub const pthread_condattr_t = extern union {
//     __size: [4]u8,
//     __align: c_int,
// };
// pub const pthread_key_t = c_uint;
// pub const pthread_once_t = c_int;
// pub const union_pthread_attr_t = extern union {
//     __size: [56]u8,
//     __align: c_long,
// };
// pub const pthread_attr_t = union_pthread_attr_t;
// pub const pthread_mutex_t = extern union {
//     __data: struct___pthread_mutex_s,
//     __size: [40]u8,
//     __align: c_long,
// };
// pub const pthread_cond_t = extern union {
//     __data: struct___pthread_cond_s,
//     __size: [48]u8,
//     __align: c_longlong,
// };
// pub const pthread_rwlock_t = extern union {
//     __data: struct___pthread_rwlock_arch_t,
//     __size: [56]u8,
//     __align: c_long,
// };
// pub const pthread_rwlockattr_t = extern union {
//     __size: [8]u8,
//     __align: c_long,
// };
// pub const pthread_spinlock_t = c_int;
// pub const pthread_barrier_t = extern union {
//     __size: [32]u8,
//     __align: c_long,
// };
// pub const pthread_barrierattr_t = extern union {
//     __size: [4]u8,
//     __align: c_int,
// };
// pub extern fn random() c_long;
// pub extern fn srandom(__seed: c_uint) void;
// pub extern fn initstate(__seed: c_uint, __statebuf: *u8, __statelen: usize) *u8;
// pub extern fn setstate(__statebuf: *u8) *u8;
// pub const struct_random_data = extern struct {
//     fptr: *i32 = @import("std").mem.zeroes(*i32),
//     rptr: *i32 = @import("std").mem.zeroes(*i32),
//     state: *i32 = @import("std").mem.zeroes(*i32),
//     rand_type: c_int = @import("std").mem.zeroes(c_int),
//     rand_deg: c_int = @import("std").mem.zeroes(c_int),
//     rand_sep: c_int = @import("std").mem.zeroes(c_int),
//     end_ptr: *i32 = @import("std").mem.zeroes(*i32),
// };
// pub extern fn random_r(noalias __buf: *struct_random_data, noalias __result: *i32) c_int;
// pub extern fn srandom_r(__seed: c_uint, __buf: *struct_random_data) c_int;
// pub extern fn initstate_r(__seed: c_uint, noalias __statebuf: *u8, __statelen: usize, noalias __buf: *struct_random_data) c_int;
// pub extern fn setstate_r(noalias __statebuf: *u8, noalias __buf: *struct_random_data) c_int;
// pub extern fn rand() c_int;
// pub extern fn srand(__seed: c_uint) void;
// pub extern fn rand_r(__seed: *c_uint) c_int;
// pub extern fn drand48() f64;
// pub extern fn erand48(__xsubi: *c_ushort) f64;
// pub extern fn lrand48() c_long;
// pub extern fn nrand48(__xsubi: *c_ushort) c_long;
// pub extern fn mrand48() c_long;
// pub extern fn jrand48(__xsubi: *c_ushort) c_long;
// pub extern fn srand48(__seedval: c_long) void;
// pub extern fn seed48(__seed16v: *c_ushort) *c_ushort;
// pub extern fn lcong48(__param: *c_ushort) void;
// pub const struct_drand48_data = extern struct {
//     __x: [3]c_ushort = @import("std").mem.zeroes([3]c_ushort),
//     __old_x: [3]c_ushort = @import("std").mem.zeroes([3]c_ushort),
//     __c: c_ushort = @import("std").mem.zeroes(c_ushort),
//     __init: c_ushort = @import("std").mem.zeroes(c_ushort),
//     __a: c_ulonglong = @import("std").mem.zeroes(c_ulonglong),
// };
// pub extern fn drand48_r(noalias __buffer: *struct_drand48_data, noalias __result: *f64) c_int;
// pub extern fn erand48_r(__xsubi: *c_ushort, noalias __buffer: *struct_drand48_data, noalias __result: *f64) c_int;
// pub extern fn lrand48_r(noalias __buffer: *struct_drand48_data, noalias __result: *c_long) c_int;
// pub extern fn nrand48_r(__xsubi: *c_ushort, noalias __buffer: *struct_drand48_data, noalias __result: *c_long) c_int;
// pub extern fn mrand48_r(noalias __buffer: *struct_drand48_data, noalias __result: *c_long) c_int;
// pub extern fn jrand48_r(__xsubi: *c_ushort, noalias __buffer: *struct_drand48_data, noalias __result: *c_long) c_int;
// pub extern fn srand48_r(__seedval: c_long, __buffer: *struct_drand48_data) c_int;
// pub extern fn seed48_r(__seed16v: *c_ushort, __buffer: *struct_drand48_data) c_int;
// pub extern fn lcong48_r(__param: *c_ushort, __buffer: *struct_drand48_data) c_int;
// pub extern fn arc4random() __uint32_t;
// pub extern fn arc4random_buf(__buf: ?*anyopaque, __size: usize) void;
// pub extern fn arc4random_uniform(__upper_bound: __uint32_t) __uint32_t;
pub extern fn malloc(__size: c_ulong) ?*anyopaque;
pub extern fn calloc(__nmemb: c_ulong, __size: c_ulong) ?*anyopaque;
// pub extern fn realloc(__ptr: ?*anyopaque, __size: c_ulong) ?*anyopaque;
pub extern fn free(__ptr: ?*anyopaque) void;
// pub extern fn reallocarray(__ptr: ?*anyopaque, __nmemb: usize, __size: usize) ?*anyopaque;
// pub extern fn alloca(__size: c_ulong) ?*anyopaque;
// pub extern fn valloc(__size: usize) ?*anyopaque;
// pub extern fn posix_memalign(__memptr: *?*anyopaque, __alignment: usize, __size: usize) c_int;
// pub extern fn aligned_alloc(__alignment: c_ulong, __size: c_ulong) ?*anyopaque;
// pub extern fn abort() noreturn;
// pub extern fn atexit(__func: ?*const fn () callconv(.C) void) c_int;
// pub extern fn at_quick_exit(__func: ?*const fn () callconv(.C) void) c_int;
// pub extern fn on_exit(__func: ?*const fn (c_int, ?*anyopaque) callconv(.C) void, __arg: ?*anyopaque) c_int;
pub extern fn exit(__status: c_int) noreturn;
// pub extern fn quick_exit(__status: c_int) noreturn;
// pub extern fn _Exit(__status: c_int) noreturn;
// pub extern fn getenv(__name: *const u8) *u8;
// pub extern fn putenv(__string: *u8) c_int;
// pub extern fn setenv(__name: *const u8, __value: *const u8, __replace: c_int) c_int;
// pub extern fn unsetenv(__name: *const u8) c_int;
// pub extern fn clearenv() c_int;
// pub extern fn mktemp(__template: *u8) *u8;
// pub extern fn mkstemp(__template: *u8) c_int;
// pub extern fn mkstemps(__template: *u8, __suffixlen: c_int) c_int;
// pub extern fn mkdtemp(__template: *u8) *u8;
// pub extern fn system(__command: *const u8) c_int;
// pub extern fn realpath(noalias __name: *const u8, noalias __resolved: *u8) *u8;
// pub const __compar_fn_t = ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int;
// pub extern fn bsearch(__key: ?*const anyopaque, __base: ?*const anyopaque, __nmemb: usize, __size: usize, __compar: __compar_fn_t) ?*anyopaque;
// pub extern fn qsort(__base: ?*anyopaque, __nmemb: usize, __size: usize, __compar: __compar_fn_t) void;
// pub extern fn abs(__x: c_int) c_int;
// pub extern fn labs(__x: c_long) c_long;
// pub extern fn llabs(__x: c_longlong) c_longlong;
// pub extern fn div(__numer: c_int, __denom: c_int) div_t;
// pub extern fn ldiv(__numer: c_long, __denom: c_long) ldiv_t;
// pub extern fn lldiv(__numer: c_longlong, __denom: c_longlong) lldiv_t;
// pub extern fn ecvt(__value: f64, __ndigit: c_int, noalias __decpt: *c_int, noalias __sign: *c_int) *u8;
// pub extern fn fcvt(__value: f64, __ndigit: c_int, noalias __decpt: *c_int, noalias __sign: *c_int) *u8;
// pub extern fn gcvt(__value: f64, __ndigit: c_int, __buf: *u8) *u8;
// pub extern fn qecvt(__value: c_longdouble, __ndigit: c_int, noalias __decpt: *c_int, noalias __sign: *c_int) *u8;
// pub extern fn qfcvt(__value: c_longdouble, __ndigit: c_int, noalias __decpt: *c_int, noalias __sign: *c_int) *u8;
// pub extern fn qgcvt(__value: c_longdouble, __ndigit: c_int, __buf: *u8) *u8;
// pub extern fn ecvt_r(__value: f64, __ndigit: c_int, noalias __decpt: *c_int, noalias __sign: *c_int, noalias __buf: *u8, __len: usize) c_int;
// pub extern fn fcvt_r(__value: f64, __ndigit: c_int, noalias __decpt: *c_int, noalias __sign: *c_int, noalias __buf: *u8, __len: usize) c_int;
// pub extern fn qecvt_r(__value: c_longdouble, __ndigit: c_int, noalias __decpt: *c_int, noalias __sign: *c_int, noalias __buf: *u8, __len: usize) c_int;
// pub extern fn qfcvt_r(__value: c_longdouble, __ndigit: c_int, noalias __decpt: *c_int, noalias __sign: *c_int, noalias __buf: *u8, __len: usize) c_int;
// pub extern fn mblen(__s: *const u8, __n: usize) c_int;
// pub extern fn mbtowc(noalias __pwc: *wchar_t, noalias __s: *const u8, __n: usize) c_int;
// pub extern fn wctomb(__s: *u8, __wchar: wchar_t) c_int;
// pub extern fn mbstowcs(noalias __pwcs: *wchar_t, noalias __s: *const u8, __n: usize) usize;
// pub extern fn wcstombs(noalias __s: *u8, noalias __pwcs: *const wchar_t, __n: usize) usize;
// pub extern fn rpmatch(__response: *const u8) c_int;
// pub extern fn getsubopt(noalias __optionp: **u8, noalias __tokens: *const *u8, noalias __valuep: **u8) c_int;
// pub extern fn getloadavg(__loadavg: *f64, __nelem: c_int) c_int;
pub extern fn memcpy(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
// pub extern fn memmove(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
// pub extern fn memccpy(__dest: ?*anyopaque, __src: ?*const anyopaque, __c: c_int, __n: c_ulong) ?*anyopaque;
// pub extern fn memset(__s: ?*anyopaque, __c: c_int, __n: c_ulong) ?*anyopaque;
// pub extern fn memcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: c_ulong) c_int;
// pub extern fn __memcmpeq(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: usize) c_int;
// pub extern fn memchr(__s: ?*const anyopaque, __c: c_int, __n: c_ulong) ?*anyopaque;
// pub extern fn strcpy(__dest: *u8, __src: *const u8) *u8;
// pub extern fn strncpy(__dest: *u8, __src: *const u8, __n: c_ulong) *u8;
// pub extern fn strcat(__dest: *u8, __src: *const u8) *u8;
// pub extern fn strncat(__dest: *u8, __src: *const u8, __n: c_ulong) *u8;
// pub extern fn strcmp(__s1: *const u8, __s2: *const u8) c_int;
// pub extern fn strncmp(__s1: *const u8, __s2: *const u8, __n: c_ulong) c_int;
// pub extern fn strcoll(__s1: *const u8, __s2: *const u8) c_int;
// pub extern fn strxfrm(__dest: *u8, __src: *const u8, __n: c_ulong) c_ulong;
// pub extern fn strcoll_l(__s1: *const u8, __s2: *const u8, __l: locale_t) c_int;
// pub extern fn strxfrm_l(__dest: *u8, __src: *const u8, __n: usize, __l: locale_t) usize;
// pub extern fn strdup(__s: *const u8) *u8;
// pub extern fn strndup(__string: *const u8, __n: c_ulong) *u8;
// pub extern fn strchr(__s: *const u8, __c: c_int) *u8;
// pub extern fn strrchr(__s: *const u8, __c: c_int) *u8;
// pub extern fn strchrnul(__s: *const u8, __c: c_int) *u8;
// pub extern fn strcspn(__s: *const u8, __reject: *const u8) c_ulong;
// pub extern fn strspn(__s: *const u8, __accept: *const u8) c_ulong;
// pub extern fn strpbrk(__s: *const u8, __accept: *const u8) *u8;
// pub extern fn strstr(__haystack: *const u8, __needle: *const u8) *u8;
// pub extern fn strtok(__s: *u8, __delim: *const u8) *u8;
// pub extern fn __strtok_r(noalias __s: *u8, noalias __delim: *const u8, noalias __save_ptr: **u8) *u8;
// pub extern fn strtok_r(noalias __s: *u8, noalias __delim: *const u8, noalias __save_ptr: **u8) *u8;
// pub extern fn strcasestr(__haystack: *const u8, __needle: *const u8) *u8;
// pub extern fn memmem(__haystack: ?*const anyopaque, __haystacklen: usize, __needle: ?*const anyopaque, __needlelen: usize) ?*anyopaque;
// pub extern fn __mempcpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __n: usize) ?*anyopaque;
// pub extern fn mempcpy(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
pub extern fn strlen(__s: *const u8) c_ulong;
// pub extern fn strnlen(__string: *const u8, __maxlen: usize) usize;
// pub extern fn strerror(__errnum: c_int) *u8;
// pub extern fn strerror_r(__errnum: c_int, __buf: *u8, __buflen: usize) c_int;
// pub extern fn strerror_l(__errnum: c_int, __l: locale_t) *u8;
// pub extern fn bcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: c_ulong) c_int;
// pub extern fn bcopy(__src: ?*const anyopaque, __dest: ?*anyopaque, __n: c_ulong) void;
// pub extern fn bzero(__s: ?*anyopaque, __n: c_ulong) void;
// pub extern fn index(__s: *const u8, __c: c_int) *u8;
// pub extern fn rindex(__s: *const u8, __c: c_int) *u8;
// pub extern fn ffs(__i: c_int) c_int;
// pub extern fn ffsl(__l: c_long) c_int;
// pub extern fn ffsll(__ll: c_longlong) c_int;
// pub extern fn strcasecmp(__s1: *const u8, __s2: *const u8) c_int;
// pub extern fn strncasecmp(__s1: *const u8, __s2: *const u8, __n: c_ulong) c_int;
// pub extern fn strcasecmp_l(__s1: *const u8, __s2: *const u8, __loc: locale_t) c_int;
// pub extern fn strncasecmp_l(__s1: *const u8, __s2: *const u8, __n: usize, __loc: locale_t) c_int;
// pub extern fn explicit_bzero(__s: ?*anyopaque, __n: usize) void;
// pub extern fn strsep(noalias __stringp: **u8, noalias __delim: *const u8) *u8;
// pub extern fn strsignal(__sig: c_int) *u8;
// pub extern fn __stpcpy(noalias __dest: *u8, noalias __src: *const u8) *u8;
// pub extern fn stpcpy(__dest: *u8, __src: *const u8) *u8;
// pub extern fn __stpncpy(noalias __dest: *u8, noalias __src: *const u8, __n: usize) *u8;
// pub extern fn stpncpy(__dest: *u8, __src: *const u8, __n: c_ulong) *u8;
// pub extern fn strlcpy(__dest: *u8, __src: *const u8, __n: c_ulong) c_ulong;
// pub extern fn strlcat(__dest: *u8, __src: *const u8, __n: c_ulong) c_ulong;
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
// pub extern fn is_keyword(word: *u8, word_s: usize) c_int;
// pub extern fn is_type(word: *u8, word_s: usize) c_int;
// pub extern fn strip_off_dot(str: *u8, str_s: usize) *u8;
// pub extern fn read_file_to_str(filename: *u8, contents: **u8) usize;
// pub extern fn parse_syntax_file(filename: *u8) Color_Arr;
// pub extern fn is_in_tokens_index(token_arr: *Token, token_s: usize, index: usize, size: *usize, color: *Color_Pairs) c_int;
// pub extern fn generate_word(view: *String_View, contents: *u8) Token;
// pub extern fn generate_tokens(line: *u8, line_s: usize, token_arr: *Token, token_arr_capacity: *usize) usize;
// pub extern fn read_file_by_lines(filename: *u8, lines: ***u8, lines_s: *usize) c_int;
// pub extern fn dynstr_to_data(str: Sized_Str) Data;
// pub extern fn handle_cursor_shape(state: *State) void;
// pub extern fn free_buffer(buffer: *Buffer) void;
// pub extern fn free_undo(undo: *Undo) void;
// pub extern fn free_undo_stack(undo: *Undo_Stack) void;
pub extern fn handle_save(buffer: *Buffer) void;
// pub extern fn load_buffer_from_file(filename: *u8) *Buffer;
// pub extern fn shift_str_left(str: *u8, str_s: *usize, index: usize) void;
// pub extern fn shift_str_right(str: *u8, str_s: *usize, index: usize) void;
// pub extern fn undo_push(state: *State, stack: *Undo_Stack, undo: Undo) void;
// pub extern fn undo_pop(stack: *Undo_Stack) Undo;
// pub extern fn find_opposite_brace(opening: u8) Brace;
// pub extern fn check_keymaps(buffer: *Buffer, state: *State) c_int;
// pub extern fn scan_files(state: *State, directory: *u8) void;
// pub extern fn free_files(files: **Files) void;
// pub extern fn load_config_from_file(state: *State, buffer: *Buffer, config_filename: *u8, syntax_filename: *u8) void;
// pub extern fn contains_c_extension(str: *const u8) c_int;
// pub extern fn check_for_errors(args: ?*anyopaque) ?*anyopaque;
// pub extern fn rgb_to_ncurses(r: c_int, g: c_int, b: c_int) Ncurses_Color;
// pub extern fn init_ncurses_color(id: c_int, r: c_int, g: c_int, b: c_int) void;
// pub extern fn reset_command(command: *u8, command_s: *usize) void;
pub extern fn __assert_fail(__assertion: *const u8, __file: *const u8, __line: c_uint, __function: *const u8) noreturn;
// pub extern fn __assert_perror_fail(__errnum: c_int, __file: *const u8, __line: c_uint, __function: *const u8) noreturn;
// pub extern fn __assert(__assertion: *const u8, __file: *const u8, __line: c_int) noreturn;

pub var tt_string: [18][*:0]const u8 = [18][*:0]const u8{
    "set_var",
    "set_output",
    "set_map",
    "let",
    "plus",
    "minus",
    "mult",
    "div",
    "echo",
    "w",
    "e",
    "we",
    "ident",
    "special key",
    "string",
    "config var",
    "int",
    "float",
};
pub var ctrl_keys: [26]Ctrl_Key = [26]Ctrl_Key{
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-a>".*;
        }).static,
        .value = @as(c_int, 'a') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-b>".*;
        }).static,
        .value = @as(c_int, 'b') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-c>".*;
        }).static,
        .value = @as(c_int, 'c') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-d>".*;
        }).static,
        .value = @as(c_int, 'd') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-e>".*;
        }).static,
        .value = @as(c_int, 'e') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-f>".*;
        }).static,
        .value = @as(c_int, 'f') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-g>".*;
        }).static,
        .value = @as(c_int, 'g') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-h>".*;
        }).static,
        .value = @as(c_int, 'h') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-i>".*;
        }).static,
        .value = @as(c_int, 'i') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-j>".*;
        }).static,
        .value = @as(c_int, 'j') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-k>".*;
        }).static,
        .value = @as(c_int, 'k') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-l>".*;
        }).static,
        .value = @as(c_int, 'l') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-m>".*;
        }).static,
        .value = @as(c_int, 'm') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-n>".*;
        }).static,
        .value = @as(c_int, 'n') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-o>".*;
        }).static,
        .value = @as(c_int, 'o') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-p>".*;
        }).static,
        .value = @as(c_int, 'p') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-q>".*;
        }).static,
        .value = @as(c_int, 'q') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-r>".*;
        }).static,
        .value = @as(c_int, 'r') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-s>".*;
        }).static,
        .value = @as(c_int, 's') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-t>".*;
        }).static,
        .value = @as(c_int, 't') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-u>".*;
        }).static,
        .value = @as(c_int, 'u') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-v>".*;
        }).static,
        .value = @as(c_int, 'v') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-w>".*;
        }).static,
        .value = @as(c_int, 'w') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-x>".*;
        }).static,
        .value = @as(c_int, 'x') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-y>".*;
        }).static,
        .value = @as(c_int, 'y') & @as(c_int, 31),
    },
    Ctrl_Key{
        .name = &(struct {
            var static = "<ctrl-z>".*;
        }).static,
        .value = @as(c_int, 'z') & @as(c_int, 31),
    },
};

pub fn view_chop_left(arg_view: String_View, arg_amount: usize) callconv(.C) String_View {
    var view = arg_view;
    _ = &view;
    var amount = arg_amount;
    _ = &amount;
    if (view.len < amount) {
        view.data += view.len; // @as(*u8, @ptrFromInt(view.len));
        view.len = 0;
        return view;
    }
    view.data += amount; // @as(*u8, @ptrFromInt(amount));
    view.len -%= amount;
    return view;
}
pub fn view_chop_right(arg_view: String_View) callconv(.C) String_View {
    var view = arg_view;
    _ = &view;
    if (view.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        view.len -%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    }
    return view;
}
pub fn view_string_internals(arg_view: String_View) callconv(.C) String_View {
    var view = arg_view;
    _ = &view;
    view = view_chop_left(view, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    view = view_chop_right(view);
    return view;
}
