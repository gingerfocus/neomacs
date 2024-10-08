const std = @import("std");
const mem = std.mem;
const shm = @import("shm.zig");

// #define _POSIX_C_SOURCE 200809L
const wl = @cImport({
    @cInclude("wayland-client-core.h");
    @cInclude("wayland-client-protocol.h");
    @cInclude("wayland-client.h");
    @cInclude("xkbcommon/xkbcommon.h");

    @cInclude("xdg-shell-protocol.h");

    // #include <errno.h>
    // #include <getopt.h>
    // #include <limits.h>
    // #include <linux/input-event-codes.h>
    // #include <stdarg.h>
    // #include <stdbool.h>
    // #include <stdlib.h>
    // #include <stdio.h>
    // #include <string.h>
    // #include <sys/mman.h>
    // #include <unistd.h>
    // #include <xkbcommon/xkbcommon.h>
});

const wev_state = struct {
    closed: bool = false,

    display: ?*wl.wl_display = null,
    registry: ?*wl.wl_registry = null,
    compositor: ?*wl.wl_compositor = null,
    seat: ?*wl.wl_seat = null,
    shm: ?*wl.wl_shm = null,
    wm_base: ?*wl.xdg_wm_base = null,
    data_device_manager: ?*wl.wl_data_device_manager = null,

    surface: ?*wl.wl_surface = null,
    xdg_surface: ?*wl.xdg_surface = null,
    xdg_toplevel: ?*wl.xdg_toplevel = null,

    width: i32 = 0,
    height: i32 = 0,

    xkb_state: ?*wl.xkb_state = null,
    xkb_context: ?*wl.xkb_context = null,
    xkb_keymap: ?*wl.xkb_keymap = null,

    selection: ?*wl.wl_data_offer = null,
    dnd: ?*wl.wl_data_offer = null,
};

const SPACER: []const u8 = "                      ";

// static int proxy_log(struct wev_state *state,
// 		struct wl_proxy *proxy, const char *event, const char *fmt, ...) {
// 	const char *class = wl_proxy_get_class(proxy);
//
// 	if (!wl_list_empty(&state->opts.filters)) {
// 		bool found = false;
// 		struct wev_filter *filter;
// 		wl_list_for_each(filter, &state->opts.filters, link) {
// 			if (strcmp(filter->interface, class) == 0 &&
// 					(!filter->event || strcmp(filter->event, event) == 0)) {
// 				found = true;
// 			}
// 		}
// 		if (!found) {
// 			return 0;
// 		}
// 	}
// 	if (!wl_list_empty(&state->opts.inverse_filters)) {
// 		bool found = false;
// 		struct wev_filter *filter;
// 		wl_list_for_each(filter, &state->opts.inverse_filters, link) {
// 			if (strcmp(filter->interface, class) == 0 &&
// 					(!filter->event || strcmp(filter->event, event) == 0)) {
// 				found = true;
// 			}
// 		}
// 		if (found) {
// 			return 0;
// 		}
// 	}
//
// 	int n = 0;
// 	n += printf("[%02u:%16s] %s%s",
// 			wl_proxy_get_id(proxy),
// 			class, event, strcmp(fmt, "\n") != 0 ? ": " : "");
// 	va_list ap;
// 	va_start(ap, fmt);
// 	n += vprintf(fmt, ap);
// 	va_end(ap);
// 	return n;
// }

// static void escape_utf8(char *buf) {
// 	if (strcmp(buf, "\a") == 0) {
// 		strcpy(buf, "\\a");
// 	} else if (strcmp(buf, "\b") == 0) {
// 		strcpy(buf, "\\b");
// 	} else if (strcmp(buf, "\e") == 0) {
// 		strcpy(buf, "\\e");
// 	} else if (strcmp(buf, "\f") == 0) {
// 		strcpy(buf, "\\f");
// 	} else if (strcmp(buf, "\n") == 0) {
// 		strcpy(buf, "\\n");
// 	} else if (strcmp(buf, "\r") == 0) {
// 		strcpy(buf, "\\r");
// 	} else if (strcmp(buf, "\t") == 0) {
// 		strcpy(buf, "\\t");
// 	} else if (strcmp(buf, "\v") == 0) {
// 		strcpy(buf, "\\v");
// 	}
// }

// static void wl_pointer_enter(void *data, struct wl_pointer *wl_pointer,
// 		uint32_t serial, struct wl_surface *surface,
// 		wl_fixed_t surface_x, wl_fixed_t surface_y) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_pointer, "enter",
// 			"serial: %d; surface: %d, x, y: %f, %f\n",
// 			serial, wl_proxy_get_id((struct wl_proxy *)surface),
// 			wl_fixed_to_double(surface_x),
// 			wl_fixed_to_double(surface_y));
// }

