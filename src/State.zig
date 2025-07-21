const root = @import("root.zig");
const std = root.std;
const scu = root.scu;
const trm = root.trm;
const lua = root.lua;
const km = root.km;
const keys = root.keys;

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

global_keymap: *km.Keymap,

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

    if (backend.stdout) {
        const logFile = std.fs.cwd().createFile("neomacs.log", .{}) catch null;
        scu.log.file = logFile;

        root.log(@src(), .info, "using stdout backend", .{});
    }

    const keysmap = try a.create(km.Keymap);
    keysmap.* = km.Keymap{
        .targeters = .{},
        .bindings = .{},
        .fallbacks = .{},
        .alloc = a,
    };

    // ---------

    const scratch: *Buffer = try a.create(Buffer);
    scratch.* = Buffer.init(a, keysmap, "*scratch*") catch |err| {
        root.log(@src(), .err, "Could not create scratch buffer", .{});
        return err;
    };

    var buffers = std.ArrayListUnmanaged(*Buffer){};
    for (args.files) |f| {
        const buffer = try a.create(Buffer);
        root.log(@src(), .debug, "opening file ({s})", .{f});
        buffer.* = Buffer.init(a, keysmap, f) catch |err| {
            root.log(@src(), .err, "File Not Found: {s}", .{f});
            a.destroy(buffer);
            return err;
        };
        try buffers.append(a, buffer);
    }

    return State{
        .a = a,
        .arena = std.heap.ArenaAllocator.init(a),
        .L = lua.init(),

        .backend = backend,

        .scratchbuffer = scratch,
        .buffers = buffers,
        .bufferindex = if (args.files.len > 0) 0 else null,
        .global_keymap = keysmap,
    };
}

pub fn setup(state: *State) !void {
    lua.setup(state.L);
    try keys.init(state.a, state.global_keymap);
    try render.init(state);
}

pub fn deinit(state: *State) void {
    std.log.debug("deiniting state", .{});

    state.commandbuffer.deinit(state.a);

    state.scratchbuffer.deinit();
    state.a.destroy(state.scratchbuffer);

    for (state.buffers.items) |buffer| {
        buffer.deinit();
        state.a.destroy(buffer);
    }
    state.buffers.deinit(state.a);

    state.global_keymap.deinit();
    state.a.destroy(state.global_keymap);

    state.components.deinit(state.a);

    lua.deinit(state.L);

    std.log.debug("closing backend", .{});
    state.backend.deinit();

    // state.loop.deinit();
    state.arena.deinit();
}

pub fn getCurrentBuffer(state: *State) *Buffer {
    const idx = state.bufferindex orelse return state.scratchbuffer;
    if (state.buffers.items.len == 0) return state.scratchbuffer;

    std.debug.assert(state.buffers.items.len >= 1);
    // TODO: this might be better as a runtime check
    // also it might be cool to create the buffer on demand
    std.debug.assert(idx <= state.buffers.items.len);
    return state.buffers.items[idx];
}

