const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .root_source_file = b.path("src/main.zig"),
        .name = "zano",
        .target = target,
        .optimize = optimize,
    });

    const terminal = b.dependency("terminal", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("thermit", terminal.module("thermit"));
    exe.root_module.addImport("scinee", terminal.module("scinee"));

    exe.addIncludePath(b.path("src"));

    b.installArtifact(exe);
    // -------------------------------------------------------------------------

    const check = b.step("check", "Lsp Check Step");
    check.dependOn(&exe.step);

    // -------------------------------------------------------------------------

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |argumnets| run_cmd.addArgs(argumnets);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
