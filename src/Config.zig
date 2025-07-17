const root = @import("root");
// const std = @import("std");
// const lua = @import("lua.zig");
// const State = @import("State.zig");

const Config = @This();

QUIT: bool = false,

relativenumber: bool = false,
autoindent: bool = true,
scrolloff: u16 = 8,

runtime: []const u8 = "",

// syntax: c_int = 1,
// indent: c_int = 0,
// undo_size: c_int = 16,
// lang: []const u8 = "",
// background_color: c_int = -1,

