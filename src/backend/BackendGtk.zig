const root = @import("../root.zig");
const std = root.std;
const lib = root.lib;
const trm = root.trm;

const desktop = lib.desktop;

const Backend = @import("Backend.zig");

const Self = @This();

const gtk = @cImport({
    @cDefine("GDK_DISABLE_DEPRECATED", "1");
    @cDefine("GTK_DISABLE_DEPRECATED", "1");
    @cInclude("gtk/gtk.h");
    @cInclude("gdk/gdk.h");
    @cInclude("gdk/gdkkeysyms.h");
});

// shim for c.g_signal_connect as translate-c is broken for this macro
fn gtkGSignalConnect(instance: gtk.gpointer, detailed_signal: [*c]const u8, c_handler: gtk.GCallback, data: gtk.gpointer) void {
    _ = gtk.g_signal_connect_data(@ptrCast(instance), detailed_signal, c_handler, data, null, @as(gtk.GConnectFlags, 0));
}

events: std.ArrayListUnmanaged(Backend.Event) = .{},
modifiers: trm.KeyModifiers = .{},

closed: bool = false,

width: i32 = 0,
height: i32 = 0,

a: std.mem.Allocator,

mainwin: *gtk.GtkWidget,
drawarea: *gtk.GtkWidget,
cr: ?*desktop.cairo.cairo_t = null,

pub fn init(a: std.mem.Allocator) !*Self {
    const self = try a.create(Self);

    if (gtk.gtk_init_check(null, null) == gtk.FALSE) {
        return error.GtkInitFailed;
    }

    const mainwin = gtk.gtk_window_new(gtk.GTK_WINDOW_TOPLEVEL);
    const drawarea = gtk.gtk_drawing_area_new();
    gtk.gtk_window_set_default_size(@ptrCast(mainwin), 800, 600);

    gtk.gtk_container_add(@ptrCast(mainwin), drawarea);

    self.* = .{
        .a = a,
        .mainwin = mainwin,
        .drawarea = drawarea,
    };

    gtkGSignalConnect(drawarea, "draw", @ptrCast(&eventDraw), self);
    gtkGSignalConnect(drawarea, "configure-event", @ptrCast(&eventConfigure), self);
    gtkGSignalConnect(mainwin, "key-press-event", @ptrCast(&eventKey), self);
    gtkGSignalConnect(mainwin, "key-release-event", @ptrCast(&eventKey), self);
    gtkGSignalConnect(mainwin, "destroy", @ptrCast(&eventDestroy), self);
    gtkGSignalConnect(mainwin, "size-allocate", @ptrCast(&eventSizeAllocate), self);

    gtk.gtk_widget_show_all(mainwin);

    return self;
}

fn eventSizeAllocate(widget: *gtk.GtkWidget, allocation: *gtk.GtkAllocation, self: *Self) callconv(.C) void {
    _ = widget;
    self.width = allocation.width;
    self.height = allocation.height;
    self.events.append(self.a, .Resize) catch {};
}

fn eventConfigure(widget: *gtk.GtkWidget, event: *gtk.GdkEventConfigure, self: *Self) callconv(.C) gtk.gboolean {
    _ = event;
    self.width = gtk.gtk_widget_get_allocated_width(widget);
    self.height = gtk.gtk_widget_get_allocated_height(widget);
    return gtk.FALSE;
}

fn eventDraw(widget: *gtk.GtkWidget, cr: *desktop.cairo.cairo_t, self: *Self) callconv(.C) gtk.gboolean {
    _ = widget;

    // Clear the drawing area with the background color
    desktop.cairo.cairo_set_source_rgba(cr, 0.18, 0.18, 0.18, 0.9); // #282828
    desktop.cairo.cairo_paint(cr);

    // The actual rendering will happen when the Backend calls thunk.draw for each node.
    // This draw_event just prepares the cairo context.
    self.cr = cr;

    // Call the render graph function directly now for immediate rendering
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

fn eventKey(widget: *gtk.GtkWidget, arg_event: *gtk.GdkEventKey, self: *Self) callconv(.C) gtk.gboolean {
    _ = widget;

    const event = @as(*GdkEventKey, @ptrCast(@alignCast(arg_event)));
    // std.debug.print("data: {any}\n", .{event});

    const char = event[7];
    const pressed = event[0] == gtk.GDK_KEY_PRESS; // 9 for release

    const ev = desktop.parseKey(char, pressed, &self.modifiers) orelse return gtk.FALSE;

    self.events.append(self.a, Backend.Event{ .Key = ev }) catch |err| {
        std.log.debug("Failed to append event: {any}", .{err});
    };

    return @intFromBool(gtk.TRUE);
}

fn eventDestroy(widget: *gtk.GtkWidget, self: *Self) callconv(.C) void {
    _ = widget;
    self.closed = true;
}

const thunk = struct {
    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));

        const cr = window.cr orelse return;

        desktop.cairodraw(cr, pos, node);
    }

    fn poll(ptr: *anyopaque, timeout: i32) Backend.Event {
        _ = timeout;

        const window = @as(*Self, @ptrCast(@alignCast(ptr)));

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
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));
        return .{
            .row = @as(usize, @intCast(window.height)) / @as(usize, @intFromFloat(desktop.CHAR_HEIGHT)) / 3,
            .col = @as(usize, @intCast(window.width)) / @as(usize, @intFromFloat(desktop.CHAR_WIDTH)) / 3,
        };
    }

    fn deinit(ptr: *anyopaque) void {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));
        window.events.deinit(window.a);
        window.a.destroy(window);
    }

    fn render(ptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));
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

    fn setCursor(ptr: *anyopaque, pos: lib.Vec2) void {
        const window = @as(*Self, @ptrCast(@alignCast(ptr)));
        const cr = window.cr orelse return;

        const x = @as(f64, @floatFromInt(pos.col)) * desktop.CHAR_WIDTH;
        const y = @as(f64, @floatFromInt(pos.row)) * desktop.CHAR_HEIGHT;

        desktop.cairo.cairo_set_source_rgb(cr, 1.0, 1.0, 1.0); // White cursor
        desktop.cairo.cairo_rectangle(cr, x, y, desktop.CHAR_WIDTH, desktop.CHAR_HEIGHT);
        desktop.cairo.cairo_fill(cr);
    }
};

pub fn backend(window: *Self) Backend {
    return Backend{
        .dataptr = window,
        .vtable = &Backend.VTable{
            .draw = thunk.draw,
            .poll = thunk.poll,
            .deinit = thunk.deinit,
            .render = thunk.render,
            .getSize = thunk.getSize,
            .setCursor = thunk.setCursor,
        },
    };
}
