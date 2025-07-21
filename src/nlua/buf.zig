const std = @import("std");

const root = @import("../root.zig");
const lua = root.lua;

pub fn write(_: ?*lua.State) callconv(.C) c_int {
    const state = root.state();

    const buffer = state.getCurrentBuffer();
    if (!buffer.hasbackingfile) return 0;

    buffer.save() catch |err| {
        root.log(@src(), .err, "could not save buffer {s}: {any}", .{ buffer.filename, err });
        return 0;
    };

    return 0;
}

pub fn open(L: ?*lua.State) callconv(.C) c_int {
    const state = root.state();

    const file = lua.check(L, 1, []const u8) orelse {
        // TODO: make a prompt thing that requests it from the user
        return 0;
    };

    const nbuf = state.a.create(root.Buffer) catch return 0;

    // TODO: make sure its the scratch buffer
    nbuf.* = root.Buffer.init(state.a, state.global_keymap, file) catch {
        state.a.destroy(nbuf);
        root.log(@src(), .err, "File Not Found: {s}", .{file});
        return 0;
    };

    state.buffers.append(state.a, nbuf) catch return 0;
    // select our new buffer
    state.bufferindex = state.buffers.items.len - 1;

    return 0;
}

pub fn next(_: ?*lua.State) callconv(.C) c_int {
    root.state().bufferNext();
    return 0;
}

pub fn prev(_: ?*lua.State) callconv(.C) c_int {
    root.state().bufferPrev();
    return 0;
}

pub fn name(L: ?*lua.State) callconv(.C) c_int {
    const state = root.state();
    const buffer = state.getCurrentBuffer();
    lua.push(L, buffer.filename);
    return 1;
}

pub fn create(_: ?*lua.State) callconv(.C) c_int {
    @panic("not implemented");
}
