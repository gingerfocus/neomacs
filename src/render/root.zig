const std = @import("std");
const root = @import("../root.zig");
const trm = root.trm;
const lib = root.lib;

const State = root.State;
const Backend = State.Backend;
const Node = Backend.Node;
const Color = Backend.Color;
const Component = @import("Component.zig");
const View = Component.View;

const StatusBar = @import("components/StatusBar.zig");
const LineNumbers = @import("components/LineNumbers.zig");
const MainEditor = @import("components/MainEditor.zig");
const CommandLine = @import("components/CommandLine.zig");

pub const sidebarWidth = 3;
pub const statusbarHeight = 2;

const id = struct {
    var static: usize = 0;
    pub fn next() usize {
        static += 1;
        return static;
    }
};

pub fn init(state: *State) !void {
    const size = state.backend.getSize();
    const rootView = View{ .x = 0, .y = 0, .w = size.row, .h = size.col };

    {
        const statusBarView = View{
            .x = 0,
            .y = rootView.h - statusbarHeight,
            .w = rootView.w,
            .h = statusbarHeight,
        };
        const statusBar = Component{
            .dataptr = undefined,
            .vtable = &.{
                .renderFn = StatusBar.render,
            },
        };
        try state.components.put(state.a, id.next(), .{ .comp = statusBar, .view = statusBarView });
    }

    {
        const lineNumbersView = View{
            .x = 0,
            .y = 0,
            .w = sidebarWidth,
            .h = rootView.h - statusbarHeight,
        };
        const lineNumbers = Component{
            .dataptr = undefined,
            .vtable = &.{
                .renderFn = LineNumbers.render,
            },
        };
        try state.components.put(state.a, id.next(), .{ .comp = lineNumbers, .view = lineNumbersView });
    }

    {
        const mainView = View{
            .x = sidebarWidth,
            .y = 0,
            .w = rootView.w - sidebarWidth,
            .h = rootView.h - statusbarHeight,
        };
        const mainEditor = Component{
            .dataptr = undefined,
            .vtable = &.{
                .renderFn = MainEditor.render,
            },
        };
        try state.components.put(state.a, id.next(), .{ .comp = mainEditor, .view = mainView });
    }

    {
        const commandView = View{
            .x = 0,
            .y = rootView.h - 1, // Bottom line of status bar
            .w = rootView.w,
            .h = 1,
        };
        const commandLine = Component{
            .dataptr = undefined,
            .vtable = &.{
                .renderFn = CommandLine.render,
            },
        };
        try state.components.put(state.a, id.next(), .{ .comp = commandLine, .view = commandView });
    }
}

pub fn draw(state: *State) !void {
    if (state.resized) {
        // recompute layout
        const newsize = state.backend.getSize();
        const rootView = View{ .x = 0, .y = 0, .w = newsize.row, .h = newsize.col };

        // Update component views. IDs are based on initialization order in init().
        // 1: statusBar, 2: lineNumbers, 3: mainEditor, 4: commandLine

        // statusBar
        if (state.components.getPtr(1)) |v| {
            v.view = .{
                .x = 0,
                .y = rootView.h - statusbarHeight,
                .w = rootView.w,
                .h = statusbarHeight,
            };
        }

        // lineNumbers
        if (state.components.getPtr(2)) |v| {
            v.view = .{
                .x = 0,
                .y = 0,
                .w = sidebarWidth,
                .h = rootView.h - statusbarHeight,
            };
        }

        // mainEditor
        if (state.components.getPtr(3)) |v| {
            v.view = .{
                .x = sidebarWidth,
                .y = 0,
                .w = rootView.w - sidebarWidth,
                .h = rootView.h - statusbarHeight,
            };
        }

        // commandLine
        if (state.components.getPtr(4)) |v| {
            v.view = .{
                .x = 0,
                .y = rootView.h - 1, // Bottom line of status bar
                .w = rootView.w,
                .h = 1,
            };
        }

        state.resized = false;
    }

    state.backend.render(.begin);
    defer state.backend.render(.end);

    var iter = state.components.iterator();
    while (iter.next()) |v| {
        const comp = v.value_ptr.comp;
        const view = v.value_ptr.view;

        if (view.w == 0 or view.h == 0) continue; // Skip empty components

        comp.vtable.renderFn(comp.dataptr, state, &state.backend, view);
    }
}
