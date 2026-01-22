const std = @import("std");
const c = @import("c.zig");
const wgpu = @import("wgpu");
const builtin = @import("builtin");

const Demo = struct {
    instance: *wgpu.Instance,
    surface: *wgpu.Surface,
    adapter: *wgpu.Adapter,
    device: *wgpu.Device,
    config: wgpu.SurfaceConfiguration,
    window: *c.GLFWwindow,

    fn deinit(self: *Demo) void {
        self.adapter.release();
        self.device.release();
        self.surface.release();
        self.instance.release();
        c.glfwDestroyWindow(self.window);
        c.glfwTerminate();
    }
};

fn getSurface(instance: *wgpu.Instance, window: *c.GLFWwindow) !*wgpu.Surface {
    switch (builtin.os.tag) {
        .macos => |tag| {
            _ = tag;
            const metal_layer = c.wgpu_create_surface_from_metal_layer(c.glfwGetCocoaWindow(window));
            return instance.createSurface(&(wgpu.SurfaceDescriptor{
                .label = "cocoa surface",
                .source = wgpu.SurfaceSource.metalLayer(metal_layer),
            }));
        },
        .linux => |tag| {
            _ = tag;
            if (c.glfwGetPlatform() == c.GLFW_PLATFORM_WAYLAND) {
                const display = c.glfwGetWaylandDisplay();
                const surface = c.glfwGetWaylandWindow(window);
                const description = wgpu.surfaceDescriptorFromWaylandSurface(.{
                    .display = display.?,
                    .surface = surface.?,
                    .label = "wayland surface",
                });
                return instance.createSurface(&description).?;
            } else if (c.glfwGetPlatform() == c.GLFW_PLATFORM_X11) {
                unreachable;
                // const display = c.glfwGetX11Display();
                // const window_handle = c.glfwGetX11Window(window);
                // return instance.createSurface(&wgpu.SurfaceDescriptor{
                //     .label = "x11 surface",
                //     .source = wgpu.SurfaceSource.xlibWindow(wgpu.SurfaceSourceXlibWindow{
                //         .display = display,
                //         .window = window_handle,
                //     }),
                // });
            }
            return error.UnsupportedPlatform;
        },
        .windows => |tag| {
            _ = tag;
            const hwnd = c.glfwGetWin32Window(window);
            const hinstance: ?*anyopaque = null; // GetModuleHandle(null)
            return instance.createSurface(&wgpu.SurfaceDescriptor{
                .label = "win32 surface",
                .source = wgpu.SurfaceSource.windowsHWND(wgpu.SurfaceSourceWindowsHWND{
                    .hinstance = hinstance,
                    .hwnd = hwnd,
                }),
            });
        },
        else => {
            return error.UnsupportedPlatform;
        },
    }
}

fn handleKey(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    _ = scancode;
    _ = mods;
    _ = window;

    if (key == c.GLFW_KEY_R and (action == c.GLFW_PRESS or action == c.GLFW_REPEAT)) {
        // const demo = @as(*Demo, @ptrCast(c.glfwGetWindowUserPointer(window)));
        // if (demo == null or demo.instance == null) return;
        // wgpuGenerateReport is not in the zig bindings it seems
    }
}

