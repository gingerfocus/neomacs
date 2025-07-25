const root = @import("../root.zig");
const std = root.std;
const lib = root.lib;
const mem = std.mem;
const trm = root.trm;
const desktop = lib.desktop;
const cairo = desktop.cairo;

const Backend = @import("Backend.zig");

const Self = @This();
const Window = @This();

const wl = @cImport({
    @cInclude("wayland-client-core.h");
    @cInclude("wayland-client-protocol.h");
    @cInclude("wayland-client.h");
    @cInclude("xkbcommon/xkbcommon.h");

    @cInclude("xdg-shell-protocol.h");
});

events: std.ArrayListUnmanaged(Backend.Event) = .{},
pressedkeys: std.ArrayListUnmanaged(struct {
    // true if this keypress is the first of a repeat
    start: bool,
    time: i64,
    key: u8,
}) = .{},
modifiers: trm.KeyModifiers = .{},

closed: bool = false,

/// Current buffer that is submitted to render
buffer: FrameBuffer,

cr: ?*desktop.cairo.cairo_t = null,
frame: ?*desktop.cairo.cairo_surface_t = null,

display: *wl.wl_display,
registry: *wl.wl_registry,
compositor: ?*wl.wl_compositor = null,
seat: ?*wl.wl_seat = null,
wshm: ?*wl.wl_shm = null,
wm_base: ?*wl.xdg_wm_base = null,
// data_device_manager: ?*wl.wl_data_device_manager = null,

surface: ?*wl.wl_surface = null,
xdg_surface: ?*wl.xdg_surface = null,
xdg_toplevel: ?*wl.xdg_toplevel = null,

width: i32 = 0,
height: i32 = 0,

xkb_state: ?*wl.xkb_state = null,
xkb_context: *wl.xkb_context,
xkb_keymap: ?*wl.xkb_keymap = null,

selection: ?*wl.wl_data_offer = null,
dnd: ?*wl.wl_data_offer = null,

a: std.mem.Allocator,
repeat: struct { rate: i32, delay: i32 } = .{
    .rate = 25,
    .delay = 300,
},

const DEFAULT_WIDTH = 1020;
const DEFAULT_HEIGHT = 840;

pub fn init(
    a: std.mem.Allocator,
    // loop: *xev.Loop,
) !*Window {
    const state = try a.create(Window);

    const display = wl.wl_display_connect(null) orelse {
        std.debug.print("Failed to connect to Wayland display\n", .{});
        return error.NoDisplay;
    };

    const registry = wl.wl_display_get_registry(display) orelse {
        std.debug.print("Failed to obtain Wayland registry\n", .{});
        return error.NoRegistry;
    };

    _ = wl.wl_registry_add_listener(registry, &wl_registry_listener, state);

    // const fd = wl.wl_display_get_fd(display);
    // const stream = xev.Stream.initFd(fd);
    // var c = try a.create(xev.Completion)l
    // stream.poll(loop,c, .read, void, null)

    state.* = .{
        // .bitmap = bitmap,

        // .closed = false,

        .registry = registry,
        .display = display,
        .buffer = FrameBuffer{ .width = 0, .height = 0, .data = &.{} },

        // .surface = null,
        // .xdg_surface = null,
        // .xdg_toplevel = null,

        // .xkb_state = null,
        .xkb_context = wl.xkb_context_new(wl.XKB_CONTEXT_NO_FLAGS) orelse return error.NoKeyboard,
        // .xkb_keymap = null,

        // .selection = null,
        // .dnd = null,
        .a = a,
    };

    // _ = wl.wl_display_dispatch(state.display);
    _ = wl.wl_display_roundtrip(state.display);

    // check what the compositor has given us in the first roundtrip
    const required: []const struct { name: []const u8, ptr: ?*anyopaque } = &.{
        .{ .name = "wl_compositor", .ptr = state.compositor },
        .{ .name = "wl_seat", .ptr = state.seat },
        .{ .name = "wl_shm", .ptr = state.wshm },
        .{ .name = "xdg_wm_base", .ptr = state.wm_base },
        // .{ .name = "wl_data_device_manager", .ptr = state.data_device_manager },
    };
    for (required) |require| {
        if (require.ptr == null) {
            std.debug.print("{s} is required but is not present.\n", .{require.name});
            return error.MissingModules;
        }
    }

    _ = wl.xdg_wm_base_add_listener(state.wm_base, &xdg_wm_base_listener, null);

    state.surface = wl.wl_compositor_create_surface(state.compositor); // important
    state.xdg_surface = wl.xdg_wm_base_get_xdg_surface(state.wm_base, state.surface);
    _ = wl.xdg_surface_add_listener(state.xdg_surface, &xdg_surface_listener, state); // size used here

    state.xdg_toplevel = wl.xdg_surface_get_toplevel(state.xdg_surface);
    wl.xdg_toplevel_set_title(state.xdg_toplevel, "wev");
    wl.xdg_toplevel_set_app_id(state.xdg_toplevel, "wev");
    _ = wl.xdg_toplevel_add_listener(state.xdg_toplevel, &xdg_toplevel_listener, state); // size set here

    _ = wl.wl_seat_add_listener(state.seat, &wl_seat_listener, state);

    // const data_device: ?*wl.wl_data_device = wl.wl_data_device_manager_get_data_device(state.data_device_manager, state.seat);
    // _ = wl.wl_data_device_add_listener(data_device, &wl_data_device_listener, state);

    wl.wl_surface_commit(state.surface);
    _ = wl.wl_display_roundtrip(state.display);

    return state;
}

