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

L: *lua.State,

config: Config = .{},

resized: bool = false,

/// Also call zygot buffer sometimes
/// TODO: i think i can go back to removing this
scratchbuffer: *Buffer,
buffers: std.ArrayListUnmanaged(*Buffer),
/// null selects the scratch buffer
bufferindex: ?usize,

global_keymap: *km.Keymap,

// resized: bool = true,

components: std.AutoArrayHashMapUnmanaged(usize, Mountable) = .{},

commandbuffer: std.ArrayListUnmanaged(u8) = .{},

autocommands: Autocommands,

// TreeSitter Parsers
// tsmap: std.ArrayListUnmanaged(void) = .{},

// loop: xev.Loop,
// inputcallback: ?struct { *xev.Completion, xev.Async } = null,

pub const Autocommands = std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(km.KeyFunction));

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
        .autocommands = .{},
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

    for (state.autocommands.values()) |list| for (list.items) |*kf| kf.deinit(state.L, state.a);
    state.autocommands.deinit(state.a);

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

pub fn triggerAutocommands(state: *State, name: []const u8) !void {
    if (state.autocommands.get(name)) |list| {
        for (list.items) |*kf| try kf.run(state);
    }
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

pub fn press(state: *State, key: trm.KeyEvent) !void {
    const ke = trm.keys.bits(key);

    const buffer = state.getCurrentBuffer();
    const oldstate = buffer.input_state;
    var newstate = oldstate;
    newstate.append(ke) catch {
        root.log(@src(), .err, "Failed to append key event to input state", .{});
        buffer.input_state.len = 0;
        return;
    };

    const BlockState = enum {
        binding,
        fallback,
        targeter,
        end,
        none,
    };

    var foundmatch: bool = false;

    const thunk = struct {
        fn itermaps(argstate: *State, maps: *km.Keymap.StorageList, nextstate: *const km.KeySequence, foundprefix: *bool) !bool {
            const keysitems = maps.items(.keys);
            for (keysitems, 0..) |k, i| {

                // can't possibly match
                if (!k.mode.eql(nextstate.mode)) continue;

                // it cant be an exact match and we already know that a prefix match exists
                if (k.len != nextstate.len and foundprefix.*) continue;
                // could be the one...
                if (k.len == nextstate.len) {
                    if (std.mem.eql(u16, k.keys[0..k.len], nextstate.keys[0..k.len])) {
                        const func = maps.items(.func)[i];
                        try func.run(argstate);
                        return true;
                    }
                }
                // aw dangit
                if (nextstate.len < k.len) {
                    if (std.mem.eql(u16, k.keys[0..nextstate.len], nextstate.keys[0..nextstate.len])) {
                        root.log(@src(), .debug, "{any} matches {any}", .{ nextstate.keys[0..nextstate.len], k.keys[0..k.len] });
                        foundprefix.* = true;
                        continue;
                    }
                }
            }

            return false;
        }
    };

    // zig bug: error targets tag token
    blkrun: switch (BlockState.binding) {
        .binding => if (try thunk.itermaps(state, &buffer.local_keymap.bindings, &newstate, &foundmatch)) {
            continue :blkrun BlockState.targeter;
        } else if (try thunk.itermaps(state, &state.global_keymap.bindings, &newstate, &foundmatch)) {
            continue :blkrun BlockState.targeter;
        } else {
            continue :blkrun BlockState.fallback;
        },
        // yes need to check prefixes as modes like r have no keymaps and
        // only a fallback
        .fallback => if (try thunk.itermaps(state, &buffer.local_keymap.fallbacks, &oldstate, &foundmatch)) {
            continue :blkrun BlockState.targeter;
        } else if (try thunk.itermaps(state, &state.global_keymap.fallbacks, &oldstate, &foundmatch)) {
            continue :blkrun BlockState.targeter;
        } else if (foundmatch) {
            // we could still find something
            continue :blkrun BlockState.none;
        } else {
            continue :blkrun BlockState.end;
        },
        .targeter => {
            if (buffer.target == null) continue :blkrun BlockState.end;

            // TODO: find the best match for the targeter
            // if e->a has a targeter and the sequence is e->a->b then it should match that one

            var bestlen: ?usize = null;
            var bestkey: ?km.KeyFunction = null;

            const gkeyslice = state.global_keymap.targeters.items(.keys);
            for (gkeyslice, 0..) |keyseq, i| {
                // too long
                if (keyseq.len > oldstate.len) continue;

                if (bestlen) |len| if (len > keyseq.len) continue;

                if (keyseq.mode.eql(oldstate.mode)) {
                    if (std.mem.eql(u16, keyseq.keys[0..keyseq.len], oldstate.keys[0..keyseq.len])) {
                        bestlen = keyseq.len;
                        bestkey = state.global_keymap.targeters.items(.func)[i];

                        // cant be better
                        if (keyseq.len == oldstate.len) break;
                    }
                }
            }

            const bkeyslice = buffer.local_keymap.targeters.items(.keys);
            for (bkeyslice, 0..) |keyseq, i| {
                // too long
                if (keyseq.len > oldstate.len) continue;

                if (bestlen) |len| if (len > keyseq.len) continue;

                if (keyseq.mode.eql(oldstate.mode)) {
                    if (std.mem.eql(u16, keyseq.keys[0..keyseq.len], oldstate.keys[0..keyseq.len])) {
                        bestlen = keyseq.len;
                        bestkey = buffer.local_keymap.targeters.items(.func)[i];

                        // cant be better
                        if (keyseq.len == oldstate.len) break;
                    }
                }
            }

            if (bestkey) |tkf| {
                // root.log(@src(), .debug, "found targeter {any}", .{tkf});
                try tkf.run(state);
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

/// DEPRECATED: use `state.takeRepeating()` instead.
pub fn takeRepeating(state: *State) usize {
    const buffer = state.getCurrentBuffer();
    return buffer.repeating.take();
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
    scrolloff: usize = 8,

    runtime: []const u8 = "",

    // syntax: c_int = 1,
    // indent: c_int = 0,
    // undo_size: c_int = 16,
    // lang: []const u8 = "",
    // background_color: c_int = -1,
};