// static void wl_pointer_leave(void *data, struct wl_pointer *wl_pointer,
// 		uint32_t serial, struct wl_surface *surface) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_pointer, "leave", "surface: %d\n",
// 			wl_proxy_get_id((struct wl_proxy *)surface));
// }

// static void wl_pointer_motion(void *data, struct wl_pointer *wl_pointer,
// 		uint32_t time, wl_fixed_t surface_x, wl_fixed_t surface_y) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_pointer, "motion",
// 			"time: %d; x, y: %f, %f\n", time,
// 			wl_fixed_to_double(surface_x),
// 			wl_fixed_to_double(surface_y));
// }

// static const char *pointer_button_str(uint32_t button) {
// 	switch (button) {
// 	case BTN_LEFT:
// 		return "left";
// 	case BTN_RIGHT:
// 		return "right";
// 	case BTN_MIDDLE:
// 		return "middle";
// 	case BTN_SIDE:
// 		return "side";
// 	case BTN_EXTRA:
// 		return "extra";
// 	case BTN_FORWARD:
// 		return "forward";
// 	case BTN_BACK:
// 		return "back";
// 	case BTN_TASK:
// 		return "task";
// 	default:
// 		return "unknown";
// 	}
// }

// static const char *pointer_state_str(uint32_t state) {
// 	switch (state) {
// 	case WL_POINTER_BUTTON_STATE_RELEASED:
// 		return "released";
// 	case WL_POINTER_BUTTON_STATE_PRESSED:
// 		return "pressed";
// 	default:
// 		return "unknown state";
// 	}
// }

// static void wl_pointer_button(void *data, struct wl_pointer *wl_pointer,
// 		uint32_t serial, uint32_t time, uint32_t button, uint32_t state) {
// 	struct wev_state *wev_state = data;
// 	proxy_log(wev_state, (struct wl_proxy *)wl_pointer, "button",
// 			"serial: %d; time: %d; button: %d (%s), state: %d (%s)\n",
// 			serial, time,
// 			button, pointer_button_str(button),
// 			state, pointer_state_str(state));
// }

// static const char *pointer_axis_str(uint32_t axis) {
// 	switch (axis) {
// 	case WL_POINTER_AXIS_VERTICAL_SCROLL:
// 		return "vertical";
// 	case WL_POINTER_AXIS_HORIZONTAL_SCROLL:
// 		return "horizontal";
// 	default:
// 		return "unknown";
// 	}
// }

// static void wl_pointer_axis(void *data, struct wl_pointer *wl_pointer,
// 		uint32_t time, uint32_t axis, wl_fixed_t value) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_pointer, "axis",
// 			"time: %d; axis: %d (%s), value: %f\n",
// 			time, axis, pointer_axis_str(axis), wl_fixed_to_double(value));
// }
//
// static void wl_pointer_frame(void *data, struct wl_pointer *wl_pointer) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_pointer, "frame", "\n");
// }
//
// static const char *pointer_axis_source_str(uint32_t axis_source) {
// 	switch (axis_source) {
// 	case WL_POINTER_AXIS_SOURCE_WHEEL:
// 		return "wheel";
// 	case WL_POINTER_AXIS_SOURCE_FINGER:
// 		return "finger";
// 	case WL_POINTER_AXIS_SOURCE_CONTINUOUS:
// 		return "continuous";
// 	case WL_POINTER_AXIS_SOURCE_WHEEL_TILT:
// 		return "wheel tilt";
// 	default:
// 		return "unknown";
// 	}
// }
//
// static void wl_pointer_axis_source(void *data, struct wl_pointer *wl_pointer,
// 		uint32_t axis_source) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_pointer, "axis_source",
// 			"%d (%s)\n", axis_source, pointer_axis_source_str(axis_source));
// }
//
// static void wl_pointer_axis_stop(void *data, struct wl_pointer *wl_pointer,
// 		uint32_t time, uint32_t axis) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_pointer, "axis_stop",
// 			"time: %d; axis: %d (%s)\n",
// 			time, axis, pointer_axis_str(axis));
// }
//
// static void wl_pointer_axis_discrete(void *data, struct wl_pointer *wl_pointer,
// 		uint32_t axis, int32_t discrete) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_pointer, "axis_stop",
// 			"axis: %d (%s), discrete: %d\n",
// 			axis, pointer_axis_str(axis), discrete);
// }
//
// static const struct wl_pointer_listener wl_pointer_listener = {
// 	.enter = wl_pointer_enter,
// 	.leave = wl_pointer_leave,
// 	.motion = wl_pointer_motion,
// 	.button = wl_pointer_button,
// 	.axis = wl_pointer_axis,
// 	.frame = wl_pointer_frame,
// 	.axis_source = wl_pointer_axis_source,
// 	.axis_stop = wl_pointer_axis_stop,
// 	.axis_discrete = wl_pointer_axis_discrete,
// };
//
// static const char *keymap_format_str(uint32_t format) {
// 	switch (format) {
// 	case WL_KEYBOARD_KEYMAP_FORMAT_NO_KEYMAP:
// 		return "none";
// 	case WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1:
// 		return "xkb v1";
// 	default:
// 		return "unknown";
// 	}
// }

