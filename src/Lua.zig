const root = @import("root.zig");
const std = root.std;

const options = @import("options");

const compiledin = options.uselua;
pub const compiled_in = compiledin;

pub const sys = if (compiledin) @import("syslua") else opaque {};
const nlua = if (compiledin) @import("nlua/root.zig") else opaque {};

const Lua = @This();

pub const InnerState = if (compiledin) sys.lua_State else anyopaque;

pub const State = if (compiledin) sys.lua_State else anyopaque;

pub const LuaRef = c_int;

enabled: bool,
state: if (compiledin) *InnerState else *anyopaque,

pub fn init(enabled: bool) Lua {
    if (!compiledin) return .{ .enabled = false, .state = undefined };
    if (!enabled) return .{ .enabled = false, .state = undefined };

    root.log(@src(), .debug, "creating lua state", .{});

    const L = sys.luaL_newstate() orelse unreachable;
    return .{ .enabled = true, .state = L };
}

pub fn setup(self: *Lua) void {
    if (!compiledin) return;
    if (!self.enabled) return;

    const L = self.state;
    sys.luaL_openlibs(L);

    if (comptime compiledin) {
        push(L, .{
            .loop = .{
                .stat = nlua.loop.stat,
            },
            .api = .{
                .quit = nlua.api.quit,
            },
            .buf = .{
                .next = nlua.buf.next,
                .prev = nlua.buf.prev,
                .edit = nlua.buf.open,
                .name = nlua.buf.name,
                .write = nlua.buf.write,
                .create = nlua.buf.create,
            },
            .opt = .{
                .__metatable = .{
                    .__index = nlua.optIndex,
                    .__newindex = nlua.optNewIndex,
                },
            },
            .keymap = .{
                .del = nlua.keymap.del,
                .set = nlua.keymap.set,
            },
            .treesitter = .{},
            .print = nlua.prettyPrint,
        });
        sys.lua_setglobal(L, "neon");

        sys.lua_pushcfunction(L, nlua.print);
        sys.lua_setglobal(L, "print");

        root.log(@src(), .debug, "running init.lua state", .{});

        if (sys.luaL_loadstring(L, SYSINIT) != 0)
            unreachable;

        if (sys.lua_pcall(L, 0, sys.LUA_MULTRET, 0) != 0) {
            var len: usize = undefined;
            const c = sys.lua_tolstring(L, -1, &len);
            root.log(@src(), .err, "could not run lua init:\n {s}", .{c[0..len]});
        }
    }
}

pub fn deinit(self: Lua) void {
    if (!compiledin) return;
    if (!self.enabled) return;

    sys.lua_close(self.state);
}

pub fn run(L: *InnerState, cmd: [:0]const u8) !void {
    if (comptime !compiledin) @compileError("Lua not compiled in");

    var iter = std.mem.splitScalar(u8, cmd, ' ');

    if (cmd[0] == '?') {
        if (sys.luaL_loadstring(L, cmd[1..]) != 0) {
            std.log.warn("[loop] unknown key or syntax \"{s}\"", .{cmd});
            return error.SyntaxError;
        }

        if (sys.lua_pcall(L, 0, 0, 0) != 0) {
            return error.CodeError;
        }
        return;
    }

    const zfunc = iter.next() orelse return;
    const func: [:0]const u8 = tmpCString(zfunc);

    sys.lua_getglobal(L, "neon");
    sys.lua_getfield(L, -1, "cmd");
    sys.lua_getfield(L, -1, func.ptr);

    const t = sys.lua_type(L, -1);

    switch (t) {
        sys.LUA_TFUNCTION => {
            var nargs: c_int = 0;
            while (iter.next()) |zarg| {
                const arg = tmpCString(zarg);
                sys.lua_pushlstring(L, arg.ptr, arg.len);
                nargs += 1;
            }
            std.log.info("nargs: {d}", .{nargs});
            const ret = sys.lua_pcall(L, nargs, 0, 0);
            if (ret != 0) {
                var len: usize = undefined;
                const str = sys.lua_tolstring(L, -1, &len);
                root.log(@src(), .err, "{s}", .{str[0..len]});
                return error.FunctionError;
            }
            return;
        },
        sys.LUA_TNIL => {
            sys.lua_pop(L, -1);
        },
        else => {
            const name = sys.lua_typename(L, sys.lua_type(L, -1));
            root.log(@src(), .err, "[loop] not a function, object type: {s}", .{std.mem.span(name)});
            return;
        },
    }

    std.log.warn("[loop] ending loop", .{});
}

