//! a lot of the different backends either are xkbd or cairo based and these
//! are just shared functions for them
//!

const root = @import("../root.zig");
const std = root.std;
const trm = root.trm;

const Backend = @import("Backend.zig");

/// common function to parse xkbd events, used by both gtk and wayland
pub fn parseKey(
    key: u32,
    pressed: bool,
    mods: *trm.KeyModifiers,
) ?trm.KeyEvent {
    switch (key) {
        65515 => mods.supr = pressed,
        65507, 65508 => mods.ctrl = pressed,
        65513, 65514 => mods.altr = pressed,
        65505, 65506 => mods.shft = pressed,
        65509 => {}, // CAPS LOCK
        else => {},
    }
    // if (!pressed) return null;

    return switch (key) {
        trm.KeySymbol.Return.toBits(),
        65293,
        => .{
            .character = trm.KeySymbol.Return.toBits(),
            .modifiers = mods.*,
        },
        65288 => .{
            .character = trm.KeySymbol.Backspace.toBits(),
            .modifiers = mods.*,
        },
        65307 => .{
            .character = trm.KeySymbol.Esc.toBits(),
            .modifiers = mods.*,
        },
        65289 => .{
            .character = trm.KeySymbol.Tab.toBits(),
            .modifiers = mods.*,
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
        => blk: {
            const ch: u8 = @intCast(key);
            var modifiers = mods.*;
            modifiers.shft = false; // characters dont use shift

            break :blk .{
                .character = ch,
                .modifiers = modifiers,
            };
        },
        trm.KeySymbol.Space.toBits(),
        => .{
            .character = @intCast(key),
            .modifiers = mods.*,
        },

        // gtk.GDK_KEY_Left => trm.Key.Left,
        // gtk.GDK_KEY_Right => trm.Key.Right,
        // gtk.GDK_KEY_Up => trm.Key.Up,
        // gtk.GDK_KEY_Down => trm.Key.Down,
        // gtk.GDK_KEY_BackSpace => trm.Key.Backspace,
        // gtk.GDK_KEY_Delete => trm.Key.Delete,
        // gtk.GDK_KEY_Return => trm.Key.Enter,
        // gtk.GDK_KEY_Escape => trm.Key.Escape,
        // gtk.GDK_KEY_Tab => trm.Key.Tab,

        else => {
            std.debug.print("unknown key: {} ({})\n", .{ key, pressed });
            return null;
        },
    };
}

const lib = root.lib;

pub const cairo = @cImport({
    @cInclude("cairo.h");
});

pub const FONT_SIZE = 36;
pub const CHAR_WIDTH = FONT_SIZE / 2;
pub const CHAR_HEIGHT = FONT_SIZE;

pub fn cairodraw(cr: *cairo.cairo_t, pos: lib.Vec2, node: Backend.Node) void {
    // Convert the logical position (row, col) to pixel coordinates
    const x = @as(f64, @floatFromInt(pos.col)) * CHAR_WIDTH;
    const y = @as(f64, @floatFromInt(pos.row)) * CHAR_HEIGHT;

    switch (node.content) {
        .Text => |ch| {
            // Set background color for the character cell
            if (node.background) |bg| {
                const rbg = bg.toRgb();
                const bg_r = @as(f64, @floatFromInt(rbg[0])) / 255.0;
                const bg_g = @as(f64, @floatFromInt(rbg[1])) / 255.0;
                const bg_b = @as(f64, @floatFromInt(rbg[2])) / 255.0;
                cairo.cairo_set_source_rgb(cr, bg_r, bg_g, bg_b);
            }

            cairo.cairo_rectangle(cr, x, y, CHAR_WIDTH, CHAR_HEIGHT);
            cairo.cairo_fill(cr);

            // Set foreground color for the text
            if (node.foreground) |fg| {
                const rgb = fg.toRgb();
                const fg_r = @as(f64, @floatFromInt(rgb[0])) / 255.0;
                const fg_g = @as(f64, @floatFromInt(rgb[1])) / 255.0;
                const fg_b = @as(f64, @floatFromInt(rgb[2])) / 255.0;
                cairo.cairo_set_source_rgb(cr, fg_r, fg_g, fg_b);
            }

            // Set font and font size
            cairo.cairo_select_font_face(cr, "Monospace", cairo.CAIRO_FONT_SLANT_NORMAL, cairo.CAIRO_FONT_WEIGHT_NORMAL);
            cairo.cairo_set_font_size(cr, FONT_SIZE);

            // Position the text within the cell (adjust for font metrics if needed)
            cairo.cairo_move_to(cr, x, y + FONT_SIZE); // Y position is typically the baseline

            // Convert character to a Zig slice for cairo_show_text
            var buf = [1:0]u8{ch};
            cairo.cairo_show_text(cr, &buf);
        },
        else => {
            // Handle unsupported node types or log a warning
            std.log.warn("Unsupported Backend.Node type for rendering", .{});
        },
    }
}

// Update modifiers
// if (char & gtk.GDK_SHIFT_MASK != 0) {
//     // char &= ~@as(u32, gtk.GDK_SHIFT_MASK);
//     std.debug.print("pressed shift\n", .{});
//     self.modifiers.shft = true;
// }
// if (char & gtk.GDK_CONTROL_MASK != 0) self.modifiers.ctrl = true;
// if (char & gtk.GDK_MOD1_MASK != 0) self.modifiers.altr = true; // GDK_MOD1_MASK often corresponds to Alt