fn wl_keyboard_keymap(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, format: u32, fd: i32, size: u32) callconv(.C) void {
    _ = wl_keyboard; // autofix
    const state: *wev_state = @alignCast(@ptrCast(data));

    // 	proxy_log(state, (struct wl_proxy *)wl_keyboard, "keymap",
    // 			"format: %d (%s), size: %d\n",
    // 			format, keymap_format_str(format), size);

    const map_shm = std.posix.mmap(null, size, std.posix.PROT.READ, .{ .TYPE = .SHARED }, fd, 0) catch {
        // close(fd);
        // fprintf(stderr, "Unable to mmap keymap: %s", strerror(errno));
        return;
    };

    // 	if (state->opts.dump_map) {
    // 		FILE *f = fopen(state->opts.dump_map, "w");
    // 		fwrite(map_shm, 1, size, f);
    // 		fclose(f);
    // 	}

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
    // 	struct wev_state *state = data;
    // 	int n = proxy_log(state, (struct wl_proxy *)wl_keyboard, "enter",
    // 			"serial: %d; surface: %d\n", serial,
    // 			wl_proxy_get_id((struct wl_proxy *)surface));
    // 	if (n != 0) {
    // 		uint32_t *key;
    // 		wl_array_for_each(key, keys) {
    // 			char buf[128];
    // 			xkb_keysym_t sym = xkb_state_key_get_one_sym(
    // 					state->xkb_state, *key + 8);
    // 			xkb_keysym_get_name(sym, buf, sizeof(buf));
    // 			printf(SPACER "sym: %-12s (%d), ", buf, sym);
    // 			xkb_state_key_get_utf8(
    // 					state->xkb_state, *key + 8, buf, sizeof(buf));
    // 			escape_utf8(buf);
    // 			printf("utf8: '%s'\n", buf);
    // 		}
    // 	}
}

fn wl_keyboard_leave(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, serial: u32, surface: ?*wl.wl_surface) callconv(.C) void {
    _ = data; // autofix
    _ = wl_keyboard; // autofix
    _ = serial; // autofix
    _ = surface; // autofix
    // 	struct wev_state *state = data;
    // 	proxy_log(state, (struct wl_proxy *)wl_keyboard, "leave",
    // 			"serial: %d; surface: %d\n", serial,
    // 			wl_proxy_get_id((struct wl_proxy *)surface));
}

fn key_state_str(state: u32) []const u8 {
    return switch (state) {
        wl.WL_KEYBOARD_KEY_STATE_RELEASED => "released",
        wl.WL_KEYBOARD_KEY_STATE_PRESSED => "pressed",
        else => "unknown",
    };
}

fn wl_keyboard_key(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, serial: u32, time: u32, key: u32, state: u32) callconv(.C) void {
    const wevstate: *wev_state = @alignCast(@ptrCast(data));
    const name = mem.span(wl.wl_proxy_get_class(@ptrCast(wl_keyboard)));
    const id = wl.wl_proxy_get_id(@ptrCast(wl_keyboard));
    std.debug.print(
        "[{:2}:{s:16}] key: serial: {}; time: {}; key: {}; state: {} ({s})\n",
        .{ id, name, serial, time, key + 8, state, key_state_str(state) },
    );

    var buf: [128]u8 = undefined;
    const sym: wl.xkb_keysym_t = wl.xkb_state_key_get_one_sym(wevstate.xkb_state, key + 8);

    const keycode: u32 = if (state == wl.WL_KEYBOARD_KEY_STATE_PRESSED) key + 8 else 0;

    _ = wl.xkb_keysym_get_name(sym, &buf, buf.len);
    std.debug.print(SPACER ++ "sym: {s} ({}), \n", .{ buf[0..12], sym });

    _ = wl.xkb_state_key_get_utf8(wevstate.xkb_state, keycode, &buf, buf.len);
    // 	escape_utf8(buf);
    // printf("utf8: '%s'\n", buf);
}

