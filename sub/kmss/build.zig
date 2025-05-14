const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const luma = b.addExecutable(.{
        .name = "luma-tty",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    luma.linkLibC();
    luma.addIncludePath(.{ .path = "/nix/store/5qk6xfilkwg9x9fsimrdkqzvfwqpy93h-linux-headers-6.5/include/drm" });
    luma.linkSystemLibrary("drm");

    b.installArtifact(luma);
}
