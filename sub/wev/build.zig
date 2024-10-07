const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // -------------------------------------------------------------------------

    const clientHeaderCommand = b.addSystemCommand(&.{ "wayland-scanner", "client-header" });
    clientHeaderCommand.addFileArg(b.path("wayland/xdg-shell.xml"));
    const clientHeader = clientHeaderCommand.addOutputFileArg("xdg-shell-protocol.h");

    const privateCodeCommand = b.addSystemCommand(&.{ "wayland-scanner", "private-code" });
    privateCodeCommand.addFileArg(b.path("wayland/xdg-shell.xml"));
    const privateCode = privateCodeCommand.addOutputFileArg("xdg-shell-protocol.c");

    // -------------------------------------------------------------------------

    const wevExe = b.addExecutable(.{
        .root_source_file = b.path("src/wev.zig"),
        .name = "wev",
        .target = target,
        .optimize = optimize,
    });

    wevExe.addCSourceFile(.{ .file = privateCode });
    wevExe.addIncludePath(clientHeader.dirname());

    wevExe.linkLibC();
    wevExe.linkSystemLibrary("wayland-client");
    wevExe.linkSystemLibrary("xkbcommon");

    // wevExe.linkSystemLibrary("tree-sitter");

    b.installArtifact(wevExe);

    // run neomacs
    const wev = b.addRunArtifact(wevExe);
    wev.step.dependOn(b.getInstallStep());
    if (b.args) |argumnets| wev.addArgs(argumnets);
    const run = b.step("run", "run wev");
    run.dependOn(&wev.step);

    // -------------------------------------------------------------------------

    const check = b.step("check", "Lsp Check Step");
    check.dependOn(&wevExe.step);
}
