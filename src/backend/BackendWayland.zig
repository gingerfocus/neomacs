const root = @import("../root.zig");
const std = root.std;
const lib = root.lib;
const mem = std.mem;
const xev = root.xev;
const trm = root.trm;

const Backend = @import("Backend.zig");

const Self = @This();
const Window = @This();

const desktop = @import("desktop.zig");
const graphi = @cImport({
    @cInclude("graphi.h");
});
const font = @cImport({
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
    @cInclude("freetype/ftmodapi.h");
    @cInclude("freetype/ftglyph.h");
});
const wl = @cImport({
    @cInclude("wayland-client-core.h");
    @cInclude("wayland-client-protocol.h");
    @cInclude("wayland-client.h");
    @cInclude("xkbcommon/xkbcommon.h");

    @cInclude("xdg-shell-protocol.h");
});

const WaylandEvent = struct {
    pressed: bool,
    ty: union(enum) {
        key: u32,
    },
};

const FrameBuffer = struct {
    width: i32,
    height: i32,
    // TODO: get 4096
    data: []align(64) u8,

    pub fn init(a: std.mem.Allocator, width: i32, height: i32) !FrameBuffer {
        const amount = @as(usize, @intCast(width * height * 4));
        // I need 4096 alligned data
        const data = try a.alignedAlloc(u8, .@"64", amount);
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

events: std.ArrayListUnmanaged(WaylandEvent) = .{},
modifiers: trm.KeyModifiers = .{},

closed: bool = false,

/// Current buffer that is submitted to render
buffer: FrameBuffer,

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
repeat: struct { rate: i32, delay: i32 } = .{ .rate = 100, .delay = 300 },

// TODO: just do it
bitmap: Bitmap,

const Bitmap = struct {
    width: u32,
    height: u32,
    buffer: []u8,
};

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

    // font.FT_Alloc_Func

    var library: font.FT_Library = undefined;
    var err = font.FT_Init_FreeType(&library);
    if (err != 0) {
        // ... an error occurred during library initialization ...
    }

    var face: font.FT_Face = undefined;
    err = font.FT_New_Face(
        library,
        "/nix/store/fmnrhnlw687farbwmfr5yq9is4z8wxa6-nerdfonts-3.2.1/share/fonts/truetype/NerdFonts/HackNerdFontMono-Regular.ttf",
        0,
        &face,
    );
    // defer font.FT_Done_Face() // mayber?

    err = font.FT_Set_Char_Size(face, // handle to face object
        0, // char_width in 1/64 of points
        16 * 64, // char_height in 1/64 of points
        300, // horizontal device resolution
        300); // vertical device resolution

    const glyph_index = font.FT_Get_Char_Index(face, 'A');

    err = font.FT_Load_Glyph(face, // handle to face object */
        glyph_index, // glyph index           */
        0); // load flags, see below */

    err = font.FT_Render_Glyph(face.*.glyph, // glyph slot  */
        font.FT_RENDER_MODE_NORMAL); // render mode */

    const bm = face.*.glyph.*.bitmap;
    const bitmap = Bitmap{
        .width = bm.width,
        .height = bm.rows,
        .buffer = try a.dupe(u8, bm.buffer[0 .. bm.width * bm.rows]),
    };

    state.* = .{
        .bitmap = bitmap,

        // .closed = false,
        //
        .registry = registry,
        .display = display,
        .buffer = FrameBuffer{ .width = 0, .height = 0, .data = &.{} },
        //
        // .surface = null,
        // .xdg_surface = null,
        // .xdg_toplevel = null,
        //
        // .xkb_state = null,
        .xkb_context = wl.xkb_context_new(wl.XKB_CONTEXT_NO_FLAGS) orelse return error.NoKeyboard,
        // .xkb_keymap = null,
        //
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

const thunk = struct {
    const FONTWIDTH = 5;
    const FONTHEIGHT = 7;
    const FONTSIZE = 4;

    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));

        const width = @as(usize, @intCast(window.width));
        const height = @as(usize, @intCast(window.height));

        // // Use graphi to render text into the window buffer.
        // // Example: draw "Hello, wind!" at position (pos.x, pos.y)
        // var text_buf: [32]u8 = undefined;
        // const text = "Hello, wind!";
        // @memcpy(text_buf[0..text.len], text);
        // text_buf[text.len] = 0;

        if (node.background) |bg| {
            const rs: c_int = @intCast(pos.row * FONTHEIGHT * FONTSIZE);
            const cs: c_int = @intCast(pos.col * FONTWIDTH * FONTSIZE);

            const rgb = bg.toRgb();
            const color: u32 = @bitCast([4]u8{ rgb[0], rgb[1], rgb[2], 0xFF });
            graphi.draw_rect(
                @ptrCast(window.buffer.data),
                width,
                height,
                cs,
                rs,
                FONTWIDTH * FONTSIZE,
                FONTHEIGHT * FONTSIZE,
                color,
            );
        }

        switch (node.content) {
            .Text => |ch| {
                const rendercolor = node.foreground orelse .Black;
                const rgb = rendercolor.toRgb();
                // std.mem.writeInt()
                const color: u32 = @bitCast([4]u8{ rgb[0], rgb[1], rgb[2], 0xFF });

                var text_buf: [2]u8 = .{ ch, 0 };
                // std.debug.print("ch: {c}\n", .{ch});

                graphi.graphi_draw_text(
                    @ptrCast(@alignCast(window.buffer.data.ptr)),
                    width,
                    height,
                    &text_buf,
                    @as(c_int, @intCast(pos.col * FONTWIDTH * FONTSIZE)),
                    @as(c_int, @intCast(pos.row * FONTHEIGHT * FONTSIZE)),
                    FONTSIZE,
                    0,
                    color, // graphi.BLACK,
                );

                for (0..window.bitmap.height) |row| {
                    @memcpy(
                        window.buffer.data[row * window.bitmap.width .. (row + 1) * window.bitmap.width],
                        window.bitmap.buffer[row * window.bitmap.width .. (row + 1) * window.bitmap.width],
                    );
                }
            },
            .Image => |_| {},
            .None => {},
        }

        return;
    }

    fn pollEvent(ptr: *anyopaque, timeout: i32) Backend.Event {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));

        if (window.closed) {
            _ = wl.wl_display_dispatch(window.display);
            return Backend.Event.End;
        }

        _ = wl.wl_display_dispatch_pending(window.display); // do client stuff
        _ = wl.wl_display_flush(window.display); // send everything to server

        if (window.events.items.len == 0) {
            const fd = wl.wl_display_get_fd(window.display);
            // std.debug.print("fd: {d}\n", .{fd});
            var fds = [1]std.posix.pollfd{std.posix.pollfd{
                .fd = fd,
                .events = std.posix.POLL.IN,
                .revents = 0,
            }};
            const count = std.posix.poll(&fds, timeout) catch unreachable;

            if (count == 0)
                return Backend.Event.Timeout;
        }

        _ = wl.wl_display_dispatch(window.display);
        // if (events < 0) return Backend.Event{ .Error = true };
        // if (events == 0) return Backend.Event.Timeout;

        while (window.events.items.len > 0) {
            const event = window.events.orderedRemove(0);

            // convert event
            switch (event.ty) {
                .key => |sym| {
                    return desktop.parseKey(sym, event.pressed, &window.modifiers) orelse continue;
                },
            }
        }
        return Backend.Event.Timeout;
    }

    fn getSize(ptr: *anyopaque) lib.Vec2 {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));

        return .{
            .row = @as(usize, @intCast(window.height)) / FONTHEIGHT / FONTSIZE / 2,
            .col = @as(usize, @intCast(window.width)) / FONTWIDTH / FONTSIZE / 2,
        };
    }

    fn deinit(ptr: *anyopaque) void {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));

        window.a.free(window.bitmap.buffer);
        window.buffer.deinit(window.a);
        window.events.deinit(window.a);

        wl.wl_display_disconnect(window.display);
        window.a.destroy(window);
    }

    fn render(ptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));

        switch (mode) {
            .begin => {
                if (window.width != window.buffer.width or window.height != window.buffer.height) {
                    root.log(@src(), .debug, "resizing buffer from {d}x{d} to {d}x{d}", .{
                        window.buffer.width,
                        window.buffer.height,
                        window.width,
                        window.height,
                    });

                    const buffer = FrameBuffer.init(
                        window.a,
                        window.width,
                        window.height,
                    ) catch {
                        std.debug.print("Failed to create swap buffer\n", .{});
                        return;
                    };

                    // const old = window.buffer;

                    // // Copy overlapping region from old buffer to new buffer
                    // const min_width: usize = @intCast(@min(old.width, window.width));
                    // const min_height: usize = @intCast(@min(old.height, window.height));

                    // // // Copy row by row to handle stride
                    // var y: i32 = 0;
                    // while (y < min_height) : (y += 1) {
                    //     const old_row = window.buffer.data[@as(usize, @intCast(y * old.width * 4))..][0 .. min_width * 4];
                    //     const new_row = buffer.data[@as(usize, @intCast(y * window.width * 4))..][0 .. min_width * 4];
                    //     @memcpy(new_row, old_row);
                    // }

                    window.buffer.deinit(window.a);
                    window.buffer = buffer;
                } else {
                    @memset(window.buffer.data, 44);
                }
            },
            .end => {
                // defaultRender(&window.buffer);

                const buffer = createBuffer(window, window.buffer) catch |err| {
                    std.debug.print("Failed to create buffer: {any}\n", .{err});
                    return;
                };
                wl.wl_surface_attach(window.surface, buffer, 0, 0);
                wl.wl_surface_damage_buffer(window.surface, 0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
                wl.wl_surface_commit(window.surface);
            },
        }
    }

    fn setCursor(ptr: *anyopaque, pos: lib.Vec2) void {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));

        graphi.draw_rect(
            @ptrCast(window.buffer.data),
            @intCast(window.buffer.width),
            @intCast(window.buffer.height),
            @intCast(pos.col * FONTWIDTH * FONTSIZE),
            @intCast(pos.row * FONTHEIGHT * FONTSIZE),
            FONTWIDTH * FONTSIZE,
            FONTHEIGHT * FONTSIZE,
            graphi.LILAC,
        );
    }
};

