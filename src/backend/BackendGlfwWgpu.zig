const root = @import("../root.zig");
const std = root.std;
const wgpu = @import("wgpu");
const lib = root.lib;

const builtin = @import("builtin");

const Backend = @import("Backend.zig");

pub const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
    if (builtin.os.tag == .linux) {
        @cDefine("GLFW_EXPOSE_NATIVE_WAYLAND", "1");
        @cInclude("GLFW/glfw3native.h");
    }
});

const Self = @This();

const BackendWgpu = @This();

const shader_code =
    \\@vertex
    \\fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4<f32> {
    \\    let x = f32(i32(in_vertex_index) - 1);
    \\    let y = f32(i32(in_vertex_index & 1u) * 2 - 1);
    \\    return vec4<f32>(x, y, 0.0, 1.0);
    \\}
    \\
    \\@fragment
    \\fn fs_main() -> @location(0) vec4<f32> {
    \\    return vec4<f32>(1.0, 0.0, 0.0, 1.0);
    \\}
;
allocator: std.mem.Allocator,

window: *glfw.GLFWwindow,

device: *wgpu.Device,
surface: *wgpu.Surface,
queue: *wgpu.Queue,
pipeline: *wgpu.RenderPipeline,

const VTable = Backend.VTable{
    .render = render,
    .draw = draw,
    .getSize = getSize,
    .setCursor = setCursor,
    .poll = poll,
    .deinit = deinit,
};

pub fn backend(self: *Self) Backend {
    return .{
        .dataptr = self,
        .vtable = &VTable,
    };
}

pub fn init(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);

    // Initialize GLFW
    _ = glfw.glfwInit();

    // Create a window
    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);
    const window = glfw.glfwCreateWindow(640, 480, "Neomacs", null, null) orelse {
        return error.WindowCreationFaled;
    };

    self.* = .{
        .allocator = allocator,
        .window = window,
        .device = undefined,
        .surface = undefined,
        .queue = undefined,
        .pipeline = undefined,
    };

    try self.initWgpu();

    return self;
}

fn deinit(dataptr: *anyopaque) void {
    var self: *Self = @ptrCast(@alignCast(dataptr));
    self.device.release();
    self.surface.release();
    self.queue.release();
    self.pipeline.release();
    // glfw.destroyWindow(self.window);
    // glfw.terminate();
    self.allocator.destroy(self);
}
fn initWgpu(self: *Self) !void {
    // Create a wgpu instance
    const instance = wgpu.Instance.create(null) orelse {
        return error.InstanceCreationFailed;
    };
    defer instance.release();

    // Create a surface
    const wayland_display = glfw.glfwGetWaylandDisplay();
    const wayland_surface = glfw.glfwGetWaylandWindow(self.window);

    const fromWaylandSurface: wgpu.SurfaceSourceWaylandSurface = .{
        .display = @ptrCast(wayland_display.?),
        .surface = @ptrCast(wayland_surface.?),
    };

    const surfaceDescriptor: wgpu.SurfaceDescriptor = .{
        .next_in_chain = &fromWaylandSurface.chain,
        .label = wgpu.StringView.fromSlice("wayland surface"),
    };
    const surface = instance.createSurface(&surfaceDescriptor) orelse {
        return error.SurfaceCreationFailed;
    };
    self.surface = surface;

    // Request an adapter
    const adapter = blk: {
        var adapter_options = wgpu.RequestAdapterOptions{
            .compatible_surface = surface,
        };
        const result = instance.requestAdapterSync(&adapter_options, 0);
        break :blk result.adapter orelse {
            return error.AdapterRequestFailed;
        };
    };
    defer adapter.release();

    // Request a device
    const device = blk: {
        const device_desc = wgpu.DeviceDescriptor{
            .required_limits = null,
        };
        const result = adapter.requestDeviceSync(instance, &device_desc, 0);
        break :blk result.device orelse {
            return error.DeviceRequestFailed;
        };
    };
    self.device = device;

    // Get the queue
    self.queue = device.getQueue() orelse {
        return error.QueueRequestFailed;
    };

    // Create the render pipeline
    const shader_module = blk: {
        const shader_desc = wgpu.shaderModuleWGSLDescriptor(.{
            .code = shader_code,
        });
        break :blk device.createShaderModule(&shader_desc) orelse {
            return error.ShaderModuleCreationFailed;
        };
    };
    defer shader_module.release();

    const pipeline_layout = device.createPipelineLayout(&wgpu.PipelineLayoutDescriptor{
        .bind_group_layouts = &[_]*wgpu.BindGroupLayout{},
        .bind_group_layout_count = 0,
    }).?;
    defer pipeline_layout.release();

    const color_target_state = wgpu.ColorTargetState{
        .format = .bgra8_unorm_srgb,
        // .format = self.surface.getPreferredFormat(adapter),
        .write_mask = wgpu.ColorWriteMasks.all,
    };

    const fragment_state = wgpu.FragmentState{
        .module = shader_module,
        .entry_point = wgpu.StringView.fromSlice("fs_main"),
        .target_count = 1,
        .targets = &.{color_target_state},
    };

    const render_pipeline_desc = wgpu.RenderPipelineDescriptor{
        .layout = pipeline_layout,
        .vertex = wgpu.VertexState{
            .module = shader_module,
            .entry_point = wgpu.StringView.fromSlice("vs_main"),
        },
        .fragment = &fragment_state,
        .primitive = .{},
        .multisample = .{},
    };

    self.pipeline = device.createRenderPipeline(&render_pipeline_desc) orelse {
        return error.PipelineCreationFailed;
    };
}

