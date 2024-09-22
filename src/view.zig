pub const _ISspace: c_int = 8192;
pub extern fn __ctype_b_loc() [*c][*c]const c_ushort;
pub extern fn strtof(__nptr: [*c]const u8, __endptr: [*c][*c]u8) f32;
pub extern fn strtol(__nptr: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_long;
pub extern fn malloc(__size: c_ulong) ?*anyopaque;
pub extern fn strncpy(__dest: [*c]u8, __src: [*c]const u8, __n: c_ulong) [*c]u8;
pub extern fn strncat(__dest: [*c]u8, __src: [*c]const u8, __n: c_ulong) [*c]u8;
pub extern fn strncmp(__s1: [*c]const u8, __s2: [*c]const u8, __n: c_ulong) c_int;

pub const String_View = extern struct {
    data: [*c]u8 = null,
    len: usize = 0,
};

fn view_create(data: [*c]u8, len: usize) String_View {
    return .{ .data = data, .len = len };
}

pub export fn view_cmp(a: String_View, b: String_View) c_int {
    return if (a.len != b.len) @as(c_int, 0) else @intFromBool(!(strncmp(a.data, b.data, a.len) != 0));
}

pub export fn view_to_cstr(view: String_View) [*c]u8 {
    var str: [*c]u8 = @as([*c]u8, @ptrCast(@alignCast(malloc((@sizeOf(u8) *% view.len) +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
    _ = &str;
    _ = strncpy(str, view.data, view.len);
    str[view.len] = '\x00';
    return str;
}

pub export fn view_trim_left(view: String_View) String_View {
    var i: usize = 0;
    while ((i < view.len) and ((@as(c_int, @bitCast(@as(c_uint, (blk: {
        const tmp = @as(c_int, @bitCast(@as(c_uint, view.data[i])));
        if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISspace)))))))) != 0)) {
        i +%= 1;
    }
    return view_create(view.data + i, view.len -% i);
}

pub export fn view_trim_right(arg_view: String_View) String_View {
    var view = arg_view;
    _ = &view;
    var i: usize = view.len -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    _ = &i;
    while ((i < view.len) and ((@as(c_int, @bitCast(@as(c_uint, (blk: {
        const tmp = @as(c_int, @bitCast(@as(c_uint, view.data[i])));
        if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISspace)))))))) != 0)) {
        i -%= 1;
    }
    return view_create(view.data, i +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
}

pub export fn view_contains(haystack: String_View, needle: String_View) c_int {
    if (needle.len > haystack.len) return 0;
    var compare: String_View = view_create(haystack.data, needle.len);

    var i: usize = 0;
    while (i < haystack.len) : (i += 1) {
        compare.data = haystack.data + i;
        if (view_cmp(needle, compare) != 0) return 1;
    }
    return 0;
}

pub export fn view_first_of(arg_view: String_View, arg_target: u8) usize {
    var view = arg_view;
    _ = &view;
    var target = arg_target;
    _ = &target;
    {
        var i: usize = 0;
        _ = &i;
        while (i < view.len) : (i +%= 1) if (@as(c_int, @bitCast(@as(c_uint, view.data[i]))) == @as(c_int, @bitCast(@as(c_uint, target)))) return i;
    }
    return 0;
}

pub export fn view_last_of(arg_view: String_View, arg_target: u8) usize {
    var view = arg_view;
    _ = &view;
    var target = arg_target;
    _ = &target;
    {
        var i: usize = view.len -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
        _ = &i;
        while (i > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) : (i -%= 1) if (@as(c_int, @bitCast(@as(c_uint, view.data[i]))) == @as(c_int, @bitCast(@as(c_uint, target)))) return i;
    }
    return 0;
}

pub export fn view_split(arg_view: String_View, arg_c: u8, arg_arr: [*c]String_View, arg_arr_s: usize) usize {
    var view = arg_view;
    _ = &view;
    var c = arg_c;
    _ = &c;
    var arr = arg_arr;
    _ = &arr;
    var arr_s = arg_arr_s;
    _ = &arr_s;
    var cur: [*c]u8 = view.data;
    _ = &cur;
    var arr_index: usize = 0;
    _ = &arr_index;
    var i: usize = undefined;
    _ = &i;
    {
        i = 0;
        while (i < view.len) : (i +%= 1) {
            if (@as(c_int, @bitCast(@as(c_uint, view.data[i]))) == @as(c_int, @bitCast(@as(c_uint, c)))) {
                if (arr_index < (arr_s -% @as(usize, @bitCast(@as(c_long, @as(c_int, 2)))))) {
                    arr[
                        blk: {
                            const ref = &arr_index;
                            const tmp = ref.*;
                            ref.* +%= 1;
                            break :blk tmp;
                        }
                    ] = view_create(cur, @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(view.data + i) -% @intFromPtr(cur))), @sizeOf(u8)))));
                    cur = (view.data + i) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1)))));
                } else {
                    arr[
                        blk: {
                            const ref = &arr_index;
                            const tmp = ref.*;
                            ref.* +%= 1;
                            break :blk tmp;
                        }
                    ] = view_create((view.data + i) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))), (view.len -% i) -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
                    return arr_index;
                }
            }
        }
    }
    arr[
        blk: {
            const ref = &arr_index;
            const tmp = ref.*;
            ref.* +%= 1;
            break :blk tmp;
        }
    ] = view_create(cur, @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(view.data + i) -% @intFromPtr(cur))), @sizeOf(u8)))));
    return arr_index;
}
pub export fn view_chop(arg_view: String_View, arg_c: u8) String_View {
    var view = arg_view;
    _ = &view;
    var c = arg_c;
    _ = &c;
    var i: usize = 0;
    _ = &i;
    while ((@as(c_int, @bitCast(@as(c_uint, view.data[i]))) != @as(c_int, @bitCast(@as(c_uint, c)))) and (i != view.len)) {
        i +%= 1;
    }
    if (i < view.len) {
        i +%= 1;
    }
    return view_create(view.data + i, view.len -% i);
}
pub export fn view_rev(arg_view: String_View, arg_data: [*c]u8, arg_data_s: usize) String_View {
    var view = arg_view;
    _ = &view;
    var data = arg_data;
    _ = &data;
    var data_s = arg_data_s;
    _ = &data_s;
    if (view.len >= data_s) return view_create(null, @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))));
    var result: String_View = view_create(data, view.len);
    _ = &result;
    {
        var i: c_int = @as(c_int, @bitCast(@as(c_uint, @truncate(view.len -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))))));
        _ = &i;
        while (i >= @as(c_int, 0)) : (i -= 1) {
            result.data[(view.len -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) -% @as(usize, @bitCast(@as(c_long, i)))] = (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk view.data + @as(usize, @intCast(tmp)) else break :blk view.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
        }
    }
    return result;
}
pub export fn view_find(arg_haystack: String_View, arg_needle: String_View) usize {
    var haystack = arg_haystack;
    _ = &haystack;
    var needle = arg_needle;
    _ = &needle;
    if (needle.len > haystack.len) return 0;
    var compare: String_View = view_create(haystack.data, needle.len);
    _ = &compare;
    {
        var i: usize = 0;
        _ = &i;
        while (i < haystack.len) : (i +%= 1) {
            compare.data = haystack.data + i;
            if (view_cmp(needle, compare) != 0) return i;
        }
    }
    return 0;
}
pub export fn view_to_int(arg_view: String_View) c_int {
    var view = arg_view;
    _ = &view;
    return @as(c_int, @bitCast(@as(c_int, @truncate(strtol(view.data, null, @as(c_int, 10))))));
}
pub export fn view_to_float(arg_view: String_View) f32 {
    var view = arg_view;
    _ = &view;
    return strtof(view.data, null);
}