pub fn press(state: *State, key: trm.KeyEvent) !void {
    const ke = trm.keys.bits(key);

    const buffer = state.getCurrentBuffer();
    const oldstate = buffer.input_state;
    var newstate = oldstate;
    // TODO: catch this error
    newstate.append(ke) catch {
        root.log(@src(), .err, "Failed to append key event to input state", .{});
        buffer.input_state.len = 0;
        return;
    };
    std.log.info("newstate: {any}", .{newstate.keys[0..newstate.len]});
    std.log.info("oldstate: {any}", .{oldstate.keys[0..oldstate.len]});

    const BlockState = enum {
        local_binding,
        global_binding,
        local_fallback,
        global_fallback,
        targeter,
        end,
        none,
    };

    var foundmatch: bool = false;

    // if (true) {
    //     var biter = buffer.local_keymap.bindings.iterator();
    //     while (biter.next()) |entry| {
    //         std.log.info("local: {any}", .{entry.key_ptr.keys[0..entry.key_ptr.len]});
    //     }
    //     var giter = buffer.global_keymap.bindings.iterator();
    //     while (giter.next()) |entry| {
    //         std.log.info("mode: {}, global: {any}", .{ entry.key_ptr.mode._, entry.key_ptr.keys[0..entry.key_ptr.len] });
    //     }
    // }

    // zig bug: error targets tag token
    blkrun: switch (BlockState.local_binding) {
        .local_binding => {
            var iter = buffer.local_keymap.bindings.iterator();
            while (iter.next()) |entry| {
                const k = entry.key_ptr;

                // can't possibly match
                if (!k.mode.eql(newstate.mode)) continue;

                // it cant be an exact match and we already know that a prefix match exists
                if (k.len != newstate.len and foundmatch) continue;
                // could be the one...
                if (k.len == newstate.len) {
                    if (std.mem.eql(u16, k.keys[0..k.len], newstate.keys[0..k.len])) {
                        try entry.value_ptr.run(state);
                        continue :blkrun BlockState.targeter;
                    }
                }
                // aw dangit
                if (newstate.len < k.len) {
                    if (std.mem.eql(u16, k.keys[0..newstate.len], newstate.keys[0..newstate.len])) {
                        foundmatch = true;
                        continue;
                    }
                }
            }

            // root.log(@src(), .debug, "no match local found for ({any})", .{newstate.keys[0..newstate.len]});
            continue :blkrun BlockState.global_binding;
        },
        .global_binding => {
            // same code as the local one ^^
            //
            var iter = state.global_keymap.bindings.iterator();
            while (iter.next()) |entry| {
                const k = entry.key_ptr;

                // can't possibly match
                if (!k.mode.eql(newstate.mode)) continue;

                // it cant be an exact match and we already know that a prefix match exists
                if (k.len != newstate.len and foundmatch) continue;
                // could be the one...
                if (k.len == newstate.len) {
                    if (std.mem.eql(u16, k.keys[0..k.len], newstate.keys[0..k.len])) {
                        try entry.value_ptr.run(state);
                        std.log.info("running local binding: {any}", .{entry.value_ptr.function});
                        continue :blkrun BlockState.targeter;
                    }
                }

                // aw dangit
                if (newstate.len < k.len) {
                    if (std.mem.eql(u16, k.keys[0..newstate.len], newstate.keys[0..newstate.len])) {
                        std.log.info("{any} matches {any}", .{ newstate.keys[0..newstate.len], k.keys[0..k.len] });
                        foundmatch = true;
                        continue;
                    }
                }
            }

            continue :blkrun BlockState.local_fallback;
        },
        .local_fallback => {
            // no need to check prefixes
            if (buffer.local_keymap.fallbacks.get(oldstate)) |*kf| {
                try kf.run(state);
                continue :blkrun BlockState.targeter;
            } else {
                continue :blkrun BlockState.global_fallback;
            }
        },
        .global_fallback => {
            if (state.global_keymap.fallbacks.get(oldstate)) |*kf| {
                try kf.run(state);
                continue :blkrun BlockState.targeter;
            } else {
                // we could still find something
                if (foundmatch) continue :blkrun BlockState.none;

                continue :blkrun BlockState.end;
            }
        },
        .targeter => {
            std.log.info("running targeter", .{});

            const bkeyslice = buffer.local_keymap.targeters.items(.keys);
            for (bkeyslice, 0..) |keyseq, i| {
                if (keyseq.eql(oldstate)) {
                    const tkf = buffer.local_keymap.targeters.items(.func)[i];
                    std.log.info("running local targeter", .{});
                    try tkf.run(state);
                    continue :blkrun BlockState.end;
                }
            }

            const gkeyslice = state.global_keymap.targeters.items(.keys);
            for (gkeyslice, 0..) |keyseq, i| {
                if (keyseq.eql(oldstate)) {
                    const tkf = state.global_keymap.targeters.items(.func)[i];
                    std.log.info("running global targeter", .{});
                    try tkf.run(state);
                    continue :blkrun BlockState.end;
                }
            }

            continue :blkrun BlockState.end;
        },
        .end => {
            buffer.input_state.len = 0;
            break :blkrun;
        },
        .none => {
            // if nothing matches, then keep the sequence going
            buffer.input_state = newstate;
            break :blkrun;
        },
    }
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
