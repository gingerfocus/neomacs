const std = @import("std");

pub fn build(b: *std.Build) !void {
    const usegtk = b.option(bool, "gtk", "compile the gtk backend") orelse false;
    // for dev
    const usewayland = b.option(bool, "wayland", "compile the wayland backend") orelse true;
    const needsdyn = usegtk or usewayland;

    // TODO: do more warning for this or make it a compile error
    const static = if (needsdyn) false else b.option(bool, "static", "try to complile everything statically") orelse true;
    const staticlua = if (static) true else b.option(bool, "static-lua", "complile lua statically") orelse static;

    // const xevdocs = b.option(bool, "xev-docs", "emit docs for xev-docs") orelse true;
    // const runtimeVar = b.option([]const u8, "runtime", "set the runtime directory");

    const options = b.addOptions();

    options.addOption(bool, "usegtk", usegtk);
    options.addOption(bool, "usewayland", usewayland);

    // std.debug.print("using options: \n{any}\n", .{.{ .gtk = usegtk, .wayland = usewayland, .static = static }});

    // ---------

    var query = std.Build.StandardTargetOptionsArgs{};
    const builtin = @import("builtin");
    // use musl for static builds on linux
    if (static and builtin.os.tag == .linux) {
        query.default_target.abi = .musl;
    }

    const target = b.standardTargetOptions(query);
    const optimize = b.standardOptimizeOption(.{});

    // ---------

    // build neomacs
    const neomacs = b.addModule("neomacs", .{
        .root_source_file = b.path("src/root.zig"),
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

    addLuaImport(b, neomacs, staticlua, target, optimize);

    // ---------

    // if (b.lazyDependency("mach", .{ .target = target, .optimize = optimize })) |mach| {
    //     neomacs.addImport("mach", mach.module("mach"));
    // }

    // ---------

    if (usewayland) {
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

        neomacs.linkSystemLibrary("cairo", .{});

        // ---------

        const graphi = b.dependency("graphi", .{
            .target = target,
            .optimize = optimize,
        });
        neomacs.linkLibrary(graphi.artifact("graphi"));
        neomacs.addIncludePath(graphi.namedLazyPath("include"));
    }

    if (usegtk) {
        neomacs.linkSystemLibrary("gtk-3", .{});
        neomacs.linkSystemLibrary("gdk-3", .{});
        neomacs.linkSystemLibrary("atk-1.0", .{});
        neomacs.linkSystemLibrary("cairo", .{});
        neomacs.linkSystemLibrary("gobject-2.0", .{});
    }

    // ---------

    // neomacs.linkSystemLibrary("graphi", .{});

    // ---------

    // const xev = b.dependency("libxev", .{
    //     .target = target,
    //     .optimize = optimize,
    //     .@"emit-man-pages" = true,
    // });
    // neomacs.addImport("xev", xev.module("xev"));

    // ---------

    // const zigrc = b.dependency("zigrc", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    // neomacs.addImport("zigrc", zigrc.artifact("zig-rc").root_module);

    // ---------

    const neomacsExe = b.addExecutable(.{
        .root_source_file = b.path("src/bin/neomacs.zig"),
        .name = "neomacs",
        .target = target,
        .optimize = optimize,
        .linkage = if (static) .static else .dynamic,
    });
    neomacsExe.root_module.addImport("neomacs", neomacs);

    // install neomacs as default
    b.installArtifact(neomacsExe);

    const neomacsRun = b.addRunArtifact(neomacsExe);
    if (b.args) |args| neomacsRun.addArgs(args) else {
        // open a demo file
        neomacsRun.addArg("etc/demo.md");
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

    // const treesitter = b.dependency("tree-sitter", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    // neomacs.addImport("tree-sitter", treesitter.module("tree-sitter"));

    // -------------------------------------------------------------------------

    const runtime = b.addInstallDirectory(.{
        .install_dir = .{ .custom = "state" },
        .install_subdir = "neon",
        .source_dir = b.path("runtime"),
    });
    b.getInstallStep().dependOn(&runtime.step);

    // TODO: make this be the output runtime dir not input
    try neomacsRun.getEnvMap().put("NEONRUNTIME", runtime.options.source_dir.getPath(b));

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

    const testStep = b.step("test", "Run tests");
    const tests = b.addTest(.{
        .root_module = neomacs,
    });
    const run_unit_tests = b.addRunArtifact(tests);
    testStep.dependOn(&run_unit_tests.step);

    // -------------------------------------------------------------------------
    //
    // default to false
    // const usekennel = b.option(bool, "usekennel", "compile the with support for literate programming") orelse true;
    //
    // const kennel = b.addModule("kennel", .{
    //     .root_source_file = b.path("src/kennel/root.zig"),
    // });
    // addLuaImport(kennel, staticlua, target, optimize);
    //
    // options.addOption(bool, "usekennel", usekennel);
    // if (usekennel) {
    //     neomacs.addImport("kennel", kennel);
    // }
    //
    // -------------------------------------------------------------------------
    // TODO: man pages to share/man/man1

    // -------------------------------------------------------------------------
    const lynx = b.addExecutable(.{
        .name = "lynx",
        .root_source_file = b.path("src/bin/lynx.zig"),
        .target = target,
        .optimize = optimize,
    });
    check.dependOn(&lynx.step);

    addBuildAndRunSteps(b, "lynx", lynx);
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

fn addLuaImport(
    b: *std.Build,
    module: *std.Build.Module,
    static: bool,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    if (static) {
        if (b.lazyDependency("luajit-build", .{
            .target = target,
            .optimize = optimize,
            .link_as = .static,
        })) |luajit_build_dep| {
            const luajit_build = luajit_build_dep.module("luajit-build");
            module.addImport("syslua", luajit_build);
        }
    } else {
        const luajit_c = b.addModule("syslua", .{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/ffi/luajitc.zig"),
        });
        module.addImport("syslua", luajit_c);
        module.linkSystemLibrary("luajit-5.1", .{});
    }
}
