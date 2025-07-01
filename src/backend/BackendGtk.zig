const std = @import("std");
const root = @import("root");
const lib = root.lib;
const trm = root.trm;

const BackendGtk = @This();
const Backend = @import("Backend.zig");

const desktop = @import("desktop.zig");

const gtk = struct {
    usingnamespace @cImport({
        @cInclude("gtk/gtk.h");
        @cInclude("gdk/gdk.h");
        @cInclude("gdk/gdkkeysyms.h");
        @cInclude("cairo/cairo.h"); // Make sure cairo is included for cairo functions
    });

    // shim for c.g_signal_connect as translate-c is broken for this macro
    fn gSignalConnect(instance: gtk.gpointer, detailed_signal: [*c]const u8, c_handler: gtk.GCallback, data: gtk.gpointer) void {
        _ = gtk.g_signal_connect_data(@ptrCast(instance), detailed_signal, c_handler, data, null, @as(gtk.GConnectFlags, 0));
    }
};

events: std.ArrayListUnmanaged(Backend.Event) = .{},
modifiers: trm.KeyModifiers = .{},

closed: bool = false,

width: i32 = 0,
height: i32 = 0,

a: std.mem.Allocator,

mainwin: *gtk.GtkWidget,
drawarea: *gtk.GtkWidget,
cr: ?*gtk.cairo_t = null ,

const FONT_SIZE: f64 = 16.0; // Example font size
const CHAR_WIDTH: f64 = 8.0; // Example character width (for monospaced font)
const CHAR_HEIGHT: f64 = 16.0; // Example character height

pub fn init(a: std.mem.Allocator) !*BackendGtk {
    const self = try a.create(BackendGtk);

    if (gtk.gtk_init_check(null, null) == gtk.FALSE) {
        return error.GtkInitFailed;
    }

    const mainwin = gtk.gtk_window_new(gtk.GTK_WINDOW_TOPLEVEL);
    const drawarea = gtk.gtk_drawing_area_new();

    gtk.gtk_container_add(@ptrCast(mainwin), drawarea);

    self.* = .{
        .a = a,
        .mainwin = mainwin,
        .drawarea = drawarea,
    };

    gtk.gSignalConnect(drawarea, "draw", @ptrCast(&eventDraw), self);
    gtk.gSignalConnect(drawarea, "configure-event", @ptrCast(&eventConfigure), self);
    gtk.gSignalConnect(mainwin, "key-press-event", @ptrCast(&eventKey), self);
    gtk.gSignalConnect(mainwin, "destroy", @ptrCast(&eventDestroy), self);

    gtk.gtk_widget_show_all(mainwin);

    return self;
}

fn eventConfigure(widget: *gtk.GtkWidget, event: *gtk.GdkEventConfigure, self: *BackendGtk) callconv(.C) gtk.gboolean {
    _ = event;
    self.width = gtk.gtk_widget_get_allocated_width(widget);
    self.height = gtk.gtk_widget_get_allocated_height(widget);
    return gtk.FALSE;
}

fn eventDraw(widget: *gtk.GtkWidget, cr: *gtk.cairo_t, self: *BackendGtk) callconv(.C) gtk.gboolean {
    _ = widget;
    self.cr = cr;

    // Clear the drawing area with the background color
    gtk.cairo_set_source_rgb(cr, 0.18, 0.18, 0.18); // #282828
    gtk.cairo_paint(cr);

    // The actual rendering will happen when the Backend calls thunk.draw for each node.
    // This draw_event just prepares the cairo context.

    // const time: f64 = @floatFromInt(@mod(@divTrunc(std.time.milliTimestamp(), 10), 255));
    // const hue = time / 255.0;
    // gtk.cairo_set_source_rgb(cr, hue, hue, hue);
    // gtk.cairo_rectangle(cr, 0, 0, 50, 50);
    // gtk.cairo_fill(cr);

    // TODO: either A store the render graph and write it in this function or 
    // B store the return pointer and jump out of this function. then when
    // rendering is finished retore the return address and then finish here
    //
    // OR C the best option hust call the render graph function
    const state = root.state();
    const render = @import("../render/root.zig");
    render.draw(state) catch {};

    // remove drawing capabilities
    self.cr = null;

    return gtk.FALSE;
}

// HACK: This is a hack to get around the fact that the GdkEventKey struct
// is opaque in translate-c, so we can't use it directly. The button evet
// should have the same layout for the fields we care about.
const SIZE = 60;
const GdkEventKey = [SIZE / 4]u32;

fn eventKey(widget: *gtk.GtkWidget, arg_event: *gtk.GdkEventKey, self: *BackendGtk) callconv(.C) gtk.gboolean {
    _ = widget;

    const event = @as(*GdkEventKey, @ptrCast(@alignCast(arg_event)));
    std.debug.print("data: {any}\n", .{event});

    const char = event[7];
    const pressed = event[0] == gtk.GDK_KEY_PRESS;

    const ev = desktop.parseKey(char, pressed, &self.modifiers) orelse return gtk.FALSE;

    self.events.append(self.a, ev) catch |err| {
        std.log.debug("Failed to append event: {any}", .{err});
    };

    return @intFromBool(gtk.TRUE);
}

fn eventDestroy(widget: *gtk.GtkWidget, self: *BackendGtk) callconv(.C) void {
    _ = widget;
    self.closed = true;
}

