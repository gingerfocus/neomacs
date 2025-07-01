const root = @import("root");
const std = @import("std");
const trm = @import("thermit");

const Backend = @import("Backend.zig");

/// common function to parse xkbd events, used by both gtk and wayland
pub fn parseKey(
    key: u32,
    pressed: bool,
    mods: *trm.KeyModifiers,
) ?Backend.Event {
    switch (key) {
        65507, 65508 => {
            mods.ctrl = pressed;
            root.log(@src(), .info, "ctrl: ", .{});
        },
        // 65515 => window.modifiers.supr = event.pressed,
        65513, 65514 => mods.altr = pressed,
        65505, 65506 => {
            mods.shft = pressed;
        },
        65293 => {
            // ENTER
        },
        65289 => {
            // TAB
        },
        65509 => {
            // CAPS
        },
        // 65361 - arrow left
        // 65362 - arrow up
        // 65364 - arrow down
        // 65363 - arrow right

        // 65288 - delete

        // 65470 - F1
        // 65471 - F2
        // ...

        // 269025074

        49...122 => {
            if (!pressed) return null;

            const ch: u8 = @intCast(key);
            std.debug.print("ch: {c}\n", .{ch});
            var modifiers = mods.*;
            modifiers.shft = false; // characters dont use shift

            return Backend.Event{ .Key = .{
                .character = ch,
                .modifiers = modifiers,
            } };
        },
        32 => {
            if (!pressed) return null;

            return Backend.Event{ .Key = .{
                .character = trm.KeySymbol.Space.toBits(),
                .modifiers = mods.*,
            } };
        },
        else => {
            std.debug.print("unknown key: {} ({})\n", .{ key, pressed });
        },
    }

    return null;
}

// switch (event.ty) {
//     .key => |keyval| {
//         std.debug.print("events: {d}\n", .{keyval});
//         const unicode = gtk.gdk_keyval_to_unicode(keyval);
//         if (unicode < 128) {
//             std.debug.print("has events: {d}\n", .{@as(u8, @intCast(unicode))});
//         } else {
//             std.debug.print("other char", .{});
//         }
//
//         if (unicode != 0) { // Check for a valid Unicode character
//             return Backend.Event{ .Key = .{
//                 .character = @intCast(unicode),
//                 .modifiers = window.modifiers,
//             } };
//         } else {
//             // Handle special keys (e.g., arrow keys, function keys)
//             // You'll need a mapping from GDK keyvals to your trm.Key enum
//             const special_key = switch (keyval) {
//                 // gtk.GDK_KEY_Left => trm.Key.Left,
//                 // gtk.GDK_KEY_Right => trm.Key.Right,
//                 // gtk.GDK_KEY_Up => trm.Key.Up,
//                 // gtk.GDK_KEY_Down => trm.Key.Down,
//                 // gtk.GDK_KEY_BackSpace => trm.Key.Backspace,
//                 // gtk.GDK_KEY_Delete => trm.Key.Delete,
//                 // gtk.GDK_KEY_Return => trm.Key.Enter,
//                 // gtk.GDK_KEY_Escape => trm.Key.Escape,
//                 // gtk.GDK_KEY_Tab => trm.Key.Tab,
//                 // Add more mappings as needed
//                 else => null,
//             };
//
//             if (special_key) |key| {
//                 return Backend.Event{ .Key = .{
//                     .key = key,
//                     .modifiers = window.modifiers,
//                 } };
//             } else {
//                 std.log.debug("Unhandled special key: {any}", .{keyval});
//             }
//         }
//     },
// }
//
// Update modifiers
// if (char & gtk.GDK_SHIFT_MASK != 0) {
//     // char &= ~@as(u32, gtk.GDK_SHIFT_MASK);
//     std.debug.print("pressed shift\n", .{});
//     self.modifiers.shft = true;
// }
// if (char & gtk.GDK_CONTROL_MASK != 0) self.modifiers.ctrl = true;
// if (char & gtk.GDK_MOD1_MASK != 0) self.modifiers.altr = true; // GDK_MOD1_MASK often corresponds to Alt