// static void print_modifiers(struct wev_state *state, uint32_t mods) {
// 	if (mods != 0) {
// 		printf(": ");
// 	}
// 	for (int i = 0; i < 32; ++i) {
// 		if ((mods >> i) & 1) {
// 			printf("%s ", xkb_keymap_mod_get_name(state->xkb_keymap, i));
// 		}
// 	}
// 	printf("\n");
// }

fn wl_keyboard_modifiers(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32) callconv(.C) void {
    _ = wl_keyboard; // autofix
    _ = serial; // autofix
    const state: *wev_state = @alignCast(@ptrCast(data));
    // 	int n = proxy_log(state, (struct wl_proxy *)wl_keyboard, "modifiers",
    // 			"serial: %d; group: %d\n", group);
    // 	printf(SPACER "depressed: %08X", mods_depressed);
    // 	print_modifiers(state, mods_depressed);
    // 	printf(SPACER "latched: %08X", mods_latched);
    // 	print_modifiers(state, mods_latched);
    // 	printf(SPACER "locked: %08X", mods_locked);
    // 	print_modifiers(state, mods_locked);
    _ = wl.xkb_state_update_mask(state.xkb_state, mods_depressed, mods_latched, mods_locked, 0, 0, group);
}

fn wl_keyboard_repeat_info(data: ?*anyopaque, wl_keyboard: ?*wl.wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
    _ = data; // autofix
    _ = wl_keyboard; // autofix
    _ = rate; // autofix
    _ = delay; // autofix
    // 	struct wev_state *state = data;
    // 	proxy_log(state, (struct wl_proxy *)wl_keyboard, "repeat_info",
    // 			"rate: %d keys/sec; delay: %d ms\n", rate, delay);
}

const wl_keyboard_listener = wl.wl_keyboard_listener{
    .keymap = wl_keyboard_keymap,
    .enter = wl_keyboard_enter,
    .leave = wl_keyboard_leave,
    .key = wl_keyboard_key,
    .modifiers = wl_keyboard_modifiers,
    .repeat_info = wl_keyboard_repeat_info,
};

// void wl_touch_down(void *data, struct wl_touch *wl_touch,
// 		uint32_t serial, uint32_t time, struct wl_surface *surface, int32_t id,
// 		wl_fixed_t x, wl_fixed_t y) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_touch, "down",
// 			"serial: %d; time: %d; surface: %d; id: %d; x, y: %f, %f\n",
// 			serial, time, wl_proxy_get_id((struct wl_proxy *)surface),
// 			id, wl_fixed_to_double(x), wl_fixed_to_double(y));
// }
//
// void wl_touch_up(void *data, struct wl_touch *wl_touch,
// 		uint32_t serial, uint32_t time, int32_t id) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_touch, "up",
// 			"serial: %d; time: %d; id: %d\n", serial, time, id);
// }
//
// void wl_touch_motion(void *data, struct wl_touch *wl_touch,
// 		uint32_t time, int32_t id, wl_fixed_t x, wl_fixed_t y) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_touch, "motion",
// 			"time: %d; id: %d; x, y: %f, %f\n",
// 			time, id, wl_fixed_to_double(x), wl_fixed_to_double(y));
// }
//
// void wl_touch_frame(void *data, struct wl_touch *wl_touch) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_touch, "frame", "\n");
// }
//
// void wl_touch_cancel(void *data, struct wl_touch *wl_touch) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_touch, "cancel", "\n");
// }
//
// void wl_touch_shape(void *data, struct wl_touch *wl_touch,
// 		int32_t id, wl_fixed_t major, wl_fixed_t minor) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_touch, "shape",
// 			"id: %d; major, minor: %f, %f\n",
// 			id, wl_fixed_to_double(major), wl_fixed_to_double(minor));
// }
//
// void wl_touch_orientation(void *data, struct wl_touch *wl_touch,
// 		int32_t id, wl_fixed_t orientation) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)wl_touch, "shape",
// 			"id: %d; orientation: %f\n",
// 			id, wl_fixed_to_double(orientation));
// }
//
// static const struct wl_touch_listener wl_touch_listener = {
// 	.down = wl_touch_down,
// 	.up = wl_touch_up,
// 	.motion = wl_touch_motion,
// 	.frame = wl_touch_frame,
// 	.cancel = wl_touch_cancel,
// 	.shape = wl_touch_shape,
// 	.orientation = wl_touch_orientation,
// };

