const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "futureproof",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();

    // Libraries!
    exe.linkSystemLibrary2("glfw3", .{});

    // --------- wgpu -----------------------------------------
    const wgpu = b.dependency("wgpu-native", .{
        .target = target,
        .optimize = optimize,
        .link_mode = .static,
    });
    exe.root_module.addImport("wgpu", wgpu.module("wgpu"));
    // ------------------------------------------------------

    exe.addIncludePath(b.path(".")); // for "extern/futureproof.h"

    // This must come before the install_name_tool call below
    b.installArtifact(exe);

    // if (exe.target.isDarwin()) {
    //     exe.addFrameworkDir("/System/Library/Frameworks");
    //     exe.linkFramework("Foundation");
    //     exe.linkFramework("AppKit");
    // }

    // ------------------------------------------------------

    const run = b.addRunArtifact(exe);
    if (b.args) |args| run.addArgs(args);
    run.getEnvMap().put("RUST_BACKTRACE", "1") catch @panic("OOM");
    const step = b.step("run", "Run the app");
    step.dependOn(&run.step);

    // ------------------------------------------------------

    const check = b.step("check", "Lsp Check Step");
    check.dependOn(&exe.step);
}
