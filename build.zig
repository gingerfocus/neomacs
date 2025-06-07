const std = @import("std");

pub fn build(b: *std.Build) void {
    const static = b.option(bool, "static", "try to complile everything statically") orelse false;

    const target = b.standardTargetOptions(if (static) .{ .default_target = .{ .abi = .musl } } else .{});
    const optimize = b.standardOptimizeOption(.{});

    // build neomacs
    const neomacs = b.addModule("neomacs", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const terminal = b.dependency("terminal", .{ .target = target, .optimize = optimize });
    neomacs.addImport("scured", terminal.module("scured"));
    neomacs.addImport("thermit", terminal.module("thermit"));

    // neomacsExe.linkSystemLibrary("tree-sitter");
    neomacs.link_libc = true;
    // neomacs.linkLibC();

    // ---------

    if (true) {
        const luajit_build_dep = b.dependency("luajit-build", .{
            .target = target,
            .optimize = optimize,
            .link_as = .static,
        });
        const luajit_build = luajit_build_dep.module("luajit-build");
        neomacs.addImport("syslua", luajit_build);
    } else {
        // @cImport()
        // const headers = .{
        //     std.Build.LazyPath{ .cwd_relative = "/nix/store/ljg715ss1zhk6ibwf6alm6idl3k41m6w-luajit-2.1.1741730670-env/include/luajit.h" },
        //     std.Build.LazyPath{ .cwd_relative = "/nix/store/ljg715ss1zhk6ibwf6alm6idl3k41m6w-luajit-2.1.1741730670-env/include/lua.h" },
        //     std.Build.LazyPath{ .cwd_relative = "/nix/store/ljg715ss1zhk6ibwf6alm6idl3k41m6w-luajit-2.1.1741730670-env/include/lualib.h" },
        //     std.Build.LazyPath{ .cwd_relative = "/nix/store/ljg715ss1zhk6ibwf6alm6idl3k41m6w-luajit-2.1.1741730670-env/include/luajit-2.1/lauxlib.h" },
        // };
        // const trans = b.addTranslateC(.{
        //     .root_source_file = luajitheader,
        //     .target = target,
        //     .optimize = optimize,
        // });
        //
        // const luajit = b.addModule("luajit", .{
        //     .root_source_file = trans.getOutput(),
        //     .target = target,
        //     .optimize = optimize,
        // });
        //
        // neomacs.addImport("syslua", luajit);
        // neomacs.linkSystemLibrary("luajit-5.1", .{});
    }

    // ---------

    const neomacsExe = b.addExecutable(.{
        .root_module = neomacs,
        .name = "neomacs",
        .linkage = if (static) .static else .dynamic,
    });

    // install neomacs as default
    b.installArtifact(neomacsExe);

    const neomacsRun = b.addRunArtifact(neomacsExe);
    if (b.args) |argumnets| {
        neomacsRun.addArgs(argumnets);
    } else {
        // open a demo file
        neomacsRun.addArg("etc/demo.txt");
    }
    const run = b.step("run", "run neomacs");
    run.dependOn(&neomacsRun.step);

    // -------------------------------------------------------------------------

    const zssExe = b.addExecutable(.{
        .name = "zss",
        .root_source_file = b.path("src/bin/zss.zig"),
        .target = target,
        .optimize = optimize,
    });
    zssExe.root_module.addImport("neomacs", neomacs);

    addBuildAndRunSteps(b, "zss", zssExe);

    // -------------------------------------------------------------------------

    const wevExe = b.addExecutable(.{
        .root_source_file = b.path("src/bin/wev.zig"),
        .name = "wev",
        .target = target,
        .optimize = optimize,
    });

    // -------------------------------------------------------------------------

    const clientHeaderCommand = b.addSystemCommand(&.{ "wayland-scanner", "client-header" });
    clientHeaderCommand.addFileArg(b.path("wayland/xdg-shell.xml"));
    const clientHeader = clientHeaderCommand.addOutputFileArg("xdg-shell-protocol.h");

    const privateCodeCommand = b.addSystemCommand(&.{ "wayland-scanner", "private-code" });
    privateCodeCommand.addFileArg(b.path("wayland/xdg-shell.xml"));
    const privateCode = privateCodeCommand.addOutputFileArg("xdg-shell-protocol.c");

    wevExe.addCSourceFile(.{ .file = privateCode });
    wevExe.addIncludePath(clientHeader.dirname());

    wevExe.linkLibC();
    wevExe.linkSystemLibrary("wayland-client");
    wevExe.linkSystemLibrary("xkbcommon");

    wevExe.root_module.addImport("neomacs", neomacs);

    const graphi = b.dependency("graphi", .{
        .target = target,
        .optimize = optimize,
    });
    wevExe.linkLibrary(graphi.artifact("graphi"));
    wevExe.addIncludePath(graphi.namedLazyPath("include"));

    addBuildAndRunSteps(b, "wev", wevExe);

    // -------------------------------------------------------------------------

    const check = b.step("check", "Lsp Check Step");
    check.dependOn(&zssExe.step);
    check.dependOn(&neomacsExe.step);
    check.dependOn(&wevExe.step);

    // -------------------------------------------------------------------------

}

fn addBuildAndRunSteps(
    b: *std.Build,
    comptime name: []const u8,
    output: *std.Build.Step.Compile,
) void {
    // compile the program
    const artifact = b.addInstallArtifact(output, .{});
    const buildStep = b.step(name, "Build " ++ name);
    buildStep.dependOn(&artifact.step);

    // run the program
    const run = b.addRunArtifact(output);
    // run.step.dependOn(b.getInstallStep());
    if (b.args) |args| run.addArgs(args);
    const runStep = b.step(name ++ "-run", "Run " ++ name);
    runStep.dependOn(&run.step);
}