fn wlSeatCapabilities(data: ?*anyopaque, wl_seat: ?*wl.wl_seat, capabilities: u32) callconv(.C) void {
    // 	struct wev_state *state = data;
    // 	int n = proxy_log(state, (struct wl_proxy *)wl_seat, "capabilities", "");
    // 	if (capabilities == 0 && n != 0) {
    // 		printf(" none");
    // 	}

    // 	if ((capabilities & WL_SEAT_CAPABILITY_POINTER)) {
    // 		if (n != 0) {
    // 			printf("pointer ");
    // 		}
    // 		struct wl_pointer *pointer = wl_seat_get_pointer(wl_seat);
    // 		wl_pointer_add_listener(pointer, &wl_pointer_listener, data);
    // 	}

    if (capabilities & wl.WL_SEAT_CAPABILITY_KEYBOARD != 0) {
        std.debug.print("keyboard ", .{});
        const keyboard: ?*wl.wl_keyboard = wl.wl_seat_get_keyboard(wl_seat);
        _ = wl.wl_keyboard_add_listener(keyboard, &wl_keyboard_listener, data);
    }

    // 	if ((capabilities & WL_SEAT_CAPABILITY_TOUCH)) {
    // 		if (n != 0) {
    // 			printf("touch ");
    // 		}
    // 		struct wl_touch *touch = wl_seat_get_touch(wl_seat);
    // 		wl_touch_add_listener(touch, &wl_touch_listener, data);
    // 	}

    std.debug.print("\n", .{});
}

fn wl_seat_name(data: ?*anyopaque, seat: ?*wl.wl_seat, name: [*c]const u8) callconv(.C) void {
    _ = data; // autofix
    _ = seat; // autofix
    _ = name; // autofix
    // 	struct wev_state *state = data;
    // 	proxy_log(state, (struct wl_proxy *)seat, "name", "%s\n", name);
}

const wl_seat_listener = wl.wl_seat_listener{
    .capabilities = wlSeatCapabilities,
    .name = wl_seat_name,
};

fn wl_buffer_release(data: ?*anyopaque, wl_buffer: ?*wl.wl_buffer) callconv(.C) void {
    _ = data;
    wl.wl_buffer_destroy(wl_buffer);
}
const wl_buffer_listener = wl.wl_buffer_listener{
    .release = wl_buffer_release,
};

fn create_buffer(state: *wev_state) ?*wl.wl_buffer {
    const stride = state.width * 4;
    const size = stride * state.height;
    const ssize = @as(usize, @intCast(size));

    const fd = shm.allocateShmFile(ssize) catch {
        // fprintf(stderr, "Failed to create shm pool file: %s", strerror(errno));
        return null;
    };

    const data: []align(4096) u8 = std.posix.mmap(null, ssize, std.posix.PROT.READ | std.posix.PROT.WRITE, .{ .TYPE = .SHARED }, fd, 0) catch {
        // fprintf(stderr, "shm buffer mmap failed\n");
        std.posix.close(fd);
        return null;
    };
    const ddata: []u32 = blk: {
        const ptr: [*]u32 = @ptrCast(data.ptr);
        break :blk ptr[0 .. data.len / 4];
    };

    const pool: ?*wl.wl_shm_pool = wl.wl_shm_create_pool(state.shm, fd, size);
    const buffer: ?*wl.wl_buffer = wl.wl_shm_pool_create_buffer(pool, 0, state.width, state.height, stride, wl.WL_SHM_FORMAT_XRGB8888);
    wl.wl_shm_pool_destroy(pool);
    std.posix.close(fd);

    var y: usize = 0;
    while (y < state.height) : (y += 1) {
        var x: usize = 0;
        while (x < state.width) : (x += 1) {
            if ((x + y / 8 * 8) % 16 < 8) {
                ddata[y * @as(usize, @intCast(state.width)) + x] = 0xFF666666;
            } else {
                ddata[y * @as(usize, @intCast(state.width)) + x] = 0xFFEEEEEE;
            }
        }
    }
    std.posix.munmap(data);

    _ = wl.wl_buffer_add_listener(buffer, &wl_buffer_listener, null);

    return buffer;
}

fn xdg_toplevel_configure(data: ?*anyopaque, xdg_toplevel: ?*wl.xdg_toplevel, width: i32, height: i32, states: ?*wl.wl_array) callconv(.C) void {
    _ = xdg_toplevel; // autofix
    const state: *wev_state = @alignCast(@ptrCast(data));
    state.width = width;
    state.height = height;
    if (state.width == 0 or state.height == 0) {
        state.width = 640;
        state.height = 480;
    }

    std.log.info("[xdg_toplevel]: configure: width: {}; height: {}", .{ width, height });
    // 	int n = proxy_log(state, (struct wl_proxy *)xdg_toplevel, "configure",
    // 			"width: %d; height: %d", width, height);

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
    const state: *wev_state = @alignCast(@ptrCast(data));
    state.closed = true;
    _ = xdg_toplevel; // autofix
    // proxy_log(state, (struct wl_proxy *)xdg_toplevel, "close", "\n");
}

