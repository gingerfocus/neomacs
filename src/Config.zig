const std = @import("std");
const root = @import("root");

const luajitsys = root.luajitsys;
const lua = @import("lua.zig");

const Config = @This();

/// If true then exit the program, ussually dont need to lock for this as
/// if we are exiting then a race condition is not that important
QUIT: bool = false,

relativenumber: bool = false,
autoindent: bool = true,

scrolloff: u16 = 8,

// syntax: c_int = 1,
// indent: c_int = 0,
// undo_size: c_int = 16,
// lang: []const u8 = "",

// background_color: c_int = -1,
// leaders: [4]u8,
// .leaders = .{ ' ', 'r', 'd', 'y' },
// key_maps: Maps,

// Used by lua call backs to lock the config state before changing it
// luaLock: std.Thread.Mutex = .{},

// __metatable: @TypeOf(.{
//     .__index = nluaOptIndex,
//     .__newindex = nluaOptNewIndex,
// }) = .{},

pub fn set(L: ?*lua.LuaState, field: []const u8, value: anytype) void {
    luajitsys.lua_getglobal(L, "neomacs");
    luajitsys.lua_getfield(L, -1, "opt");

    std.log.debug("set {s}={}", .{ field, value });

    switch (@typeInfo(@TypeOf(value))) {
        .Bool => {
            luajitsys.lua_pushboolean(L, @as(c_int, @intFromBool(value)));
        },
        .Int => {
            luajitsys.lua_pushinteger(L, @as(c_int, @intCast(value)));
        },
        else => unreachable,
    }
    luajitsys.lua_setfield(L, -2, field.ptr);
}

pub fn get(L: *lua.LuaState) Config {
    var self = Config{};

    luajitsys.lua_getglobal(L, "neomacs");
    luajitsys.lua_getfield(L, -1, "opt");

    const ti = @typeInfo(Config);
    inline for (ti.Struct.fields) |field| {
        const feildPtr = &@field(self, field.name);

        // root.log(@src(), .debug, "found feild ({s})", .{field.name});

        luajitsys.lua_getfield(L, -1, field.name);
        switch (@typeInfo(field.type)) {
            .Bool => {
                if (luajitsys.lua_isboolean(L, -1)) {
                    const val = luajitsys.lua_toboolean(L, -1);
                    // std.log.debug("get {s}={}", .{ field.name, val != 0 });

                    const dataPtr = @as(*bool, @ptrCast(@as(*anyopaque, @ptrCast(feildPtr))));
                    dataPtr.* = val != 0;
                }
            },
            .Int => {
                if (luajitsys.lua_isnumber(L, -1) != 0) {
                    const floatVal = luajitsys.lua_tonumber(L, -1);
                    const val: field.type = @intFromFloat(floatVal);

                    // std.log.debug("get {s}={}", .{ field.name, val });
                    const dataPtr = @as(*field.type, @alignCast(@ptrCast(@as(*anyopaque, @ptrCast(feildPtr)))));
                    dataPtr.* = val;
                }
                // root.log(@src(), .debug, "{s} is an int", .{field.name});
                // // if (luajitsys.lua_isnumber(L, VAL_INDEX) != 0) return 0;
                // const val = luajitsys.lua_tonumber(L, VAL_INDEX); // val
                // const v = @as(field.type, @intCast(@as(usize, @intFromFloat(val))));
                //
                // root.log(@src(), .debug, "setting {s}={}", .{ field.name, v });
                //
                // const ptr = @as(*field.type, @alignCast(@ptrCast(@as(*anyopaque, @ptrCast(feildPtr)))));
                // ptr.* = v;
            },
            // Int: Int,
            // Float: Float,
            else => unreachable,
        }

        luajitsys.lua_pop(L, 1);

        // Type: void,
        // Void: void,
        // NoReturn: void,
        // Pointer: Pointer,
        // Array: Array,
        // Struct: Struct,
        // ComptimeFloat: void,
        // ComptimeInt: void,
        // Undefined: void,
        // Null: void,
        // Optional: Optional,
        // ErrorUnion: ErrorUnion,
        // ErrorSet: ErrorSet,
        // Enum: Enum,
        // Union: Union,
        // Fn: Fn,
        // Opaque: Opaque,
        // Frame: Frame,
        // AnyFrame: AnyFrame,
        // Vector: Vector,
        // EnumLiteral: void,
    }
    return self;
}

