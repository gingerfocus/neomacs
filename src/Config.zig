// const std = @import("std");
// const root = @import("root");
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

// lock: std.Thread.Mutex = .{},

// pub fn set(L: ?*lua.State) callconv(.C) c_int {
//     const field = lua.check(L, 1, []const u8) orelse return 0;
//
//     // lua.sys.lua_getglobal(L, "neomacs");
//     // lua.sys.lua_getfield(L, -1, "opt");
//
//     // std.DynLib;
//     std.log.debug("setting '{s}'", .{field});
//
//     inline for (@typeInfo(@This()).Struct.fields) |flag| {
//         if (mem.eql(u8, flag.name, field)) {
//             @field(root.state().config, flag.name) = lua.check(L, 2, flag.type) orelse return 0;
//             break;
//         }
//     }
//     return 0;
//
//     // lua.sys.lua_pushboolean(L, @as(c_int, @intFromBool(value)));
//     // lua.sys.lua_pushinteger(L, @as(c_int, @intCast(value)));
//
//     // lua.sys.lua_setfield(L, -2, field.ptr);
// }

// pub fn get(L: *lua.State) Config {
//     var self = Config{};
//
//     lua.sys.lua_getglobal(L, "neomacs");
//     lua.sys.lua_getfield(L, -1, "opt");
//
//     const ti = @typeInfo(Config);
//     inline for (ti.Struct.fields) |field| {
//         const feildPtr: *field.type = &@field(self, field.name);
//
//         // root.log(@src(), .debug, "found feild ({s})", .{field.name});
//
//         lua.sys.lua_getfield(L, -1, field.name);
//         switch (@typeInfo(field.type)) {
//             .Bool => {
//                 if (lua.sys.lua_isboolean(L, -1)) {
//                     const val = lua.sys.lua_toboolean(L, -1);
//                     // std.log.debug("get {s}={}", .{ field.name, val != 0 });
//
//                     const dataPtr = @as(*bool, @ptrCast(@as(*anyopaque, @ptrCast(feildPtr))));
//                     dataPtr.* = val != 0;
//                 }
//             },
//             .Int => {
//                 if (lua.sys.lua_isnumber(L, -1) != 0) {
//                     const floatVal = lua.sys.lua_tonumber(L, -1);
//                     const val: field.type = @intFromFloat(floatVal);
//
//                     // std.log.debug("get {s}={}", .{ field.name, val });
//                     const dataPtr = @as(*field.type, @alignCast(@ptrCast(@as(*anyopaque, @ptrCast(feildPtr)))));
//                     dataPtr.* = val;
//                 }
//                 // root.log(@src(), .debug, "{s} is an int", .{field.name});
//                 // // if (luajitsys.lua_isnumber(L, VAL_INDEX) != 0) return 0;
//                 // const val = luajitsys.lua_tonumber(L, VAL_INDEX); // val
//                 // const v = @as(field.type, @intCast(@as(usize, @intFromFloat(val))));
//                 //
//                 // root.log(@src(), .debug, "setting {s}={}", .{ field.name, v });
//                 //
//                 // const ptr = @as(*field.type, @alignCast(@ptrCast(@as(*anyopaque, @ptrCast(feildPtr)))));
//                 // ptr.* = v;
//             },
//             // Int: Int,
//             // Float: Float,
//             else => unreachable,
//         }
//
//         lua.sys.lua_pop(L, 1);
//
//         // Type: void,
//         // Void: void,
//         // NoReturn: void,
//         // Pointer: Pointer,
//         // Array: Array,
//         // Struct: Struct,
//         // ComptimeFloat: void,
//         // ComptimeInt: void,
//         // Undefined: void,
//         // Null: void,
//         // Optional: Optional,
//         // ErrorUnion: ErrorUnion,
//         // ErrorSet: ErrorSet,
//         // Enum: Enum,
//         // Union: Union,
//         // Fn: Fn,
//         // Opaque: Opaque,
//         // Frame: Frame,
//         // AnyFrame: AnyFrame,
//         // Vector: Vector,
//         // EnumLiteral: void,
//     }
//     return self;
// }
