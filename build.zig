const std = @import("std");

pub fn build(b: *std.Build) void {
    const windowing = b.option(bool, "windowing", "add window backend") orelse true;
    const static = b.option(bool, "static", "try to complile everything statically") orelse false;
    // const xevdocs = b.option(bool, "xev-docs", "emit docs for xev-docs") orelse true;

    if (windowing and static) {
        std.debug.print("error: Executable can't link in a windowing system and be built statically!\n", .{});
        std.process.exit(1);
    }
    const options = b.addOptions();
    options.addOption(bool, "windowing", windowing);

    // ---------

    // b.graph.host
    const target = b.standardTargetOptions(if (static) .{ .default_target = .{ .abi = .musl } } else .{});
    const optimize = b.standardOptimizeOption(.{});

    // ---------

    // build neomacs
    const neomacs = b.addModule("neomacs", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const terminal = b.dependency("terminal", .{ .target = target, .optimize = optimize });
    neomacs.addImport("scured", terminal.module("scured"));
    neomacs.addImport("thermit", terminal.module("thermit"));
    neomacs.addImport("options", options.createModule());

    // neomacsExe.linkSystemLibrary("tree-sitter");
    neomacs.link_libc = true;


    // ---------

    if (static) {
        const luajit_build_dep = b.dependency("luajit-build", .{
            .target = target,
            .optimize = optimize,
            .link_as = .static,
        });
        const luajit_build = luajit_build_dep.module("luajit-build");
        neomacs.addImport("syslua", luajit_build);
    } else {
        const luajit_c = b.addModule("syslua", .{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/ffi/luajitc.zig"),
        });
        neomacs.addImport("syslua", luajit_c);
        neomacs.linkSystemLibrary("luajit-5.1", .{});
    }

    // ---------

    // if (b.lazyDependency("mach", .{ .target = target, .optimize = optimize })) |mach| {
    //     neomacs.addImport("mach", mach.module("mach"));
    // }

    // ---------

    if (windowing) {
        const clientHeaderCommand = b.addSystemCommand(&.{ "wayland-scanner", "client-header" });
        clientHeaderCommand.addFileArg(b.path("etc/xdg-shell.xml"));
        const clientHeader = clientHeaderCommand.addOutputFileArg("xdg-shell-protocol.h");

        const privateCodeCommand = b.addSystemCommand(&.{ "wayland-scanner", "private-code" });
        privateCodeCommand.addFileArg(b.path("etc/xdg-shell.xml"));
        const privateCode = privateCodeCommand.addOutputFileArg("xdg-shell-protocol.c");

        neomacs.addCSourceFile(.{ .file = privateCode });
        neomacs.addIncludePath(clientHeader.dirname());

        neomacs.linkSystemLibrary("wayland-client", .{});
        neomacs.linkSystemLibrary("xkbcommon", .{});

        neomacs.linkSystemLibrary("freetype2", .{});

        neomacs.linkSystemLibrary("gtk-3", .{});
        neomacs.linkSystemLibrary("gdk-3", .{});
        neomacs.linkSystemLibrary("atk-1.0", .{});
        neomacs.linkSystemLibrary("cairo", .{});
        neomacs.linkSystemLibrary("gobject-2.0", .{});
    }

    // ---------

    const graphi = b.dependency("graphi", .{
        .target = target,
        .optimize = optimize,
    });
    neomacs.linkLibrary(graphi.artifact("graphi"));
    neomacs.addIncludePath(graphi.namedLazyPath("include"));
    // neomacs.linkSystemLibrary("graphi", .{});

    // ---------

    const xev = b.dependency("libxev", .{
        .target = target,
        .optimize = optimize,
        .@"emit-man-pages" = true,
    });
    neomacs.addImport("xev", xev.module("xev"));

    // ---------

    const zigrc = b.dependency("zigrc", .{
        .target = target,
        .optimize = optimize,
    });
    neomacs.addImport("zigrc", zigrc.artifact("zig-rc").root_module);

    // ---------

    const neomacsExe = b.addExecutable(.{
        .root_module = neomacs,
        .name = "neomacs",
        .linkage = if (static) .static else .dynamic,
    });

    // install neomacs as default
    b.installArtifact(neomacsExe);

    const neomacsRun = b.addRunArtifact(neomacsExe);
    if (b.args) |args| neomacsRun.addArgs(args) else {
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

    // const wevExe = b.addExecutable(.{
    //     .root_source_file = b.path("src/bin/wev.zig"),
    //     .name = "wev",
    //     .target = target,
    //     .optimize = optimize,
    // });
    //
    // wevExe.root_module.addImport("neomacs", neomacs);
    //
    // addBuildAndRunSteps(b, "wev", wevExe);

    // -------------------------------------------------------------------------

    const check = b.step("check", "Lsp Check Step");
    check.dependOn(&zssExe.step);
    // check.dependOn(&wevExe.step);
    check.dependOn(&neomacsExe.step);

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