// fn nluaOptIndex(L: ?*lua.LuaState) callconv(.C) c_int {
//     // const TABLE_INDEX = 1;
//     const KEY_INDEX = 2; // key
//     const VAL_INDEX = 3; // val
//
//     var key_l: usize = undefined;
//     const key = luajitsys.lua_tolstring(L, KEY_INDEX, &key_l);
//
//     root.log(@src(), .debug, "trying to set ({s})", .{key[0..key_l]});
//
//     // if (std.mem.eql(u8, "QUIT", key[0..key_l])) {
//     //     if (!luajitsys.lua_isboolean(L, VAL_INDEX)) return 0;
//     //     const val = luajitsys.lua_toboolean(L, VAL_INDEX);
//     //     root.state.config.QUIT = val != 0;
//     //     root.log(@src(), .debug, "set QUIT to {}", .{val != 0});
//     // }
//     //
//     // if (std.mem.eql(u8, "QUIT", key[0..key_l])) {
//     //     if (!luajitsys.lua_isboolean(L, VAL_INDEX)) return 0;
//     //     const val = luajitsys.lua_toboolean(L, VAL_INDEX);
//     //     root.state.config.QUIT = val != 0;
//     //     root.log(@src(), .debug, "set QUIT to {}", .{val != 0});
//     // }
//
//     const ti = @typeInfo(Config);
//     inline for (ti.Struct.fields) |field| {
//         if (std.mem.eql(u8, field.name, key[0..key_l])) {
//             root.log(@src(), .debug, "found feild ({s})", .{field.name});
//             const feildPtr = &@field(root.state.config, field.name);
//             // Type: void,
//             // Void: void,
//             // NoReturn: void,
//             // Pointer: Pointer,
//             // Array: Array,
//             // Struct: Struct,
//             // ComptimeFloat: void,
//             // ComptimeInt: void,
//             // Undefined: void,
//             // Null: void,
//             // Optional: Optional,
//             // ErrorUnion: ErrorUnion,
//             // ErrorSet: ErrorSet,
//             // Enum: Enum,
//             // Union: Union,
//             // Fn: Fn,
//             // Opaque: Opaque,
//             // Frame: Frame,
//             // AnyFrame: AnyFrame,
//             // Vector: Vector,
//             // EnumLiteral: void,
//
//             switch (@typeInfo(field.type)) {
//                 .Bool => {
//                     // if (!luajitsys.lua_isboolean(L, VAL_INDEX)) return 0;
//                     // const val = luajitsys.lua_toboolean(L, VAL_INDEX);
//                     //
//                     // root.log(@src(), .debug, "setting {s}={}", .{ field.name, val != 0 });
//
//                     const data = @as(*bool, @ptrCast(@as(*anyopaque, @ptrCast(feildPtr)))).*;
//                     luajitsys.lua_pushboolean(L, @intFromBool(data));
//                     // ptr.* = val != 0;
//                 },
//                 .Int => {
//                     root.log(@src(), .debug, "{s} is an int", .{field.name});
//                     // if (luajitsys.lua_isnumber(L, VAL_INDEX) != 0) return 0;
//                     const val = luajitsys.lua_tonumber(L, VAL_INDEX); // val
//                     const v = @as(field.type, @intCast(@as(usize, @intFromFloat(val))));
//
//                     root.log(@src(), .debug, "setting {s}={}", .{ field.name, v });
//
//                     const ptr = @as(*field.type, @alignCast(@ptrCast(@as(*anyopaque, @ptrCast(feildPtr)))));
//                     ptr.* = v;
//                 },
//                 // Int: Int,
//                 // Float: Float,
//                 else => unreachable,
//             }
//             break;
//         }
//     }
//     return 0;
// }
