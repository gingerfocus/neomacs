const root = @import("root.zig");
const std = root.std;
const scu = root.scu;
const trm = root.trm;
const lua = root.lua;
const km = root.km;
const keys = root.keys;
// const xev = root.xev;

const Buffer = root.Buffer;
const Args = root.Args;

const render = @import("render/root.zig");
const Component = @import("render/Component.zig");
const Backend = @import("backend/Backend.zig");

const State = @This();

a: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
backend: Backend,

ch: trm.KeyEvent = @bitCast(@as(u16, 0)),
/// TODO: move to the buffer structure
repeating: Repeating = .{},

L: *lua.State,

config: Config = .{},

resized: bool = false,

/// Also call zygot buffer sometimes
scratchbuffer: *Buffer,
buffers: std.ArrayListUnmanaged(*Buffer),
/// null selects the scratch buffer
bufferindex: ?usize,

// resized: bool = true,

components: std.AutoArrayHashMapUnmanaged(usize, Mountable) = .{},

commandbuffer: std.ArrayListUnmanaged(u8) = .{},

// TreeSitter Parsers
// tsmap: std.ArrayListUnmanaged(void) = .{},

// loop: xev.Loop,
// inputcallback: ?struct { *xev.Completion, xev.Async } = null,

pub fn init(a: std.mem.Allocator, args: Args) anyerror!State {
    const backend = try Backend.init(a, args);
    // TODO: based on the backend then create an appropriate logger to either
    // stdout or a file

    try checkfirstrun(a);
    const L = lua.init();

    var arena = std.heap.ArenaAllocator.init(a);
    const maps = try a.create(km.ModeToKeys);
    maps.* = try keys.create(a, &arena);

    // ---------

    const scratch: *Buffer = try a.create(Buffer);
    scratch.* = Buffer{
        .filename = "*scratch*",
        .hasbackingfile = false,
        .keymaps = maps,
        .id = Buffer.idgen.next(),
        .lines = .{},
        .alloc = a,
    };
    // TODO: append welcome content to scratch buffer
    // try scratch.insertCharacter(a, 't');

    var buffers = std.ArrayListUnmanaged(*Buffer){};
    for (args.files) |f| {
        const buffer = try a.create(Buffer);
        root.log(@src(), .debug, "opening file ({s})", .{f});
        buffer.* = Buffer.init(a, maps, f) catch |err| {
            root.log(@src(), .err, "File Not Found: {s}", .{f});
            a.destroy(buffer);
            return err;
        };
        try buffers.append(a, buffer);
    }

    var state = State{
        .a = a,
        .arena = arena,
        .L = L,

        .backend = backend,

        .scratchbuffer = scratch,
        .buffers = buffers,
        .bufferindex = if (args.files.len > 0) 0 else null,
    };

    try render.init(&state);

    return state;
}

pub fn deinit(state: *State) void {
    std.log.debug("deiniting state", .{});

    state.commandbuffer.deinit(state.a);

    // The scratchbuffer owns the keymaps.
    // The keymaps must be released before lua as they reference each other.
    state.scratchbuffer.keymaps.deinit(state.a);
    state.a.destroy(state.scratchbuffer.keymaps);
    state.scratchbuffer.deinit();
    state.a.destroy(state.scratchbuffer);

    for (state.buffers.items) |buffer| {
        buffer.deinit();
        state.a.destroy(buffer);
    }
    state.buffers.deinit(state.a);

    state.components.deinit(state.a);

    lua.deinit(state.L);

    std.log.debug("closing backend", .{});
    state.backend.deinit();

    // state.loop.deinit();
    state.arena.deinit();
}

// pub fn getBuffer(state: *const State) *Buffer {
//     return state.buffers.items[state.bufferindex];
// }

pub fn getCurrentBuffer(state: *State) *Buffer {
    const idx = state.bufferindex orelse return state.scratchbuffer;
    if (state.buffers.items.len == 0) return state.scratchbuffer;

    std.debug.assert(state.buffers.items.len >= 1);
    // TODO: this might be better as a runtime check
    // also it might be cool to create the buffer on demand
    std.debug.assert(idx <= state.buffers.items.len);
    return state.buffers.items[idx];
}

pub fn press(state: *State, ke: trm.KeyEvent) !void {
    // try state.loop.run(.no_wait);

    const keymap = state.getKeyMaps();
    root.log(@src(), .debug, "press (mode: {d}, key: {d})", .{ keymap.modeid._, trm.keys.bits(ke) });
    try keymap.run(state, ke);
}

// TODO: make a const and mut version
pub fn getKeyMaps(state: *State) *km.KeyMaps {
    // std.debug.print("cmd: {s}\n", .{state.commandbuffer.items});
    const buffer = state.getCurrentBuffer();
    if (buffer.curkeymap) |map| return map;

    return buffer.keymaps.get(Buffer.ModeId.Normal).?;
}

pub const Repeating = struct {
    is: bool = false,
    count: usize = 0,

    pub inline fn reset(self: *Repeating) void {
        self.is = false;
        self.count = 0;
    }

    pub inline fn take(self: *Repeating) usize {
        const count = if (self.is) self.count else 1;
        self.count = 0;
        self.is = false;
        return count;
    }
};

/// DEPRECATED: use `state.repeating.take()` instead.
pub fn takeRepeating(state: *State) usize {
    return state.repeating.take();
}

fn checkfirstrun(a: std.mem.Allocator) !void {
    const home = std.posix.getenv("HOME") orelse unreachable;
    const initFile = try std.fmt.allocPrint(a, "{s}/.config/neomacs/init.lua", .{home});
    defer a.free(initFile);

    if (std.fs.accessAbsolute(initFile, .{})) |_| {
        std.log.info("Welcome back vet!", .{});
        return;
    } else |_| {
        // welcome FNG
        // const DEFAULTCONFIG = @embedFile("config.lua");
        // const file = try std.fs.openFileAbsolute(initFile, .{ .mode = .write_only });
        // defer file.close();
        // try file.writeAll(DEFAULTCONFIG);
        return;
    }
}

// TODO: fix these and make them better
pub fn bufferNext(state: *State) void {
    if (state.buffers.items.len < 2) return;

    const idx = state.bufferindex orelse {
        if (state.buffers.items.len != 0) state.bufferindex = 0;
        return;
    };

    state.bufferindex = if (idx == state.buffers.items.len - 1) 0 else idx + 1;
}

pub fn bufferPrev(state: *State) void {
    if (state.buffers.items.len < 2) return;

    const idx = state.bufferindex orelse {
        if (state.buffers.items.len != 0) state.bufferindex = 0;
        return;
    };
    state.bufferindex = if (idx == 0) state.buffers.items.len - 1 else idx - 1;
}

const Mountable = struct {
    view: Component.View,
    comp: Component,
};

pub const Config = struct {
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
};