pub fn backend(window: *Self) Backend {
    return Backend{
        .dataptr = window,
        .vtable = &Backend.VTable{
            .draw = thunk.draw,
            .poll = thunk.pollEvent,
            .deinit = thunk.deinit,
            .render = thunk.render,
            .getSize = thunk.getSize,
            .setCursor = thunk.setCursor,
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

fn key_state_str(state: u32) []const u8 {
    return switch (state) {
        wl.WL_KEYBOARD_KEY_STATE_RELEASED => "released",
        wl.WL_KEYBOARD_KEY_STATE_PRESSED => "pressed",
        else => "unknown",
    };
}

fn wl_keyboard_key(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, serial: u32, time: u32, key: u32, pressedstate: u32) callconv(.C) void {
    const window: *Window = @alignCast(@ptrCast(data));

    _ = wl_keyboard;
    _ = serial;
    _ = time;

    // const name = mem.span(wl.wl_proxy_get_class(@ptrCast(wl_keyboard)));
    // const id = wl.wl_proxy_get_id(@ptrCast(wl_keyboard));

    const pressed = pressedstate == wl.WL_KEYBOARD_KEY_STATE_PRESSED;

    // std.debug.print(
    //     "[{:2}:{s:16}] key: serial: {}; time: {}; key: {}; state: {} ({s})\n",
    //     .{ id, name, serial, time, key + 8, pressed, key_state_str(pressedstate) },
    // );

    // var buf: [128]u8 = undefined;
    const sym: wl.xkb_keysym_t = wl.xkb_state_key_get_one_sym(window.xkb_state, key + 8);

    // _ = wl.xkb_keysym_get_name(sym, &buf, buf.len);
    // std.debug.print(SPACER ++ "sym: {s} ({}), \n", .{ buf[0..12], sym });

    // const keycode: u32 = if (pressed) key + 8 else 0;

    // _ = wl.xkb_state_key_get_utf8(window.xkb_state, keycode, &buf, buf.len);
    // escape_utf8(buf);
    // std.debug.print(SPACER ++ "utf8: '{s}'\n", .{buf[0..12]});

    window.events.append(window.a, .{
        .pressed = pressed,
        .ty = .{ .key = sym },
    }) catch {};
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
            window.repeat = .{ .rate = rate, .delay = delay };
        }
    }.repeat_info),
};

