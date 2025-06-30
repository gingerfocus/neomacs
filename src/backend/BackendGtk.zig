const std = @import("std");
const Backend = @import("Backend.zig");
const root = @import("root");
const lib = root.lib;
const mem = std.mem;
const xev = root.xev;
const trm = @import("thermit");

const Window = @This();
const BackendGtk = @This();

const gtk = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("gdk/gdk.h");
    @cInclude("gdk/gdkkeysyms.h");
});

const GtkEvent = struct {
    pressed: bool,
    ty: union(enum) {
        key: u32,
    },
};

events: std.ArrayListUnmanaged(GtkEvent) = .{},
modifiers: trm.KeyModifiers = .{},

closed: bool = false,

width: i32 = 0,
height: i32 = 0,

a: std.mem.Allocator,

mainwin: *gtk.GtkWidget,
drawarea: *gtk.GtkWidget,
cr: ?*gtk.cairo_t,

pub fn init(a: std.mem.Allocator) !*Window {
    const self = try a.create(Window);

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
        .cr = null,
    };

    _ = gSignalConnect(drawarea, "draw", @as(gtk.GCallback, @ptrCast(&draw_event)), self);
    _ = gSignalConnect(drawarea, "configure-event", @as(gtk.GCallback, @ptrCast(&configure_event)), self);
    _ = gSignalConnect(mainwin, "key-press-event", @as(gtk.GCallback, @ptrCast(&key_press_event)), self);
    _ = gSignalConnect(mainwin, "destroy", @as(gtk.GCallback, @ptrCast(&destroy_event)), self);

    gtk.gtk_widget_show_all(mainwin);

    return self;
}

// shim for c.g_signal_connect as translate-c is broken for this macro
fn gSignalConnect(instance: gtk.gpointer, detailed_signal: [*c]const u8, c_handler: gtk.GCallback, data: gtk.gpointer) void {
    _ = gtk.g_signal_connect_data(@ptrCast(instance), detailed_signal, c_handler, data, null, @as(gtk.GConnectFlags, 0));
}

fn configure_event(widget: *gtk.GtkWidget, event: *gtk.GdkEventConfigure, self: *Window) callconv(.C) gtk.gboolean {
    _ = event;
    self.width = gtk.gtk_widget_get_allocated_width(widget);
    self.height = gtk.gtk_widget_get_allocated_height(widget);
    return gtk.FALSE;
}

fn draw_event(widget: *gtk.GtkWidget, cr: *gtk.cairo_t, self: *Window) callconv(.C) gtk.gboolean {
    _ = widget;
    self.cr = cr;
    gtk.cairo_set_source_rgb(cr, 0.18, 0.18, 0.18); // #282828
    gtk.cairo_paint(cr);
    return gtk.FALSE;
}

fn key_press_event(widget: *gtk.GtkWidget, event: *gtk.GdkEventKey, self: *Window) callconv(.C) gtk.gboolean {
    _ = widget;
    _ = event;
    _ = self;
    // const pressed = event.type == c.GDK_KEY_PRESS;
    // if (!pressed) return c.FALSE;
    //
    // self.events.append(self.a, .{
    //     .pressed = pressed,
    //     .ty = .{ .key = event.keyval },
    // }) catch |err| {
    //     std.log.debug("Failed to append event: {any}", .{err});
    // };

    return @intFromBool(gtk.TRUE);
}

fn destroy_event(widget: *gtk.GtkWidget, self: *Window) callconv(.C) void {
    _ = widget;
    self.closed = true;
}

const thunk = struct {
    fn draw(ptr: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
        _ = pos;
        _ = node;

        const window = @as(*BackendGtk, @ptrCast(@alignCast(ptr)));
        _ = window;
        // Draw implementation
    }

    fn poll(ptr: *anyopaque, timeout: i32) Backend.Event {
        _ = timeout;

        const window = @as(*BackendGtk, @ptrCast(@alignCast(ptr)));

        while (gtk.gtk_events_pending() != 0) {
            _ = gtk.gtk_main_iteration();
        }

        if (window.closed) {
            return Backend.Event.End;
        }

        while (window.events.items.len > 0) {
            const event = window.events.orderedRemove(0);
            switch (event.ty) {
                .key => |keyval| {
                    const unicode = gtk.gdk_keyval_to_unicode(keyval);
                    if (unicode != 0 and unicode < 256) {
                        return Backend.Event{ .Key = .{
                            .character = @intCast(unicode),
                            .modifiers = window.modifiers,
                        }};
                    } else {
                        // TODO: handle special keys
                        std.log.debug("special key: {any}", .{keyval});
                    }
                },
            }
        }

        return Backend.Event.Timeout;
    }

    fn getSize(ptr: *anyopaque) lib.Vec2 {
        const window = @as(*BackendGtk, @ptrCast(@alignCast(ptr)));
        return .{
            .row = @as(usize, @intCast(window.height)) / 16,
            .col = @as(usize, @intCast(window.width)) / 8,
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
            .begin => {},
            .end => {
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