fn deinit(ptr: *anyopaque) void {
    const window = @as(*Self, @ptrCast(@alignCast(ptr)));

    // window.a.free(window.bitmap.buffer);
    window.buffer.deinit(window.a);
    window.events.deinit(window.a);
    window.pressedkeys.deinit(window.a);

    wl.wl_display_disconnect(window.display);
    // window.* = undefined;

    window.a.destroy(window);
}

fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
    const window = @as(*Self, @ptrCast(@alignCast(ptr)));

    const ctx = window.cr orelse {
        std.debug.print("Failed to create cairo context\n", .{});
        return;
    };

    desktop.cairodraw(ctx, pos, node);
}

fn render(ptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
    const window = @as(*Self, @ptrCast(@alignCast(ptr)));

    switch (mode) {
        .begin => {
            std.debug.assert(window.frame == null);
            std.debug.assert(window.cr == null);

            const width = @as(c_int, @intCast(window.width));
            const height = @as(c_int, @intCast(window.height));

            const surface = cairo.cairo_image_surface_create(cairo.CAIRO_FORMAT_ARGB32, width, height);
            window.frame = surface;
            window.cr = cairo.cairo_create(surface);
        },
        .end => {
            const surface = window.frame.?; // must call begin first
            const data = cairo.cairo_image_surface_get_data(surface);
            const width = cairo.cairo_image_surface_get_width(surface);
            const height = cairo.cairo_image_surface_get_height(surface);
            // const stride = c.cairo_image_surface_get_stride(surface);

            // const fbuffer = FrameBuffer.init(window.a, width, height) catch return;
            // defer fbuffer.deinit(window.a);
            // @memcpy(fbuffer.data, data[0 .. @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4]); // stride=4

            const fbuffer = FrameBuffer{
                .width = width,
                .height = height,
                .data = @alignCast(data[0 .. @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4]),
            };
            const buffer = createBuffer(window, fbuffer) catch |err| {
                std.debug.print("Failed to create buffer: {any}\n", .{err});
                return;
            };
            wl.wl_surface_attach(window.surface, buffer, 0, 0);
            wl.wl_surface_damage_buffer(window.surface, 0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
            wl.wl_surface_commit(window.surface);

            if (window.cr != null) {
                cairo.cairo_destroy(window.cr);
                window.cr = null;
            }
            if (window.frame != null) {
                cairo.cairo_surface_destroy(window.frame);
                window.frame = null;
            }
        },
    }
}

fn setCursor(ptr: *anyopaque, pos: lib.Vec2, ty: Backend.VTable.CursorType) void {
    const window = @as(*Self, @ptrCast(@alignCast(ptr)));

    // TODO: set cursor line, no! that should be dont by the renderer

    const cr = window.cr orelse return;

    const x = @as(f64, @floatFromInt(pos.col)) * desktop.CHAR_WIDTH;
    const y = @as(f64, @floatFromInt(pos.row)) * desktop.CHAR_HEIGHT;

    const cursorwidth: f64 = switch (ty) {
        .SteadyBlock => desktop.CHAR_WIDTH,
        .SteadyBar => desktop.CHAR_WIDTH / 6,
        else => desktop.CHAR_WIDTH,
    };

    cairo.cairo_set_source_rgb(cr, 1.0, 1.0, 1.0); // White cursor
    cairo.cairo_rectangle(cr, x, y, cursorwidth, desktop.CHAR_HEIGHT);
    cairo.cairo_fill(cr);
}

/// Logic, add all held keys to the event list, then poll with no block. add
/// all those events to the list. If there are events then return them, else
/// poll for the timeout and try to add those events.
fn pollEvent(ptr: *anyopaque, timeout: i32) Backend.Event {
    const window = @as(*Self, @ptrCast(@alignCast(ptr)));

    if (window.closed) {
        _ = wl.wl_display_dispatch(window.display);
        return Backend.Event.End;
    }

    var events: std.ArrayList(Backend.Event) = .init(window.a);

    const now = std.time.milliTimestamp();
    for (window.pressedkeys.items) |*pressed| {
        const diff = now - pressed.time;
        if ((pressed.start and diff > window.repeat.delay) or (!pressed.start and diff > window.repeat.rate)) {
            root.log(@src(), .info, "repeat: {c}", .{pressed.key});
            pressed.start = false;
            pressed.time = now;
            events.append(Backend.Event{ .Key = trm.KeyEvent{ .character = pressed.key, .modifiers = window.modifiers } }) catch {};
        }
    }

    _ = wl.wl_display_dispatch_pending(window.display); // do client stuff
    _ = wl.wl_display_flush(window.display); // send everything to server

    // dont wait if we already have events
    const to = if (events.items.len > 0) 0 else timeout;

    const fd = wl.wl_display_get_fd(window.display);
    // std.debug.print("fd: {d}\n", .{fd});
    var fds = [1]std.posix.pollfd{
        std.posix.pollfd{
            .fd = fd,
            .events = std.posix.POLL.IN,
            .revents = 0,
        },
    };
    const count = std.posix.poll(&fds, to) catch 0;

    if (count > 0) {
        _ = wl.wl_display_dispatch(window.display);
    }

    for (window.events.items) |event| {
        events.append(event) catch {};
    }
    window.events.clearRetainingCapacity();

    if (events.items.len > 1) {
        return Backend.Event{ .Many = events };
    } else if (events.items.len == 1) {
        const ev = events.orderedRemove(0);
        events.deinit();
        return ev;
    } else {
        return Backend.Event.Timeout;
    }
}

fn getSize(dataptr: *anyopaque) lib.Vec2 {
    const window = @as(*Self, @ptrCast(@alignCast(dataptr)));

    const size: lib.Vec2 = .{
        .row = @as(usize, @intCast(window.height)) / desktop.CHAR_HEIGHT / 2,
        .col = @as(usize, @intCast(window.width)) / desktop.CHAR_WIDTH / 2,
    };
    root.log(@src(), .info, "size: {any}", .{size});
    return size;
}

pub fn backend(window: *Self) Backend {
    return Backend{
        .dataptr = window,
        .vtable = &Backend.VTable{
            .draw = draw,
            .poll = pollEvent,
            .deinit = deinit,
            .render = render,
            .getSize = getSize,
            .setCursor = setCursor,
        },
    };
}

fn createBuffer(window: *Window, frame: FrameBuffer) !*wl.wl_buffer {
    const stride = frame.width * 4;
    const size = stride * frame.height;
    const ssize = @as(usize, @intCast(size));

    const fd = try lib.shm.file(ssize);
    defer std.posix.close(fd);

    const data: []align(4096) u8 = try std.posix.mmap(null, ssize, std.posix.PROT.READ | std.posix.PROT.WRITE, .{ .TYPE = .SHARED }, fd, 0);
    defer std.posix.munmap(data);

    const pool: *wl.wl_shm_pool = wl.wl_shm_create_pool(window.wshm, fd, size) orelse return error.CreatePoolFailed;
    defer wl.wl_shm_pool_destroy(pool);
    const buffer: *wl.wl_buffer = wl.wl_shm_pool_create_buffer(pool, 0, frame.width, frame.height, stride, wl.WL_SHM_FORMAT_XRGB8888) orelse return error.CreateBufferFailed;

    // RENDER: wow so cool
    @memcpy(data, frame.data);

    if (wl.wl_buffer_add_listener(buffer, &wl_buffer_listener, null) != 0) {
        return error.AddBufferListenerFailed;
    }

    return buffer;
}

const SPACER: []const u8 = "                      ";

// static const char *keymap_format_str(uint32_t format) {
//     switch (format) {
//     case WL_KEYBOARD_KEYMAP_FORMAT_NO_KEYMAP:
//         return "none";
//     case WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1:
//         return "xkb v1";
//     default:
//         return "unknown";
//     }
// }

fn wlkeyboardmap(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, format: u32, fd: i32, size: u32) callconv(.C) void {
    _ = wl_keyboard;
    const state: *Window = @alignCast(@ptrCast(data));

    //     proxy_log(state, (struct wl_proxy *)wl_keyboard, "keymap",
    //             "format: %d (%s), size: %d\n",
    //             format, keymap_format_str(format), size);

    const map_shm = std.posix.mmap(null, size, std.posix.PROT.READ, .{ .TYPE = .SHARED }, fd, 0) catch {
        // close(fd);
        // fprintf(stderr, "Unable to mmap keymap: %s", strerror(errno));
        return;
    };

    //     if (state->opts.dump_map) {
    //         FILE *f = fopen(state->opts.dump_map, "w");
    //         fwrite(map_shm, 1, size, f);
    //         fclose(f);
    //     }

    if (format != wl.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1) {
        std.posix.munmap(map_shm);
        std.posix.close(fd);
        return;
    }

    const keymap: ?*wl.xkb_keymap = wl.xkb_keymap_new_from_string(state.xkb_context, map_shm.ptr, wl.XKB_KEYMAP_FORMAT_TEXT_V1, wl.XKB_KEYMAP_COMPILE_NO_FLAGS);

    std.posix.munmap(map_shm);
    std.posix.close(fd);

    const xkb_state: ?*wl.xkb_state = wl.xkb_state_new(keymap);

    wl.xkb_keymap_unref(state.xkb_keymap);
    wl.xkb_state_unref(state.xkb_state);
    state.xkb_keymap = keymap;
    state.xkb_state = xkb_state;
}

fn wl_keyboard_enter(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, serial: u32, surface: ?*wl.wl_surface, keys: ?*wl.wl_array) callconv(.C) void {
    _ = data; // autofix
    _ = wl_keyboard; // autofix
    _ = serial; // autofix
    _ = surface; // autofix
    _ = keys; // autofix
    //     struct Window *state = data;
    //     int n = proxy_log(state, (struct wl_proxy *)wl_keyboard, "enter",
    //             "serial: %d; surface: %d\n", serial,
    //             wl_proxy_get_id((struct wl_proxy *)surface));
    //     if (n != 0) {
    //         uint32_t *key;
    //         wl_array_for_each(key, keys) {
    //             char buf[128];
    //             xkb_keysym_t sym = xkb_state_key_get_one_sym(
    //                     state->xkb_state, *key + 8);
    //             xkb_keysym_get_name(sym, buf, sizeof(buf));
    //             printf(SPACER "sym: %-12s (%d), ", buf, sym);
    //             xkb_state_key_get_utf8(
    //                     state->xkb_state, *key + 8, buf, sizeof(buf));
    //             escape_utf8(buf);
    //             printf("utf8: '%s'\n", buf);
    //         }
    //     }
}

fn wl_keyboard_leave(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, serial: u32, surface: ?*wl.wl_surface) callconv(.C) void {
    _ = data; // autofix
    _ = wl_keyboard; // autofix
    _ = serial; // autofix
    _ = surface; // autofix
    //     struct Window *state = data;
    //     proxy_log(state, (struct wl_proxy *)wl_keyboard, "leave",
    //             "serial: %d; surface: %d\n", serial,
    //             wl_proxy_get_id((struct wl_proxy *)surface));
}

fn wl_keyboard_key(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, serial: u32, time: u32, key: u32, pressedstate: u32) callconv(.C) void {
    const window: *Window = @alignCast(@ptrCast(data));

    _ = wl_keyboard;
    _ = serial;
    _ = time;

    // const name = mem.span(wl.wl_proxy_get_class(@ptrCast(wl_keyboard)));
    // const id = wl.wl_proxy_get_id(@ptrCast(wl_keyboard));

    const pressed = switch (pressedstate) {
        wl.WL_KEYBOARD_KEY_STATE_PRESSED => true,
        wl.WL_KEYBOARD_KEY_STATE_RELEASED => false,
        else => unreachable,
    };

    // TODO: this is the only xkb function, other than the modifier state, perhaps I can make it myself
    const sym: wl.xkb_keysym_t = wl.xkb_state_key_get_one_sym(window.xkb_state, key + 8);

    if (desktop.parseKey(sym, pressed, &window.modifiers)) |ksym| {
        if (pressed) {
            // root.log(@src(), .info, "keypress down: {d}", .{ksym.character});

            // coult also use the time value
            const now = std.time.milliTimestamp();

            window.pressedkeys.append(window.a, .{
                .start = true,
                .time = now,
                .key = ksym.character,
            }) catch {};
            window.events.append(window.a, Backend.Event{ .Key = ksym }) catch {};
        } else {
            // root.log(@src(), .info, "keypress up: {d}", .{ksym.character});

            var index: ?usize = null;
            for (window.pressedkeys.items, 0..) |pressedkey, i| {

                // Fixes bug where releasing shift can cause the key to repeat
                // forever
                if (is_upper_letter(pressedkey.key, ksym.character)) {
                    index = i;
                    break;
                }
            }
            if (index) |idx| _ = window.pressedkeys.swapRemove(idx);
        }
    }
}

// HACK: this works but it would be better if there was some api for the
// physical key pressed that we can use
fn is_upper_letter(c1: u8, c2: u8) bool {
    if (c1 == 58 and c2 == 59) return true;
    if (c2 == 58 and c1 == 59) return true;

    return (std.ascii.toLower(c1) == std.ascii.toLower(c2));
}

// static void print_modifiers(struct Window *state, uint32_t mods) {
//     if (mods != 0) {
//         printf(": ");
//     }
//     for (int i = 0; i < 32; ++i) {
//         if ((mods >> i) & 1) {
//             printf("%s ", xkb_keymap_mod_get_name(state->xkb_keymap, i));
//         }
//     }
//     printf("\n");
// }

fn wl_keyboard_modifiers(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32) callconv(.C) void {
    _ = wl_keyboard; // autofix
    _ = serial; // autofix
    const state: *Window = @alignCast(@ptrCast(data));
    //     int n = proxy_log(state, (struct wl_proxy *)wl_keyboard, "modifiers",
    //             "serial: %d; group: %d\n", group);
    //     printf(SPACER "depressed: %08X", mods_depressed);
    //     print_modifiers(state, mods_depressed);
    //     printf(SPACER "latched: %08X", mods_latched);
    //     print_modifiers(state, mods_latched);
    //     printf(SPACER "locked: %08X", mods_locked);
    //     print_modifiers(state, mods_locked);
    _ = wl.xkb_state_update_mask(state.xkb_state, mods_depressed, mods_latched, mods_locked, 0, 0, group);
}
const wl_keyboard_listener = wl.wl_keyboard_listener{
    .keymap = wlkeyboardmap,
    .enter = wl_keyboard_enter,
    .leave = wl_keyboard_leave,
    .key = wl_keyboard_key,
    .modifiers = wl_keyboard_modifiers,

    // Data sent from the server about how to handle key input
    .repeat_info = (struct {
        fn repeat_info(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
            _ = wl_keyboard;

            const window: *Window = @alignCast(@ptrCast(data));
            _ = window;

            // I dont like my servers repeat rate so I use my own
            const rep = .{ .rate = rate, .delay = delay };
            root.log(@src(), .info, "server sent repeat: {any}", .{rep});
            // window.repeat = rep;
        }
    }.repeat_info),
};

const wl_seat_listener = wl.wl_seat_listener{
    .capabilities = (struct {
        fn wl_seat_capbilities(data: ?*anyopaque, wl_seat: ?*wl.wl_seat, capabilities: u32) callconv(.C) void {
            //     struct Window *state = data;
            //     int n = proxy_log(state, (struct wl_proxy *)wl_seat, "capabilities", "");
            //     if (capabilities == 0 && n != 0) {
            //         printf(" none");
            //     }

            //     if ((capabilities & WL_SEAT_CAPABILITY_POINTER)) {
            //         if (n != 0) {
            //             printf("pointer ");
            //         }
            //         struct wl_pointer *pointer = wl_seat_get_pointer(wl_seat);
            //         wl_pointer_add_listener(pointer, &wl_pointer_listener, data);
            //     }

            if (capabilities & wl.WL_SEAT_CAPABILITY_KEYBOARD != 0) {
                std.debug.print("keyboard ", .{});
                const keyboard: ?*wl.wl_keyboard = wl.wl_seat_get_keyboard(wl_seat);
                _ = wl.wl_keyboard_add_listener(keyboard, &wl_keyboard_listener, data);
            }

            //     if ((capabilities & WL_SEAT_CAPABILITY_TOUCH)) {
            //         if (n != 0) {
            //             printf("touch ");
            //         }
            //         struct wl_touch *touch = wl_seat_get_touch(wl_seat);
            //         wl_touch_add_listener(touch, &wl_touch_listener, data);
            //     }

            std.debug.print("\n", .{});
        }
    }.wl_seat_capbilities),

    .name = (struct {
        fn wl_seat_name(data: ?*anyopaque, seat: ?*wl.wl_seat, name: [*c]const u8) callconv(.C) void {
            _ = data;
            _ = seat;
            _ = name;
            //     struct Window *state = data;
            //     proxy_log(state, (struct wl_proxy *)seat, "name", "%s\n", name);
        }
    }.wl_seat_name),
};

const wl_buffer_listener = wl.wl_buffer_listener{
    .release = (struct {
        fn release(_: ?*anyopaque, wl_buffer: ?*wl.wl_buffer) callconv(.C) void {
            // data is already unmapped
            wl.wl_buffer_destroy(wl_buffer);
        }
    }.release),
};

const xdg_toplevel_listener = wl.xdg_toplevel_listener{
    .configure = (struct {
        fn xdg_toplevel_configure(data: ?*anyopaque, _: ?*wl.xdg_toplevel, width: i32, height: i32, _: ?*wl.wl_array) callconv(.C) void {
            const state: *Window = @alignCast(@ptrCast(data));
            state.width = width;
            state.height = height;
            if (state.width == 0 or state.height == 0) {
                state.width = DEFAULT_WIDTH;
                state.height = DEFAULT_HEIGHT;
            }
        }
    }.xdg_toplevel_configure),
    .close = (struct {
        fn xdg_toplevel_close(data: ?*anyopaque, _: ?*wl.xdg_toplevel) callconv(.C) void {
            const state: *Window = @alignCast(@ptrCast(data));
            state.closed = true;
            // wl.xdg_toplevel_destroy(xdg_toplevel);
        }
    }.xdg_toplevel_close),
    .configure_bounds = null,
    .wm_capabilities = null,
};

const xdg_surface_listener = wl.xdg_surface_listener{
    .configure = (struct {
        fn xdg_surface_configure(data: ?*anyopaque, xdg_surface: ?*wl.xdg_surface, serial: u32) callconv(.C) void {
            const state: *Window = @alignCast(@ptrCast(data));
            _ = state;

            std.log.info("[xdg_surface]: configure serial: {}", .{serial});

            wl.xdg_surface_ack_configure(xdg_surface, serial);

            // TODO: we can now draw after this so if might be valuable to do
            // something so the window is not blank
            // `wl_surface_commit` typa beat
        }
    }.xdg_surface_configure),
};

const xdg_wm_base_listener = wl.xdg_wm_base_listener{
    .ping = (struct {
        fn wm_base_ping(_: ?*anyopaque, wm_base: ?*wl.xdg_wm_base, serial: u32) callconv(.C) void {
            // TODO: if window is closed then dont respond
            wl.xdg_wm_base_pong(wm_base, serial);
        }
    }.wm_base_ping),
};

const wl_registry_listener = wl.wl_registry_listener{
    .global = (struct {
        fn registry_global(
            data: ?*anyopaque,
            wl_registry: ?*wl.wl_registry,
            id: u32,
            interface: [*c]const u8,
            version: u32,
        ) callconv(.C) void {
            const state: *Window = @alignCast(@ptrCast(data));

            const handles: []const struct {
                interface: *const wl.wl_interface,
                version: u32,
                ptr: *?*anyopaque,
            } = &.{
                .{ .interface = &wl.wl_compositor_interface, .version = 4, .ptr = @as(*?*anyopaque, @ptrCast(&state.compositor)) },
                .{ .interface = &wl.wl_seat_interface, .version = 6, .ptr = @as(*?*anyopaque, @ptrCast(&state.seat)) },
                .{ .interface = &wl.wl_shm_interface, .version = 1, .ptr = @as(*?*anyopaque, @ptrCast(&state.wshm)) },
                .{ .interface = &wl.xdg_wm_base_interface, .version = 2, .ptr = @as(*?*anyopaque, @ptrCast(&state.wm_base)) },
                // .{ .interface = &wl.wl_data_device_manager_interface, .version = 3, .ptr = @as(*?*anyopaque, @ptrCast(&state.data_device_manager)) },
            };

            for (handles) |handle| {
                if (std.mem.orderZ(u8, interface, handle.interface.name) == .eq) {
                    std.debug.print("connection to {s} (v{}) at verison {}\n", .{ std.mem.span(interface), version, handle.version });
                    // std.debug.assert(version >= handle.version);
                    handle.ptr.* = wl.wl_registry_bind(wl_registry, id, handle.interface, handle.version);
                }
            }

            // std.debug.print("global interface: {s}, vertsion: {}, name: {}\n", .{ std.mem.span(interface), version, name });
        }
    }.registry_global),
    .global_remove = (struct {
        fn global_remove(
            _: ?*anyopaque,
            _: ?*wl.wl_registry,
            id: u32,
        ) callconv(.C) void {
            // Who cares
            std.debug.print("Got a registry losing event for {}\n", .{id});
        }
    }.global_remove),
};

const FrameBuffer = struct {
    width: i32 = 0,
    height: i32 = 0,
    // data: []align(4096) u8 = &[_]u8{},
    data: []u8 = &[_]u8{},

    pub fn init(a: std.mem.Allocator, width: i32, height: i32) !FrameBuffer {
        const amount = @as(usize, @intCast(width * height * 4));
        // I need 4096 alligned data
        const data = try a.alignedAlloc(u8, 4096, amount);
        return FrameBuffer{
            .width = width,
            .height = height,
            .data = data,
        };
    }

    pub fn deinit(self: FrameBuffer, a: std.mem.Allocator) void {
        a.free(self.data);
    }
};