var static: [256]u8 = undefined;
fn tmpCString(str: []const u8) [:0]const u8 {
    @memcpy(static[0..str.len], str);
    static[str.len] = 0;
    return static[0..str.len :0];
}

pub fn push(L: ?*InnerState, value: anytype) void {
    if (comptime !compiledin) @compileError("Lua not compiled in");

    const Value = @TypeOf(value);
    const typeInfo = @typeInfo(Value);

    switch (typeInfo) {
        .comptime_int => sys.lua_pushinteger(L, value),
        .int => |int| {
            if (int.bits <= 32) sys.lua_pushinteger(L, value) //
            else sys.lua_pushnumber(L, @floatFromInt(value));
        },
        .bool => sys.lua_pushboolean(L, @intFromBool(value)),
        .@"struct" => {
            sys.lua_newtable(L);

            inline for (typeInfo.@"struct".fields) |field| {
                const f = @field(value, field.name);

                push(L, f);

                if (comptime std.mem.eql(u8, field.name, "__metatable")) {
                    _ = sys.lua_setmetatable(L, -2);
                } else {
                    sys.lua_setfield(L, -2, field.name.ptr);
                }
            }
        },
        .@"fn" => sys.lua_pushcfunction(L, value),
        .@"enum" => {
            const name = @tagName(value);
            sys.lua_pushlstring(L, name.ptr, name.len);
        },
        .pointer => {
            if (Value == *anyopaque) {
                sys.lua_pushlightuserdata(L, value);
                return;
            }
            if (Value == []const u8) {
                sys.lua_pushlstring(L, value.ptr, value.len);
                return;
            }
            @compileError("unable to push type: " ++ @typeName(Value));
        },
        else => @compileError("unable to push type: " ++ @typeName(Value)),
    }
}

pub fn check(L: ?*InnerState, idx: c_int, comptime T: type) ?T {
    if (comptime !compiledin) @compileError("Lua not compiled in");

    const luat = sys.lua_type(L, idx);

    switch (@typeInfo(T)) {
        .void => {
            if (luat == sys.LUA_TNIL) return void{} else return null;
        },
        .bool => {
            if (!sys.lua_isboolean(L, idx)) return null;
            return sys.lua_toboolean(L, idx) != 0;
        },
        .int => {
            if (sys.lua_isnumber(L, idx) == 0) return null;
            return @intCast(sys.lua_tointeger(L, idx));
        },
        .float => {
            if (sys.lua_isnumber(L, idx) == 0) return null;
            return @floatCast(sys.lua_tonumber(L, idx));
        },
        .array => |arr| {
            var A: T = undefined;
            for (&A, 0..) |*p, i| {
                _ = sys.lua_geti(L, idx, @intCast(i + 1));
                defer sys.lua_pop(L, 1);
                p.* = check(L, -1, arr.child) orelse return null;
            }
            return A;
        },
        .pointer => |_| switch (T) {
            *anyopaque => {
                return sys.lua_topointer(L, idx);
            },
            []const u8 => {
                var len: usize = undefined;
                const ptr = sys.lua_tolstring(L, idx, &len);
                return ptr[0..len];
            },
            else => {
                const ptr = sys.lua_touserdata(L, idx);
                return @as(T, @alignCast(@ptrCast(ptr)));
            },
        },
        .optional => |N| {
            if (sys.lua_isnoneornil(L, idx)) {
                return null;
            }
            return check(L, idx, N.child);
        },
        .@"struct" => @compileError("NYI"),
        else => @compileError("unable to coerce to type: " ++ @typeName(T)),
    }
}

pub fn wrap(comptime func: fn (L: *InnerState) anyerror!c_int) sys.lua_CFunction {
    return struct {
        fn thunk(lua: ?*InnerState) callconv(.C) c_int {
            const L = lua orelse unreachable;

            return func(L) catch |err| {
                var buf: [512]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "{s}", .{@errorName(err)}) catch unreachable;
                sys.lua_pushlstring(L, msg.ptr, msg.len);
                return sys.lua_error(L);
            };
        }
    }.thunk;
}

const SYSINIT =
    \\local runtime = os.getenv("NEONRUNTIME")
    \\if not runtime then
    \\    local home = os.getenv("HOME")
    \\    runtime = home .. "/.local/share/neon"
    \\end
    \\neon.opt.runtime = runtime
    \\package.path = runtime .. "/?.lua;" .. package.path
    \\package.path = runtime .. "/?/init.lua;" .. package.path
    \\require("rt").startup()
;
