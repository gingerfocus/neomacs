const std = @import("std");

const root = @import("../root.zig");
const Lua = root.Lua;

pub fn write(_: ?*Lua.State) callconv(.C) c_int {
    const state = root.state();

    const buffer = state.getCurrentBuffer();

    buffer.save() catch {
        // root.log(@src(), .err, "could not save buffer {s}: {any}", .{ buffer.filename, err });
        return 0;
    };

    return 0;
}

pub fn open(L: ?*Lua.State) callconv(.C) c_int {
    const state = root.state();

    root.log(@src(), .err, "opne", .{});

    const file = Lua.check(L, 1, []const u8) orelse {
        root.log(@src(), .err, "no file provided", .{});
        // TODO: make a prompt thing that requests it from the user
        return 0;
    };

    const nbuf = state.a.create(root.Buffer) catch return 0;

    // TODO: make sure its the scratch buffer
    nbuf.* = root.Buffer.init(state.a, state.keymaps, file) catch {
        state.a.destroy(nbuf);
        root.log(@src(), .err, "File Not Found: {s}", .{file});
        return 0;
    };

    state.buffers.append(state.a, nbuf) catch return 0;
    // select our new buffer
    state.bufferindex = state.buffers.items.len - 1;
    root.log(@src(), .debug, "opened file {s}", .{file});

    return 0;
}

pub fn next(_: ?*Lua.State) callconv(.C) c_int {
    root.state().bufferNext();
    return 0;
}

pub fn prev(_: ?*Lua.State) callconv(.C) c_int {
    root.state().bufferPrev();
    return 0;
}

pub fn name(L: ?*Lua.State) callconv(.C) c_int {
    const state = root.state();
    const buffer = state.getCurrentBuffer();
    Lua.push(L, buffer.filename orelse "*unnamed*");
    return 1;
}

pub fn create(_: ?*Lua.State) callconv(.C) c_int {
    @panic("not implemented");
}
