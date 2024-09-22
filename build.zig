const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const view = b.addStaticLibrary(.{
        .name = "view",
        .root_source_file = b.path("src/view.zig"),
        .target = target,
        .optimize = optimize,
    });

    const buffer = b.addStaticLibrary(.{
        .name = "buffer",
        .root_source_file = b.path("src/buffer.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tools = b.addStaticLibrary(.{
        .name = "tools",
        .root_source_file = b.path("src/tools.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        // .root_source_file = b.path("src/main.zig"),
        .name = "zano",
        .target = target,
        .optimize = optimize,
    });

    exe.addCSourceFiles(.{
        .root = b.path(""),
        .files = &.{
            // "src/buffer.c",
            "src/cgetopt.c",
            "src/commands.c",
            "src/frontend.c",
            "src/keys.c",
            "src/lex.c",
            "src/main.c",
            // "src/tools.c",
            // "src/view.c",
        },
        .flags = &.{
            // "-std=c23",
        },
    });

    exe.addIncludePath(b.path("src"));

    exe.linkLibrary(view);
    exe.linkLibrary(buffer);
    exe.linkLibrary(tools);

    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("pthread");
    exe.linkSystemLibrary("ncurses");

    exe.linkLibC();

    b.installArtifact(exe);

    // -------------------------------------------------------------------------

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