fn wlSeatCapabilities(data: ?*anyopaque, wl_seat: ?*wl.wl_seat, capabilities: u32) callconv(.C) void {
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

const wl_seat_listener = wl.wl_seat_listener{
    .capabilities = wlSeatCapabilities,
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
    // .release = wlBufferRelease,
    .release = (struct {
        fn release(data: ?*anyopaque, wl_buffer: ?*wl.wl_buffer) callconv(.C) void {
            _ = data;
            // data is already unmapped
            wl.wl_buffer_destroy(wl_buffer);
        }
    }.release),
};

fn xdg_toplevel_configure(data: ?*anyopaque, xdg_toplevel: ?*wl.xdg_toplevel, width: i32, height: i32, states: ?*wl.wl_array) callconv(.C) void {
    _ = xdg_toplevel; // autofix
    const state: *Window = @alignCast(@ptrCast(data));
    state.width = width;
    state.height = height;
    if (state.width == 0 or state.height == 0) {
        state.width = DEFAULT_WIDTH;
        state.height = DEFAULT_HEIGHT;
    }

    std.log.info("[xdg_toplevel]: configure: width: {}; height: {}", .{ width, height });
    //     int n = proxy_log(state, (struct wl_proxy *)xdg_toplevel, "configure",
    //             "width: %d; height: %d", width, height);

    const statesZ: []const u32 = blk: {
        const ptr: [*]const u32 = @alignCast(@ptrCast(states.?));
        break :blk ptr[0..states.?.size];
    };

    if (statesZ.len > 0) {
        std.debug.print(SPACER, .{});
    }
    for (statesZ) |s| {
        switch (s) {
            wl.XDG_TOPLEVEL_STATE_MAXIMIZED => {
                std.debug.print("maximized ", .{});
            },
            wl.XDG_TOPLEVEL_STATE_FULLSCREEN => {
                std.debug.print("fullscreen ", .{});
            },
            wl.XDG_TOPLEVEL_STATE_RESIZING => {
                std.debug.print("resizing ", .{});
            },
            wl.XDG_TOPLEVEL_STATE_ACTIVATED => {
                std.debug.print("activated ", .{});
            },
            wl.XDG_TOPLEVEL_STATE_TILED_LEFT => {
                std.debug.print("tiled-left ", .{});
            },
            wl.XDG_TOPLEVEL_STATE_TILED_RIGHT => {
                std.debug.print("tiled-right ", .{});
            },
            wl.XDG_TOPLEVEL_STATE_TILED_TOP => {
                std.debug.print("tiled-top ", .{});
            },
            wl.XDG_TOPLEVEL_STATE_TILED_BOTTOM => {
                std.debug.print("tiled-bottom ", .{});
            },
            else => {},
        }
    }
    if (statesZ.len > 0) {
        std.debug.print("\n", .{});
    }
}

fn xdg_toplevel_close(data: ?*anyopaque, xdg_toplevel: ?*wl.xdg_toplevel) callconv(.C) void {
    const state: *Window = @alignCast(@ptrCast(data));
    state.closed = true;
    _ = xdg_toplevel; // autofix
    // proxy_log(state, (struct wl_proxy *)xdg_toplevel, "close", "\n");
}

const xdg_toplevel_listener = wl.xdg_toplevel_listener{
    .configure = xdg_toplevel_configure,
    .close = xdg_toplevel_close,
};

const xdg_surface_listener = wl.xdg_surface_listener{
    .configure = (struct {
        fn xdg_surface_configure(data: ?*anyopaque, xdg_surface: ?*wl.xdg_surface, serial: u32) callconv(.C) void {
            const state: *Window = @alignCast(@ptrCast(data));
            _ = state;

            std.log.info("[xdg_surface]: configure serial: {}", .{serial});

            wl.xdg_surface_ack_configure(xdg_surface, serial);

            // const buffer: ?*wl.wl_buffer = create_buffer(state);
            // wl.wl_surface_attach(state.surface, buffer, 0, 0);
            // wl.wl_surface_damage_buffer(state.surface, 0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
            // wl.wl_surface_commit(state.surface);
        }
    }.xdg_surface_configure),
};

const xdg_wm_base_listener = wl.xdg_wm_base_listener{
    .ping = (struct {
        fn wm_base_ping(data: ?*anyopaque, wm_base: ?*wl.xdg_wm_base, serial: u32) callconv(.C) void {
            _ = data;
            // std.debug.print("[xdg_wm_base]: ping serial: {}\n", .{serial});
            wl.xdg_wm_base_pong(wm_base, serial);
        }
    }.wm_base_ping),
};

const wl_registry_listener = wl.wl_registry_listener{
    .global = (struct {
        fn registry_global(
            data: ?*anyopaque,
            wl_registry: ?*wl.wl_registry,
            name: u32,
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
                    handle.ptr.* = wl.wl_registry_bind(wl_registry, name, handle.interface, handle.version);
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
