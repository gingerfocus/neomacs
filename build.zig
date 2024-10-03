const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const neomacsExe = b.addExecutable(.{
        .root_source_file = b.path("src/main.zig"),
        .name = "neomacs",
        .target = target,
        .optimize = optimize,
    });

    const terminal = b.dependency("terminal", .{ .target = target, .optimize = optimize });
    neomacsExe.root_module.addImport("thermit", terminal.module("thermit"));
    neomacsExe.root_module.addImport("scinee", terminal.module("scinee"));

    b.installArtifact(neomacsExe);

    // -------------------------------------------------------------------------

    const check = b.step("check", "Lsp Check Step");
    check.dependOn(&neomacsExe.step);

    // -------------------------------------------------------------------------

    const neomacs = b.addRunArtifact(neomacsExe);
    neomacs.step.dependOn(b.getInstallStep());
    if (b.args) |argumnets| neomacs.addArgs(argumnets);
    const run = b.step("run", "run neomacs");
    run.dependOn(&neomacs.step);

    // -------------------------------------------------------------------------

    const zssExe = b.dependency("zss", .{}).artifact("zss");
    b.installArtifact(zssExe);

    const zss = b.addRunArtifact(zssExe);
    if (b.args) |argumnets| zss.addArgs(argumnets);
    const zssstep = b.step("zss", "run zss");
    zssstep.dependOn(&zss.step);
}