fn render(dataptr: *anyopaque, mode: Backend.VTable.RenderMode) void {
    var self: *Self = @ptrCast(@alignCast(dataptr));
    switch (mode) {
        .begin => {
            var frame: wgpu.SurfaceTexture = undefined;
            self.surface.getCurrentTexture(&frame);
            self.surface.configure(&wgpu.SurfaceConfiguration{
                .width = 640,
                .height = 480,
                .device = self.device,
                .format = .bgra8_unorm_srgb,
            });
            const view = frame.texture.?.createView(null) orelse return;
            defer view.release();

            const command_encoder = self.device.createCommandEncoder(&.{}) orelse return;
            defer command_encoder.release();

            const render_pass = command_encoder.beginRenderPass(&wgpu.RenderPassDescriptor{
                .color_attachment_count = 1,
                .color_attachments = &.{
                    wgpu.ColorAttachment{
                        .view = view,
                        .load_op = wgpu.LoadOp.clear,
                        .store_op = wgpu.StoreOp.store,
                        .clear_value = wgpu.Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 },
                    },
                },
            }) orelse return;
            defer render_pass.release();

            render_pass.setPipeline(self.pipeline);
            render_pass.draw(3, 1, 0, 0);
        },
        .end => {
            _ = self.surface.present();
        },
    }
}

fn draw(self: *anyopaque, pos: lib.Vec2, node: Backend.Node) void {
    _ = self;
    _ = pos;
    _ = node;
}

fn getSize(dataptr: *anyopaque) lib.Vec2 {
    const self: *const Self = @ptrCast(@alignCast(dataptr));
    var width: c_int = 0;
    var height: c_int = 0;
    glfw.glfwGetWindowSize(self.window, &width, &height);
    return .{ .row = @intCast(width), .col = @intCast(height) };
}

fn setCursor(self: *anyopaque, pos: lib.Vec2) void {
    _ = self;
    _ = pos;
}

fn poll(dataptr: *anyopaque, timeout: i32) Backend.Event {
    _ = timeout;

    const self: *Self = @ptrCast(@alignCast(dataptr));
    _ = self;
    // glfw.pollEvents();
    // if (glfw.windowShouldClose(self.window)) {
    //     return .End;
    // }
    return .Unknown;
}