const thunk = struct {
    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        const window = @as(*BackendGtk, @ptrCast(@alignCast(ptr)));

        const cr = window.cr orelse return;

        // Convert the logical position (row, col) to pixel coordinates
        const x = @as(f64, @floatFromInt(pos.col)) * CHAR_WIDTH;
        const y = @as(f64, @floatFromInt(pos.row)) * CHAR_HEIGHT;

        switch (node.content) {
            .Text => |ch| {
                // Set background color for the character cell

                if (node.background) |bg| {
                    const rbg = bg.toRgb();
                    const bg_r = @as(f64, @floatFromInt(rbg[0])) / 255.0;
                    // const bg_r = @as(f64, ((text_node.bg_color >> 16) & 0xFF)) / 255.0;
                    // const bg_g = @as(f64, ((text_node.bg_color >> 8) & 0xFF)) / 255.0;
                    // const bg_b = @as(f64, (text_node.bg_color & 0xFF)) / 255.0;
                    gtk.cairo_set_source_rgb(cr, bg_r, bg_r, bg_r);
                }

                gtk.cairo_rectangle(cr, x, y, CHAR_WIDTH, CHAR_HEIGHT);
                gtk.cairo_fill(cr);

                // Set font and font size
                gtk.cairo_select_font_face(cr, "Monospace", gtk.CAIRO_FONT_SLANT_NORMAL, gtk.CAIRO_FONT_WEIGHT_NORMAL);
                gtk.cairo_set_font_size(cr, FONT_SIZE);

                // Set foreground color for the text
                // const fg_r = @as(f64, ((text_node.fg_color >> 16) & 0xFF)) / 255.0;
                // const fg_g = @as(f64, ((text_node.fg_color >> 8) & 0xFF)) / 255.0;
                // const fg_b = @as(f64, (text_node.fg_color & 0xFF)) / 255.0;
                gtk.cairo_set_source_rgb(cr, 0.78, 0.78, 0.78);

                // Convert character to a Zig slice for cairo_show_text
                // var char_buf: [4]u8 = undefined;
                // const char_len = std.unicode.utf8Encode(ch, &char_buf);
                // const char_slice = char_buf[0..char_len];

                // Position the text within the cell (adjust for font metrics if needed)
                gtk.cairo_move_to(cr, x, y + FONT_SIZE); // Y position is typically the baseline

                var buf = [2:0]u8{ ch, 0 };
                gtk.cairo_show_text(cr, &buf);
            },
            // Add more cases here for other node types (e.g., .rect, .image)
            // .rect => {
            //     const rect_node = node.rect;
            //     const r = @as(f64, ((rect_node.color >> 16) & 0xFF)) / 255.0;
            //     const g = @as(f64, ((rect_node.color >> 8) & 0xFF)) / 255.0;
            //     const b = @as(f64, (rect_node.color & 0xFF)) / 255.0;
            //     gtk.cairo_set_source_rgb(cr, r, g, b);
            //     gtk.cairo_rectangle(cr, x, y, @as(f64, @intToFloat(rect_node.width)), @as(f64, @intToFloat(rect_node.height)));
            //     gtk.cairo_fill(cr);
            // },
            else => {
                // Handle unsupported node types or log a warning
                std.log.warn("Unsupported Backend.Node type for rendering", .{});
            },
        }
    }

    fn poll(ptr: *anyopaque, timeout: i32) Backend.Event {
        _ = timeout;

        const window = @as(*BackendGtk, @ptrCast(@alignCast(ptr)));

        while (gtk.gtk_events_pending() != 0) {
            _ = gtk.gtk_main_iteration();
        }

        if (window.closed) return Backend.Event.End;

        if (window.events.items.len > 0) {
            const event = window.events.orderedRemove(0);
            return event;
        }
        // Reset modifiers after processing events (or at the start of the next poll)
        // window.modifiers = .{};

        return Backend.Event.Timeout;
    }

    fn getSize(ptr: *anyopaque) lib.Vec2 {
        const window = @as(*BackendGtk, @ptrCast(@alignCast(ptr)));
        return .{
            .row = @as(usize, @intCast(window.height)) / @as(usize, @intFromFloat(CHAR_HEIGHT)),
            .col = @as(usize, @intCast(window.width)) / @as(usize, @intFromFloat(CHAR_WIDTH)),
        };
    }

    fn deinit(ptr: *anyopaque) void {
        const window = @as(*BackendGtk, @ptrCast(@alignCast(ptr)));
        window.events.deinit(window.a);
        window.a.destroy(window);
    }

    fn render(ptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
        const window = @as(*BackendGtk, @ptrCast(@alignCast(ptr)));
        switch (mode) {
            .begin => {
                // In GTK/Cairo, drawing happens in the "draw" signal handler.
                // We're setting the 'cr' in draw_event, so we don't need to do much here.
                // If you were to do immediate mode rendering, you might start a new Cairo path here.
            },
            .end => {
                // Invalidate the drawing area to trigger a redraw
                gtk.gtk_widget_queue_draw(window.drawarea);
            },
        }
    }
};

pub fn backend(window: *BackendGtk) Backend {
    return Backend{
        .dataptr = window,
        .vtable = &Backend.VTable{
            .draw = thunk.draw,
            .poll = thunk.poll,
            .deinit = thunk.deinit,
            .render = thunk.render,
            .getSize = thunk.getSize,
        },
    };
}
