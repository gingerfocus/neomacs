const root = @import("../root.zig");
const std = @import("std");
const trm = @import("thermit");

const Backend = @import("Backend.zig");

/// common function to parse xkbd events, used by both gtk and wayland
pub fn parseKey(
    key: u32,
    pressed: bool,
    mods: *trm.KeyModifiers,
) ?Backend.Event {
    var exit = true;
    switch (key) {
        65515 => mods.supr = pressed,
        65507, 65508 => mods.ctrl = pressed,
        65513, 65514 => mods.altr = pressed,
        65505, 65506 => mods.shft = pressed,
        else => exit = !pressed,
    }
    if (exit) return null;

    switch (key) {
        trm.KeySymbol.Return.toBits(),
        65293,
        => return Backend.Event{ .Key = .{
            .character = trm.KeySymbol.Return.toBits(),
            .modifiers = mods.*,
        } },
        65288 => return Backend.Event{ .Key = .{
            .character = trm.KeySymbol.Backspace.toBits(),
            .modifiers = mods.*,
        } },
        65307 => return Backend.Event{ .Key = .{
            .character = trm.KeySymbol.Esc.toBits(),
            .modifiers = mods.*,
        } },
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

        // pass through with no shift modifier
        33...126,
        => {
            const ch: u8 = @intCast(key);
            // std.debug.print("ch: {c}\n", .{ch});
            var modifiers = mods.*;
            modifiers.shft = false; // characters dont use shift

            return Backend.Event{ .Key = .{
                .character = ch,
                .modifiers = modifiers,
            } };
        },
        trm.KeySymbol.Space.toBits(),
        => return Backend.Event{ .Key = .{
            .character = @intCast(key),
            .modifiers = mods.*,
        } },
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
