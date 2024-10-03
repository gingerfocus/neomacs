const fr = @import("frontend.zig");
const defs = @import("defs.zig");
const lx = @import("lex.zig");
const vw = @import("view.zig");

const FILE = defs.FILE;
const String_View = defs.String_View;

pub extern fn fclose(__stream: *FILE) c_int;
pub extern fn fopen(__filename: *const u8, __modes: *const u8) *FILE;
pub extern fn fread(__ptr: ?*anyopaque, __size: c_ulong, __n: c_ulong, __stream: *FILE) c_ulong;
pub extern fn fseek(__stream: *FILE, __off: c_long, __whence: c_int) c_int;
pub extern fn ftell(__stream: *FILE) c_long;
pub extern fn malloc(__size: c_ulong) ?*anyopaque;
pub extern fn calloc(__nmemb: c_ulong, __size: c_ulong) ?*anyopaque;
pub extern fn realloc(__ptr: ?*anyopaque, __size: c_ulong) ?*anyopaque;
pub extern fn free(__ptr: ?*anyopaque) void;
pub extern fn exit(__status: c_int) noreturn;
pub extern fn memset(__s: ?*anyopaque, __c: c_int, __n: c_ulong) ?*anyopaque;
pub extern fn memcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: c_ulong) c_int;
pub extern fn strncpy(__dest: *u8, __src: *const u8, __n: c_ulong) *u8;
pub extern fn strcmp(__s1: *const u8, __s2: *const u8) c_int;
pub extern fn strdup(__s: *const u8) *u8;
pub extern fn strlen(__s: *const u8) c_ulong;

pub const _ISalpha: c_int = 1024;
pub extern fn __ctype_b_loc() **const c_ushort;

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

pub const Type_None: c_int = 0;
pub const Type_Keyword: c_int = 1;
pub const Type_Type: c_int = 2;
pub const Type_Preprocessor: c_int = 3;
pub const Type_String: c_int = 4;
pub const Type_Comment: c_int = 5;
pub const Type_Word: c_int = 6;
pub const Token_Type = c_uint;

