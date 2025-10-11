const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Option to build standalone version (with embedded FFmpeg)
    const standalone = b.option(bool, "standalone", "Build standalone version without external FFmpeg dependency") orelse false;

    // Create root module
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "media-gen",
        .root_module = root_module,
    });

    // Link system libraries
    exe.linkLibC();

    if (standalone) {
        // For standalone builds, we'll use a different approach
        setupStandaloneBuild(b, exe, target);
    } else {
        // Regular build that requires system FFmpeg
        setupRegularBuild(b, exe, target);
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const test_step = b.step("test", "Run unit tests");

    const test_module = b.createModule(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_exe = b.addTest(.{
        .root_module = test_module,
    });

    const run_test = b.addRunArtifact(test_exe);
    test_step.dependOn(&run_test.step);
}

fn setupRegularBuild(b: *std.Build, exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    _ = target;
    // Regular build - expects system FFmpeg to be available
    // No additional setup needed, FFmpeg will be called as external process

    // Add build options for regular build
    const options = b.addOptions();
    options.addOption(bool, "standalone", false);
    exe.root_module.addOptions("build_options", options);
}

fn setupStandaloneBuild(b: *std.Build, exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    _ = target;

    // For standalone builds, we have several options:
    // 1. Bundle FFmpeg binaries
    // 2. Use FFmpeg libraries statically linked
    // 3. Implement basic media generation without FFmpeg

    // For now, we'll use approach #1 - bundle FFmpeg binaries
    // This will be implemented in the source code
    const options = b.addOptions();
    options.addOption(bool, "standalone", true);
    exe.root_module.addOptions("build_options", options);
}
