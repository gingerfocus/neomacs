const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build neomacs
    const neomacsExe = b.addExecutable(.{
        .root_source_file = b.path("src/main.zig"),
        .name = "neomacs",
        .target = target,
        .optimize = optimize,
    });
    const terminal = b.dependency("terminal", .{ .target = target, .optimize = optimize });
    neomacsExe.root_module.addImport("scured", terminal.module("scured"));

    neomacsExe.linkSystemLibrary("tree-sitter");
    neomacsExe.linkSystemLibrary("luajit-5.1");
    neomacsExe.linkLibC();

    // install neomacs
    b.installArtifact(neomacsExe);

    // run neomacs
    const neomacs = b.addRunArtifact(neomacsExe);
    // neomacs.step.dependOn(b.getInstallStep());
    if (b.args) |argumnets| neomacs.addArgs(argumnets);
    const run = b.step("run", "run neomacs");
    run.dependOn(&neomacs.step);

    // -------------------------------------------------------------------------
    //
    // // install zss
    // const zssExe = b.dependency("zss", .{}).artifact("zss");
    // b.installArtifact(zssExe);
    //
    // // run zss
    // const zss = b.addRunArtifact(zssExe);
    // if (b.args) |argumnets| zss.addArgs(argumnets);
    // const zssstep = b.step("zss", "run zss");
    // zssstep.dependOn(&zss.step);
    //
    // -------------------------------------------------------------------------
    //
    // // install wev
    // const wevExe = b.dependency("wev", .{}).artifact("wev");
    // b.installArtifact(wevExe);
    //
    // // run wev
    // const wev = b.addRunArtifact(wevExe);
    // if (b.args) |argumnets| wev.addArgs(argumnets);
    // const wevstep = b.step("wev", "run wev");
    // wevstep.dependOn(&wev.step);
    //
    // -------------------------------------------------------------------------

    const check = b.step("check", "Lsp Check Step");
    check.dependOn(&neomacsExe.step);
    // check.dependOn(&zssExe.step);
    // check.dependOn(&wevExe.step);
}