pub const Token = extern struct {
    type: Token_Type = @import("std").mem.zeroes(Token_Type),
    index: usize = @import("std").mem.zeroes(usize),
    size: usize = @import("std").mem.zeroes(usize),
};
pub export fn is_keyword(arg_word: *u8, arg_word_s: usize) c_int {
    var word = arg_word;
    _ = &word;
    var word_s = arg_word_s;
    _ = &word_s;
    {
        var i: usize = 0;
        _ = &i;
        while (i < keywords_s) : (i +%= 1) {
            while (true) {
                if (!(keywords[i] != @as(*u8, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) {
                    fr.frontend_end();
                    // _ = fprintf(stderr, "%s:%d: ASSERTION FAILED: ", "src/lex.c", @as(c_int, 54));
                    // _ = fprintf(stderr, "keywords were NOT generated properly");
                    // _ = fprintf(stderr, "\n");
                    exit(@as(c_int, 1));
                }
                if (!false) break;
            }
            if (word_s < strlen(keywords[i])) continue;
            if (strcmp(word, keywords[i]) == @as(c_int, 0)) return 1;
        }
    }
    return 0;
}
pub export fn is_type(arg_word: *u8, arg_word_s: usize) c_int {
    var word = arg_word;
    _ = &word;
    var word_s = arg_word_s;
    _ = &word_s;
    {
        var i: usize = 0;
        _ = &i;
        while (i < types_s) : (i +%= 1) {
            if (word_s < strlen(types[i])) continue;
            if (strcmp(word, types[i]) == @as(c_int, 0)) return 1;
        }
    }
    return 0;
}
pub export fn strip_off_dot(arg_str: *u8, arg_str_s: usize) *u8 {
    var str = arg_str;
    _ = &str;
    var str_s = arg_str_s;
    _ = &str_s;
    var p: *u8 = str + str_s;
    _ = &p;
    while ((p > str) and (@as(c_int, @bitCast(@as(c_uint, p.*))) != @as(c_int, '.'))) : (p -= 1) {}
    return if (p == str) null else strdup(blk: {
        const ref = &p;
        ref.* += 1;
        break :blk ref.*;
    });
}
pub export fn read_file_to_str(arg_filename: *u8, arg_contents: **u8) usize {
    var filename = arg_filename;
    _ = &filename;
    var contents = arg_contents;
    _ = &contents;
    var file: *FILE = fopen(filename, "r");
    _ = &file;
    if (file == @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
        return 0;
    }
    _ = fseek(file, @as(c_long, @bitCast(@as(c_long, @as(c_int, 0)))), @as(c_int, 2));
    var length: usize = @as(usize, @bitCast(ftell(file)));
    _ = &length;
    _ = fseek(file, @as(c_long, @bitCast(@as(c_long, @as(c_int, 0)))), @as(c_int, 0));
    contents.* = @as(*u8, @ptrCast(@alignCast(malloc((@sizeOf(u8) *% length) +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
    _ = fread(@as(?*anyopaque, @ptrCast(contents.*)), @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))), length, file);
    _ = fclose(file);
    contents[length] = null;
    return length;
}
pub export fn parse_syntax_file(arg_filename: *u8) Color_Arr {
    var filename = arg_filename;
    _ = &filename;
    keywords_s = 0;
    types_s = 0;
    var contents: *u8 = null;
    _ = &contents;
    var contents_s: usize = read_file_to_str(filename, &contents);
    _ = &contents_s;
    if (contents_s == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        return Color_Arr{
            .arr = null,
            .arr_s = @import("std").mem.zeroes(usize),
        };
    }
    var contents_view: String_View = vw.view_create(contents, contents_s);
    _ = &contents_view;
    var num_of_dots: usize = 0;
    _ = &num_of_dots;
    {
        var i: usize = 0;
        _ = &i;
        while (i < contents_view.len) : (i +%= 1) {
            if (@as(c_int, @bitCast(@as(c_uint, contents_view.data[i]))) == @as(c_int, '.')) {
                num_of_dots +%= 1;
            }
        }
    }
    var color_arr: *Custom_Color = @as(*Custom_Color, @ptrCast(@alignCast(malloc(@sizeOf(Custom_Color) *% num_of_dots))));
    _ = &color_arr;
    var arr_s: usize = 0;
    _ = &arr_s;
    var lines: *String_View = @as(*String_View, @ptrCast(@alignCast(malloc(@sizeOf(String_View) *% num_of_dots))));
    _ = &lines;
    var lines_s: usize = 0;
    _ = &lines_s;
    var cur_size: usize = 0;
    _ = &cur_size;
    var cur: *u8 = contents_view.data;
    _ = &cur;
    {
        var i: usize = 0;
        _ = &i;
        while (i <= contents_view.len) : (i +%= 1) {
            cur_size +%= 1;
            if ((i > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, contents_view.data[i -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))]))) == @as(c_int, '.'))) {
                lines[lines_s].data = cur;
                cur += cur_size;
                lines[
                    blk: {
                        const ref = &lines_s;
                        const tmp = ref.*;
                        ref.* +%= 1;
                        break :blk tmp;
                    }
                ].len = cur_size;
                cur_size = 0;
            }
        }
    }
    {
        var i: usize = 0;
        _ = &i;
        while (i < lines_s) : (i +%= 1) {
            var num_of_commas: usize = 0;
            _ = &num_of_commas;
            {
                var j: usize = 0;
                _ = &j;
                while (j < lines[i].len) : (j +%= 1) {
                    if (@as(c_int, @bitCast(@as(c_uint, lines[i].data[j]))) == @as(c_int, ',')) {
                        num_of_commas +%= 1;
                    }
                }
            }
            var words: *String_View = @as(*String_View, @ptrCast(@alignCast(malloc((num_of_commas +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) *% @sizeOf(String_View)))));
            _ = &words;
            var words_s: usize = 0;
            _ = &words_s;
            var cur_1: *u8 = lines[i].data;
            _ = &cur_1;
            var cur_size_2: usize = 0;
            _ = &cur_size_2;
            {
                var j: usize = 0;
                _ = &j;
                while (j < lines[i].len) : (j +%= 1) {
                    cur_size_2 +%= 1;
                    if (@as(c_int, @bitCast(@as(c_uint, lines[i].data[j]))) == @as(c_int, ',')) {
                        words[words_s].data = cur_1;
                        cur_1 += cur_size_2;
                        words[
                            blk: {
                                const ref = &words_s;
                                const tmp = ref.*;
                                ref.* +%= 1;
                                break :blk tmp;
                            }
                        ].len = cur_size_2 -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
                        cur_size_2 = 0;
                    }
                }
            }
            cur_size_2 -%= 1;
            words[words_s].data = cur_1;
            cur_1 += cur_size_2;
            words[
                blk: {
                    const ref = &words_s;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ].len = cur_size_2 -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
            if (words_s < @as(usize, @bitCast(@as(c_long, @as(c_int, 4))))) {
                return Color_Arr{
                    .arr = null,
                    .arr_s = @import("std").mem.zeroes(usize),
                };
            }
            var color: Custom_Color = Custom_Color{
                .custom_slot = @as(c_uint, @bitCast(@as(c_int, 0))),
                .custom_id = 0,
                .custom_r = 0,
                .custom_g = 0,
                .custom_b = 0,
            };
            _ = &color;
            color.custom_id = @as(c_int, @bitCast(@as(c_uint, @truncate(i +% @as(usize, @bitCast(@as(c_long, @as(c_int, 8))))))));
            var cur_type: u8 = words[@as(c_uint, @intCast(@as(c_int, 0)))].data[@as(c_uint, @intCast(@as(c_int, 0)))];
            _ = &cur_type;
            color.custom_r = vw.view_to_int(words[@as(c_uint, @intCast(@as(c_int, 1)))]);
            color.custom_g = vw.view_to_int(words[@as(c_uint, @intCast(@as(c_int, 2)))]);
            color.custom_b = vw.view_to_int(words[@as(c_uint, @intCast(@as(c_int, 3)))]);
            if (@as(c_int, @bitCast(@as(c_uint, cur_type))) == @as(c_int, 'k')) {
                if (words_s > @as(usize, @bitCast(@as(c_long, @as(c_int, 4))))) {
                    keywords = @as(**u8, @ptrCast(@alignCast(malloc((@sizeOf(*u8) *% words_s) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 3))))))));
                } else {
                    keywords = @as(**u8, @ptrCast(@alignCast(&keywords_old)));
                    keywords_s = @sizeOf([25]*u8) / @sizeOf(*u8);
                }
                color.custom_slot = 4;
            } else if (@as(c_int, @bitCast(@as(c_uint, cur_type))) == @as(c_int, 't')) {
                if (words_s > @as(usize, @bitCast(@as(c_long, @as(c_int, 4))))) {
                    types = @as(**u8, @ptrCast(@alignCast(malloc((@sizeOf(*u8) *% words_s) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 3))))))));
                } else {
                    types = @as(**u8, @ptrCast(@alignCast(&types_old)));
                    types_s = @sizeOf([8]*u8) / @sizeOf(*u8);
                }
                color.custom_slot = 1;
            } else if (@as(c_int, @bitCast(@as(c_uint, cur_type))) == @as(c_int, 'w')) {
                color.custom_slot = 2;
            }
            {
                var j: usize = 4;
                _ = &j;
                while (j < words_s) : (j +%= 1) {
                    while (true) {
                        switch (@as(c_int, @bitCast(@as(c_uint, cur_type)))) {
                            @as(c_int, 107) => {
                                keywords[
                                    blk: {
                                        const ref = &keywords_s;
                                        const tmp = ref.*;
                                        ref.* +%= 1;
                                        break :blk tmp;
                                    }
                                ] = vw.view_to_cstr(vw.view_trim_left(words[j]));
                                break;
                            },
                            @as(c_int, 116) => {
                                types[
                                    blk: {
                                        const ref = &types_s;
                                        const tmp = ref.*;
                                        ref.* +%= 1;
                                        break :blk tmp;
                                    }
                                ] = vw.view_to_cstr(vw.view_trim_left(words[j]));
                                break;
                            },
                            else => break,
                        }
                        break;
                    }
                }
            }
            color_arr[
                blk: {
                    const ref = &arr_s;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ] = color;
        }
    }
    var arr: Color_Arr = Color_Arr{
        .arr = color_arr,
        .arr_s = arr_s,
    };
    _ = &arr;
    free(@as(?*anyopaque, @ptrCast(lines)));
    free(@as(?*anyopaque, @ptrCast(contents)));
    return arr;
}
pub export fn is_in_tokens_index(arg_token_arr: *Token, arg_token_s: usize, arg_index_1: usize, arg_size: *usize, arg_color: *Color_Pairs) c_int {
    var token_arr = arg_token_arr;
    _ = &token_arr;
    var token_s = arg_token_s;
    _ = &token_s;
    var index_1 = arg_index_1;
    _ = &index_1;
    var size = arg_size;
    _ = &size;
    var color = arg_color;
    _ = &color;
    {
        var i: usize = 0;
        _ = &i;
        while (i < token_s) : (i +%= 1) {
            if (token_arr[i].index == index_1) {
                size.* = token_arr[i].size;
                while (true) {
                    switch (token_arr[i].type) {
                        @as(c_uint, @bitCast(@as(c_int, 0))) => break,
                        @as(c_uint, @bitCast(@as(c_int, 1))) => {
                            color.* = @as(c_uint, @bitCast(RED_COLOR));
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 2))) => {
                            color.* = @as(c_uint, @bitCast(YELLOW_COLOR));
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 3))) => {
                            color.* = @as(c_uint, @bitCast(CYAN_COLOR));
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 4))) => {
                            color.* = @as(c_uint, @bitCast(MAGENTA_COLOR));
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 5))) => {
                            color.* = @as(c_uint, @bitCast(GREEN_COLOR));
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 6))) => {
                            color.* = @as(c_uint, @bitCast(BLUE_COLOR));
                            break;
                        },
                        else => {},
                    }
                    break;
                }
                return 1;
            }
        }
    }
    return 0;
}
pub export fn generate_word(arg_view: *String_View, arg_contents: *u8) Token {
    var view = arg_view;
    _ = &view;
    var contents = arg_contents;
    _ = &contents;
    var index_1: usize = @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(view.*.data) -% @intFromPtr(contents))), @sizeOf(u8))));
    _ = &index_1;
    var word: [128]u8 = [1]u8{
        0,
    } ++ [1]u8{0} ** 127;
    _ = &word;
    var word_s: usize = 0;
    _ = &word_s;
    while ((view.*.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (((@as(c_int, @bitCast(@as(c_uint, (blk: {
        const tmp = @as(c_int, @bitCast(@as(c_uint, view.*.data[@as(c_uint, @intCast(@as(c_int, 0)))])));
        if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISalpha)))))))) != 0) or (@as(c_int, @bitCast(@as(c_uint, view.*.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '_')))) {
        if (word_s >= @as(usize, @bitCast(@as(c_long, @as(c_int, 128))))) break;
        word[
            blk: {
                const ref = &word_s;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            }
        ] = view.*.data[@as(c_uint, @intCast(@as(c_int, 0)))];
        view.*.data += 1;
        view.*.len -%= 1;
    }
    view.*.data -= 1;
    view.*.len +%= 1;
    if (is_keyword(@as(*u8, @ptrCast(@alignCast(&word))), word_s) != 0) {
        return Token{
            .type = @as(c_uint, @bitCast(Type_Keyword)),
            .index = index_1,
            .size = word_s,
        };
    } else if (is_type(@as(*u8, @ptrCast(@alignCast(&word))), word_s) != 0) {
        return Token{
            .type = @as(c_uint, @bitCast(Type_Type)),
            .index = index_1,
            .size = word_s,
        };
    } else {
        return Token{
            .type = @as(c_uint, @bitCast(Type_Word)),
            .index = index_1,
            .size = word_s,
        };
    }
    return Token{
        .type = @as(c_uint, @bitCast(Type_None)),
        .index = @import("std").mem.zeroes(usize),
        .size = @import("std").mem.zeroes(usize),
    };
}
pub export fn generate_tokens(arg_line: *u8, arg_line_s: usize, arg_token_arr: *Token, arg_token_arr_capacity: *usize) usize {
    var line = arg_line;
    _ = &line;
    var line_s = arg_line_s;
    _ = &line_s;
    var token_arr = arg_token_arr;
    _ = &token_arr;
    var token_arr_capacity = arg_token_arr_capacity;
    _ = &token_arr_capacity;
    var token_arr_s: usize = 0;
    _ = &token_arr_s;
    var view: String_View = vw.view_create(line, line_s);
    _ = &view;
    view = vw.view_trim_left(view);
    while (view.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        if ((@as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = @as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))])));
            if (tmp >= 0) break :blk __ctype_b_loc().* + @as(usize, @intCast(tmp)) else break :blk __ctype_b_loc().* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))) & @as(c_int, @bitCast(@as(c_uint, @as(c_ushort, @bitCast(@as(c_short, @truncate(_ISalpha)))))))) != 0) {
            var token: Token = generate_word(&view, line);
            _ = &token;
            if (token_arr_s >= token_arr_capacity.*) {
                token_arr = @as(*Token, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(token_arr)), (@sizeOf(Token) *% token_arr_capacity.*) *% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 2))))))));
                token_arr_capacity.* *%= @as(usize, @bitCast(@as(c_long, @as(c_int, 2))));
            }
            if (token.type != @as(c_uint, @bitCast(Type_None))) {
                token_arr[
                    blk: {
                        const ref = &token_arr_s;
                        const tmp = ref.*;
                        ref.* +%= 1;
                        break :blk tmp;
                    }
                ] = token;
            }
        } else if (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '#')) {
            var token: Token = Token{
                .type = @as(c_uint, @bitCast(Type_Preprocessor)),
                .index = @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(view.data) -% @intFromPtr(line))), @sizeOf(u8)))),
                .size = view.len,
            };
            _ = &token;
            while ((view.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) != @as(c_int, '\n'))) {
                view.len -%= 1;
                view.data += 1;
            }
            token_arr[
                blk: {
                    const ref = &token_arr_s;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ] = token;
        } else if (((view.len >= @as(usize, @bitCast(@as(c_long, @as(c_int, 2))))) and (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '/'))) and (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 1)))]))) == @as(c_int, '/'))) {
            var token: Token = Token{
                .type = @as(c_uint, @bitCast(Type_Comment)),
                .index = @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(view.data) -% @intFromPtr(line))), @sizeOf(u8)))),
                .size = view.len,
            };
            _ = &token;
            while ((view.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) != @as(c_int, '\n'))) {
                view.len -%= 1;
                view.data += 1;
            }
            token_arr[
                blk: {
                    const ref = &token_arr_s;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ] = token;
        } else if (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '"')) {
            var token: Token = Token{
                .type = @as(c_uint, @bitCast(Type_String)),
                .index = @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(view.data) -% @intFromPtr(line))), @sizeOf(u8)))),
                .size = @import("std").mem.zeroes(usize),
            };
            _ = &token;
            var string_s: usize = 1;
            _ = &string_s;
            view.len -%= 1;
            view.data += 1;
            while ((view.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) != @as(c_int, '"'))) {
                if ((view.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) and (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\\'))) {
                    string_s +%= 1;
                    view.len -%= 1;
                    view.data += 1;
                }
                string_s +%= 1;
                view.len -%= 1;
                view.data += 1;
            }
            token.size = blk: {
                const ref = &string_s;
                ref.* +%= 1;
                break :blk ref.*;
            };
            token_arr[
                blk: {
                    const ref = &token_arr_s;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ] = token;
        } else if (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\'')) {
            var token: Token = Token{
                .type = @as(c_uint, @bitCast(Type_String)),
                .index = @as(usize, @bitCast(@divExact(@as(c_long, @bitCast(@intFromPtr(view.data) -% @intFromPtr(line))), @sizeOf(u8)))),
                .size = @import("std").mem.zeroes(usize),
            };
            _ = &token;
            var string_s: usize = 1;
            _ = &string_s;
            view.len -%= 1;
            view.data += 1;
            while ((view.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) != @as(c_int, '\''))) {
                if ((view.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) and (@as(c_int, @bitCast(@as(c_uint, view.data[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\\'))) {
                    string_s +%= 1;
                    view.len -%= 1;
                    view.data += 1;
                }
                string_s +%= 1;
                view.len -%= 1;
                view.data += 1;
            }
            token.size = blk: {
                const ref = &string_s;
                ref.* +%= 1;
                break :blk ref.*;
            };
            token_arr[
                blk: {
                    const ref = &token_arr_s;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ] = token;
        }
        if (view.len == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) break;
        view.data += 1;
        view.len -%= 1;
        view = vw.view_trim_left(view);
    }
    return token_arr_s;
}
pub export fn read_file_by_lines(arg_filename: *u8, arg_lines: ***u8, arg_lines_s: *usize) c_int {
    var filename = arg_filename;
    _ = &filename;
    var lines = arg_lines;
    _ = &lines;
    var lines_s = arg_lines_s;
    _ = &lines_s;
    var file: *FILE = fopen(filename, "r");
    _ = &file;
    if (file == @as(*FILE, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
        return 1;
    }
    _ = fseek(file, @as(c_long, @bitCast(@as(c_long, @as(c_int, 0)))), @as(c_int, 2));
    var length: usize = @as(usize, @bitCast(ftell(file)));
    _ = &length;
    _ = fseek(file, @as(c_long, @bitCast(@as(c_long, @as(c_int, 0)))), @as(c_int, 0));
    if (length == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
        _ = fclose(file);
        return 1;
    }
    var contents: *u8 = @as(*u8, @ptrCast(@alignCast(malloc(@sizeOf(u8) *% length))));
    _ = &contents;
    _ = fread(@as(?*anyopaque, @ptrCast(contents)), @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))), length, file);
    _ = fclose(file);
    var line_count: usize = 0;
    _ = &line_count;
    {
        var i: usize = 0;
        _ = &i;
        while (i < length) : (i +%= 1) {
            if (@as(c_int, @bitCast(@as(c_uint, contents[i]))) == @as(c_int, '\n')) {
                line_count +%= 1;
            }
        }
    }
    free(@as(?*anyopaque, @ptrCast(lines.*)));
    var new_lines: **u8 = @as(**u8, @ptrCast(@alignCast(malloc(@sizeOf(**u8) *% line_count))));
    _ = &new_lines;
    var current_line: [128]u8 = [1]u8{
        0,
    } ++ [1]u8{0} ** 127;
    _ = &current_line;
    var current_line_s: usize = 0;
    _ = &current_line_s;
    {
        var i: usize = 0;
        _ = &i;
        while (i < length) : (i +%= 1) {
            if (@as(c_int, @bitCast(@as(c_uint, contents[i]))) == @as(c_int, '\n')) {
                new_lines[lines_s.*] = @as(*u8, @ptrCast(@alignCast(malloc((@sizeOf(u8) *% current_line_s) +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
                _ = strncpy(new_lines[lines_s.*], @as(*u8, @ptrCast(@alignCast(&current_line))), current_line_s +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
                current_line_s = 0;
                _ = memset(@as(?*anyopaque, @ptrCast(@as(*u8, @ptrCast(@alignCast(&current_line))))), @as(c_int, 0), current_line_s);
                lines_s.* +%= @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
                continue;
            }
            current_line[
                blk: {
                    const ref = &current_line_s;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ] = contents[i];
        }
    }
    lines.* = new_lines;
    free(@as(?*anyopaque, @ptrCast(contents)));
    return 0;
}

pub var types_old: [8][*:0]const u8 = [8][*:0]const u8{
    "char",
    "double",
    "float",
    "int",
    "long",
    "short",
    "void",
    "size_t",
};
pub var keywords_old: [25][*:0]const u8 = [25][*:0]const u8{
    "auto",
    "break",
    "case",
    "const",
    "continue",
    "default",
    "do",
    "else",
    "enum",
    "extern",
    "for",
    "goto",
    "if",
    "register",
    "return",
    "signed",
    "sizeof",
    "static",
    "struct",
    "switch",
    "typedef",
    "union",
    "unsigned",
    "volatile",
    "while",
};
pub var keywords: **u8 = @import("std").mem.zeroes(**u8);
pub var keywords_s: usize = 0;
pub var types: **u8 = @import("std").mem.zeroes(**u8);
pub var types_s: usize = 0;