fn handleFramebufferSize(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    if (width == 0 and height == 0) {
        return;
    }

    const demo = @as(?*Demo, @alignCast(@ptrCast(c.glfwGetWindowUserPointer(window)))) orelse return;

    demo.config.width = @intCast(width);
    demo.config.height = @intCast(height);

    demo.surface.configure(&demo.config);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    if (args.len < 2) {
        std.debug.print("add a shader file to run\n", .{});
        return;
    }
    const file = try std.fs.cwd().openFile(args[1], .{});
    const shader_source = try file.readToEndAlloc(alloc, std.math.maxInt(usize));

    if (c.glfwInit() != c.GLFW_TRUE) {
        std.debug.print("Could not initialize glfw", .{});
        return;
    }

    const instance = wgpu.Instance.create(null) orelse {
        std.debug.print("Could not create wgpu instance", .{});
        return;
    };

    c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);
    const window = c.glfwCreateWindow(640, 480, "triangle [wgpu + glfw]", null, null) orelse {
        std.debug.print("Could not create window", .{});
        return;
    };

    const surface = try getSurface(instance, window);

    const resultadapter = instance.requestAdapterSync(&wgpu.RequestAdapterOptions{
        .compatible_surface = surface,
    }, 0);
    const adapter = resultadapter.adapter orelse {
        std.debug.print("Could not get adapter", .{});
        return;
    };

    const device_result = adapter.requestDeviceSync(instance, &wgpu.DeviceDescriptor{
        .required_limits = null,
    }, 0);

    const device = device_result.device orelse {
        std.debug.print("Could not get device", .{});
        return;
    };

    const queue = device.getQueue().?;

    const shader_module = device.createShaderModule(&wgpu.shaderModuleWGSLDescriptor(.{
        .code = shader_source,
    })).?;
    defer shader_module.release();

    const pipeline_layout = device.createPipelineLayout(&wgpu.PipelineLayoutDescriptor{
        .bind_group_layout_count = 0,
        .bind_group_layouts = undefined,
        // .label = "pipeline_layout",
    }).?;
    defer pipeline_layout.release();

    var surface_capabilities: wgpu.SurfaceCapabilities = undefined;
    _ = surface.getCapabilities(adapter, &surface_capabilities);

    const render_pipeline = device.createRenderPipeline(&wgpu.RenderPipelineDescriptor{
        // .label = "render_pipeline",
        .layout = pipeline_layout,
        .vertex = wgpu.VertexState{
            .module = shader_module,
            .entry_point = wgpu.StringView.fromSlice("vs_main"),
        },
        .fragment = &wgpu.FragmentState{
            .module = shader_module,
            .entry_point = wgpu.StringView.fromSlice("fs_main"),
            .target_count = 1,
            .targets = &.{wgpu.ColorTargetState{
                .format = surface_capabilities.formats[0],
                // .write_mask = wgpu.ColorWriteMask.all,
            }},
        },
        .primitive = wgpu.PrimitiveState{
            .topology = wgpu.PrimitiveTopology.triangle_list,
        },
        .multisample = wgpu.MultisampleState{
            .count = 1,
            .mask = 0xFFFFFFFF,
        },
    }).?;
    defer render_pipeline.release();

    var width: c_int = 0;
    var height: c_int = 0;
    c.glfwGetWindowSize(window, &width, &height);

    var config = wgpu.SurfaceConfiguration{
        .device = device,
        .usage = wgpu.TextureUsages.render_attachment,
        .format = surface_capabilities.formats[0],
        .present_mode = wgpu.PresentMode.fifo,
        .alpha_mode = surface_capabilities.alpha_modes[0],

        .width = @intCast(width),
        .height = @intCast(height),
    };

    surface.configure(&config);

    var demo = Demo{
        .instance = instance,
        .surface = surface,
        .adapter = adapter,
        .device = device,
        .config = config,
        .window = window,
    };
    defer demo.deinit();

    c.glfwSetWindowUserPointer(window, &demo);
    _ = c.glfwSetKeyCallback(window, handleKey);
    _ = c.glfwSetFramebufferSizeCallback(window, handleFramebufferSize);

    while (c.glfwWindowShouldClose(window) == 0) {
        c.glfwPollEvents();

        var surface_texture: wgpu.SurfaceTexture = undefined;
        surface.getCurrentTexture(&surface_texture);

        switch (surface_texture.status) {
            .success_optimal, .success_suboptimal => {},
            .timeout, .outdated, .lost => {
                if (surface_texture.texture != null) {
                    surface_texture.texture.?.release();
                }
                c.glfwGetWindowSize(window, &width, &height);
                if (width != 0 and height != 0) {
                    demo.config.width = @intCast(width);
                    demo.config.height = @intCast(height);
                    surface.configure(&demo.config);
                }
                continue;
            },
            .out_of_memory, .device_lost => {
                std.debug.print("getCurrentTexture failed with status: {s}", .{@tagName(surface_texture.status)});
                return;
            },
            .@"error" => unreachable,
        }
        const frame = surface_texture.texture.?.createView(null).?;

        const command_encoder = device.createCommandEncoder(&wgpu.CommandEncoderDescriptor{
            .label = wgpu.StringView.fromSlice("command_encoder"),
        }).?;

        const render_pass_encoder = command_encoder.beginRenderPass(&wgpu.RenderPassDescriptor{
            .label = wgpu.StringView.fromSlice("render_pass_encoder"),
            .color_attachment_count = 1,
            .color_attachments = &.{wgpu.ColorAttachment{
                .view = frame,
                .load_op = wgpu.LoadOp.clear,
                .store_op = wgpu.StoreOp.store,
                .clear_value = wgpu.Color{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 },
            }},
        }).?;

        render_pass_encoder.setPipeline(render_pipeline);
        render_pass_encoder.draw(3, 1, 0, 0);
        render_pass_encoder.end();

        const command_buffer = command_encoder.finish(&wgpu.CommandBufferDescriptor{
            .label = wgpu.StringView.fromSlice("command_buffer"),
        }).?;

        queue.submit(&.{command_buffer});
        _ = surface.present();

        frame.release();
        surface_texture.texture.?.release();
        command_buffer.release();
        render_pass_encoder.release();
        command_encoder.release();
    }
}