const xdg_toplevel_listener = wl.xdg_toplevel_listener{
    .configure = xdg_toplevel_configure,
    .close = xdg_toplevel_close,
};

fn xdg_surface_configure(data: ?*anyopaque, xdg_surface: ?*wl.xdg_surface, serial: u32) callconv(.C) void {
    const state: *wev_state = @alignCast(@ptrCast(data));

    std.log.info("[xdg_surface]: configure serial: {}", .{serial});

    wl.xdg_surface_ack_configure(xdg_surface, serial);
    const buffer: ?*wl.wl_buffer = create_buffer(state);
    wl.wl_surface_attach(state.surface, buffer, 0, 0);
    wl.wl_surface_damage_buffer(state.surface, 0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
    wl.wl_surface_commit(state.surface);
}

const xdg_surface_listener = wl.xdg_surface_listener{
    .configure = xdg_surface_configure,
};

fn wm_base_ping(data: ?*anyopaque, wm_base: ?*wl.xdg_wm_base, serial: u32) callconv(.C) void {
    _ = data; // autofix
    wl.xdg_wm_base_pong(wm_base, serial);
}

const xdg_wm_base_listener = wl.xdg_wm_base_listener{
    .ping = wm_base_ping,
};

// static void wl_data_offer_offer(void *data, struct wl_data_offer *offer,
// 		const char * mime_type) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)offer, "offer",
// 			"mime_type: %s\n", mime_type);
// }

// static const char *dnd_actions_str(uint32_t state) {
// 	switch (state) {
// 	case WL_DATA_DEVICE_MANAGER_DND_ACTION_NONE:
// 		return "none";
// 	case WL_DATA_DEVICE_MANAGER_DND_ACTION_COPY:
// 		return "copy";
// 	case WL_DATA_DEVICE_MANAGER_DND_ACTION_MOVE:
// 		return "move";
// 	case WL_DATA_DEVICE_MANAGER_DND_ACTION_COPY |
// 			WL_DATA_DEVICE_MANAGER_DND_ACTION_MOVE:
// 		return "copy, move";
// 	case WL_DATA_DEVICE_MANAGER_DND_ACTION_ASK:
// 		return "ask";
// 	case WL_DATA_DEVICE_MANAGER_DND_ACTION_COPY |
// 			WL_DATA_DEVICE_MANAGER_DND_ACTION_ASK:
// 		return "copy, ask";
// 	case WL_DATA_DEVICE_MANAGER_DND_ACTION_MOVE |
// 			WL_DATA_DEVICE_MANAGER_DND_ACTION_ASK:
// 		return "move, ask";
// 	case WL_DATA_DEVICE_MANAGER_DND_ACTION_COPY |
// 			WL_DATA_DEVICE_MANAGER_DND_ACTION_MOVE |
// 			WL_DATA_DEVICE_MANAGER_DND_ACTION_ASK:
// 		return "copy, move, ask";
// 	default:
// 		return "unknown";
// 	}
// }
//
// static void wl_data_offer_source_actions(void *data,
// 		struct wl_data_offer *offer, uint32_t actions) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)offer, "source_actions",
// 			"actions: %u (%s)\n", actions, dnd_actions_str(actions));
// }
//
// static void wl_data_offer_action(void *data, struct wl_data_offer *offer,
// 		uint32_t dnd_action) {
// 	struct wev_state *state = data;
// 	proxy_log(state, (struct wl_proxy *)offer, "action",
// 			"dnd_action: %u (%s)\n", dnd_action, dnd_actions_str(dnd_action));
// }
//
// static const struct wl_data_offer_listener wl_data_offer_listener = {
// 	.offer = wl_data_offer_offer,
// 	.source_actions = wl_data_offer_source_actions,
// 	.action = wl_data_offer_action,
// };
//
fn wl_data_device_data_offer(data: ?*anyopaque, device: ?*wl.wl_data_device, id: ?*wl.wl_data_offer) callconv(.C) void {
    _ = data; // autofix
    _ = device; // autofix
    _ = id; // autofix
    // 	struct wev_state *state = data;
    // 	proxy_log(state, (struct wl_proxy *)device, "data_offer",
    // 			"id: %u\n", wl_proxy_get_id((struct wl_proxy *)id));
    //
    // 	wl_data_offer_add_listener(id, &wl_data_offer_listener, data);
}

fn wl_data_device_enter(
    data: ?*anyopaque,
    device: ?*wl.wl_data_device,
    serial: u32,
    surface: ?*wl.wl_surface,
    x: wl.wl_fixed_t,
    y: wl.wl_fixed_t,
    id: ?*wl.wl_data_offer,
) callconv(.C) void {
    _ = device; // autofix
    _ = surface; // autofix
    _ = x; // autofix
    _ = y; // autofix
    const state: *wev_state = @alignCast(@ptrCast(data));
    // 	proxy_log(state, (struct wl_proxy *)device, "enter",
    // 	"serial: %d; surface: %d; x, y: %f, %f; id: %u\n", serial,
    // 	wl_proxy_get_id((struct wl_proxy *)surface),
    // 	wl_fixed_to_double(x), wl_fixed_to_double(y),
    // 	wl_proxy_get_id((struct wl_proxy *)id));

    state.dnd = id;
    wl.wl_data_offer_set_actions(id, wl.WL_DATA_DEVICE_MANAGER_DND_ACTION_COPY |
        wl.WL_DATA_DEVICE_MANAGER_DND_ACTION_MOVE |
        wl.WL_DATA_DEVICE_MANAGER_DND_ACTION_ASK, wl.WL_DATA_DEVICE_MANAGER_DND_ACTION_COPY);

    // Static accept just so we have something.
    wl.wl_data_offer_accept(id, serial, "text/plain");
}

fn wl_data_device_leave(data: ?*anyopaque, device: ?*wl.wl_data_device) callconv(.C) void {
    _ = device; // autofix
    const state: *wev_state = @alignCast(@ptrCast(data));
    // proxy_log(state, (struct wl_proxy *)device, "leave", "\n");

    // Might have already been destroyed during a drop event.
    if (state.dnd != null) {
        wl.wl_data_offer_destroy(state.dnd);
        state.dnd = null;
    }
}

fn wl_data_device_motion(data: ?*anyopaque, device: ?*wl.wl_data_device, serial: u32, x: wl.wl_fixed_t, y: wl.wl_fixed_t) callconv(.C) void {
    _ = data; // autofix
    _ = device; // autofix
    _ = serial; // autofix
    _ = x; // autofix
    _ = y; // autofix
    // 	struct wev_state *state = data;
    // 	proxy_log(state, (struct wl_proxy *)device, "motion",
    // 			"serial: %d; x, y: %f, %f\n", serial, wl_fixed_to_double(x),
    // 			wl_fixed_to_double(y));
}

fn wl_data_device_drop(data: ?*anyopaque, device: ?*wl.wl_data_device) callconv(.C) void {
    _ = device; // autofix
    const state: *wev_state = @alignCast(@ptrCast(data));
    // proxy_log(state, (struct wl_proxy *)device, "drop", "\n");

    // We don't actually want the data, so cancel the drop.
    wl.wl_data_offer_destroy(state.dnd);
    state.dnd = null;
}

fn wl_data_device_selection(data: ?*anyopaque, device: ?*wl.wl_data_device, id: ?*wl.wl_data_offer) callconv(.C) void {
    _ = device; // autofix
    const state: *wev_state = @alignCast(@ptrCast(data));
    // 	if (id == NULL) {
    // 		proxy_log(state, (struct wl_proxy *)device, "selection",
    // 				"(cleared)\n");
    // 	}
    // 	else {
    // 		proxy_log(state, (struct wl_proxy *)device, "selection", "id: %u\n",
    // 				wl_proxy_get_id((struct wl_proxy *)id));
    // 	}

    if (state.selection != null) {
        wl.wl_data_offer_destroy(state.selection);
    }
    state.selection = id; // May be NULL.
}

const wl_data_device_listener = wl.wl_data_device_listener{
    .data_offer = wl_data_device_data_offer,
    .enter = wl_data_device_enter,
    .leave = wl_data_device_leave,
    .motion = wl_data_device_motion,
    .drop = wl_data_device_drop,
    .selection = wl_data_device_selection,
};

fn registry_global(
    data: ?*anyopaque,
    wl_registry: ?*wl.wl_registry,
    name: u32,
    interface: [*c]const u8,
    version: u32,
) callconv(.C) void {
    const state: *wev_state = @alignCast(@ptrCast(data));

    const handles: []const struct {
        interface: *const wl.wl_interface,
        version: u32,
        ptr: *?*anyopaque,
    } = &.{
        .{ .interface = &wl.wl_compositor_interface, .version = 4, .ptr = @as(*?*anyopaque, @ptrCast(&state.compositor)) },
        .{ .interface = &wl.wl_seat_interface, .version = 6, .ptr = @as(*?*anyopaque, @ptrCast(&state.seat)) },
        .{ .interface = &wl.wl_shm_interface, .version = 1, .ptr = @as(*?*anyopaque, @ptrCast(&state.shm)) },
        .{ .interface = &wl.xdg_wm_base_interface, .version = 2, .ptr = @as(*?*anyopaque, @ptrCast(&state.wm_base)) },
        .{ .interface = &wl.wl_data_device_manager_interface, .version = 3, .ptr = @as(*?*anyopaque, @ptrCast(&state.data_device_manager)) },
    };

    // 	char *xdg_current_desktop = getenv("XDG_CURRENT_DESKTOP");

    // 	/* Mutter currently implements wl_seat version 5, not 6 */
    // 	if (xdg_current_desktop && !strcmp(xdg_current_desktop, "GNOME"))
    // 		handles[1].version = 5;

    for (handles) |handle| {
        if (std.mem.orderZ(u8, interface, handle.interface.name) == .eq) {
            // std.debug.print("connection to {s} (v{}) at verison {}\n", .{ std.mem.span(interface), version, handle.version });
            // std.debug.assert(version >= handle.version);
            handle.ptr.* = wl.wl_registry_bind(wl_registry, name, handle.interface, handle.version);
        }
    }

    if (false) {
        std.debug.print("global interface: {s}, vertsion: {}, name: {}\n", .{ std.mem.span(interface), version, name });
    }
}

fn registry_global_remove(
    _: ?*anyopaque,
    _: ?*wl.wl_registry,
    _: u32,
) callconv(.C) void {
    // Who cares
    // std.debug.print("Got a registry losing event for {}\n", .{id});
}

const wl_registry_listener = wl.wl_registry_listener{
    .global = registry_global,
    .global_remove = registry_global_remove,
};

pub fn main() u8 {
    var state: wev_state = .{};
    state.xkb_context = wl.xkb_context_new(wl.XKB_CONTEXT_NO_FLAGS);
    state.display = wl.wl_display_connect(null) orelse {
        std.debug.print("Failed to connect to Wayland display\n", .{});
        return 1;
    };
    defer wl.wl_display_disconnect(state.display);

    state.registry = wl.wl_display_get_registry(state.display) orelse {
        std.debug.print("Failed to obtain Wayland registry\n", .{});
        return 1;
    };
    _ = wl.wl_registry_add_listener(state.registry, &wl_registry_listener, &state);

    // _ = wl.wl_display_dispatch(display);
    _ = wl.wl_display_roundtrip(state.display);

    const required: []const struct { name: []const u8, ptr: ?*anyopaque } = &.{
        .{ .name = "wl_compositor", .ptr = state.compositor },
        .{ .name = "wl_seat", .ptr = state.seat },
        .{ .name = "wl_shm", .ptr = state.shm },
        .{ .name = "xdg_wm_base", .ptr = state.wm_base },
        .{ .name = "wl_data_device_manager", .ptr = state.data_device_manager },
    };
    for (required) |require| {
        if (require.ptr == null) {
            std.debug.print("{s} is required but is not present.\n", .{require.name});
            return 1;
        }
    }

    _ = wl.xdg_wm_base_add_listener(state.wm_base, &xdg_wm_base_listener, null);

    state.surface = wl.wl_compositor_create_surface(state.compositor); // important
    state.xdg_surface = wl.xdg_wm_base_get_xdg_surface(state.wm_base, state.surface);
    _ = wl.xdg_surface_add_listener(state.xdg_surface, &xdg_surface_listener, &state); // size used here

    state.xdg_toplevel = wl.xdg_surface_get_toplevel(state.xdg_surface);
    wl.xdg_toplevel_set_title(state.xdg_toplevel, "wev");
    wl.xdg_toplevel_set_app_id(state.xdg_toplevel, "wev");
    _ = wl.xdg_toplevel_add_listener(state.xdg_toplevel, &xdg_toplevel_listener, &state); // size set here

    _ = wl.wl_seat_add_listener(state.seat, &wl_seat_listener, &state);

    const data_device: ?*wl.wl_data_device = wl.wl_data_device_manager_get_data_device(state.data_device_manager, state.seat);
    _ = wl.wl_data_device_add_listener(data_device, &wl_data_device_listener, &state);

    wl.wl_surface_commit(state.surface);
    _ = wl.wl_display_roundtrip(state.display);

    while (wl.wl_display_dispatch(state.display) != -1) {
        // This space deliberately left blank
        if (state.closed) break;

        // wl.wl_surface_attach(state.surface, buffer, 0, 0);
        wl.wl_surface_damage_buffer(state.surface, 0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
        wl.wl_surface_commit(state.surface);
    }

    return 0;
}

const State = opaque {};

const Backend = struct {
    data: *anyopaque,
    /// Waits for the next event from the backend, if an event ocurrs then run
    /// the event callback.
    pollFn: fn (*anyopaque) void,
    /// Uses the state to render the screen
    renderFn: fn (*anyopaque, *State) void,
    /// Checks weather the backend is requesting to close
    runFn: fn (*anyopaque) bool,
};

const WaylandBacked = struct {};
