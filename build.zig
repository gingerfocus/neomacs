const std = @import("std");

pub fn build(b: *std.Build) void {
    const static = b.option(bool, "static", "try to complile everything statically") orelse false;
    const target = b.standardTargetOptions(if (static) .{ .default_target = .{ .abi = .musl } } else .{});
    const optimize = b.standardOptimizeOption(.{});

    // build neomacs
    const neomacsExe = b.addExecutable(.{
        .root_source_file = b.path("src/main.zig"),
        .name = "neomacs",
        .target = target,
        .optimize = optimize,
        .linkage = if (static) .static else .dynamic,
    });
    const terminal = b.dependency("terminal", .{ .target = target, .optimize = optimize });
    neomacsExe.root_module.addImport("scured", terminal.module("scured"));
    neomacsExe.root_module.addImport("thermit", terminal.module("thermit"));

    // neomacsExe.linkSystemLibrary("tree-sitter");
    neomacsExe.linkLibC();

    // ---------
    if (true) {
        const luajit_build_dep = b.dependency("luajit-build", .{
            .target = target,
            .optimize = optimize,
            .link_as = .static,
        });
        const luajit_build = luajit_build_dep.module("luajit-build");
        neomacsExe.root_module.addImport("syslua", luajit_build);
    } else {
        neomacsExe.linkSystemLibrary("luajit-5.1");
        // b.addTranslateC(.{
        //     .root_source_file = b.addConfigHeader()
        // })
        // b.addModule()
        // neomacsExe.root_module.addImport()
    }
    // ---------

    // install neomacs
    b.installArtifact(neomacsExe);

    // run neomacs
    const neomacs = b.addRunArtifact(neomacsExe);
    // neomacs.step.dependOn(b.getInstallStep());
    if (b.args) |argumnets| {
        neomacs.addArgs(argumnets);
    } else {
        // open a demo file
        neomacs.addArg("etc/demo.txt");
    }
    const run = b.step("run", "run neomacs");
    run.dependOn(&neomacs.step);

    // -------------------------------------------------------------------------

    // const tests = b.addTest(.{
    //     .optimize = optimize,
    //     .target = target,
    //     .root_source_file = b.path("test/01.zig"),
    // });
    // const testStep = b.step("test", "run the tests");
    // testStep.dependOn(&tests.step);

    // -------------------------------------------------------------------------

    const zssMod = b.createModule(.{
        .root_source_file = b.path("src/zss.zig"),
        .target = target,
        .optimize = optimize,
    });
    zssMod.addImport("thermit", terminal.module("thermit"));

    const zssExe = b.addExecutable(.{
        .name = "zss",
        .root_source_file = b.path("src/bin/zss.zig"),
        .target = target,
        .optimize = optimize,
    });
    zssExe.root_module.addImport("zss", zssMod);
    // neomacsExe.root_module.addImport("zss", zssMod);

    const zssStep = b.step("zss", "build zss");
    zssStep.dependOn(&b.addInstallArtifact(zssExe, .{}).step);

    // -------------------------------------------------------------------------

    const check = b.step("check", "Lsp Check Step");
    check.dependOn(&zssExe.step);
    check.dependOn(&neomacsExe.step);
    // check.dependOn(&wevExe.step);
}
