const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // This build always uses embedded FFmpeg

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

    // Always build with embedded FFmpeg
    setupEmbeddedFFmpegBuild(b, exe, target);

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
    const integration_test_step = b.step("test-integration", "Run integration tests");

    // Unit tests
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

    // Integration tests
    const integration_test_module = b.createModule(.{
        .root_source_file = b.path("src/integration_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const integration_test_exe = b.addTest(.{
        .root_module = integration_test_module,
    });

    const run_integration_test = b.addRunArtifact(integration_test_exe);
    integration_test_step.dependOn(&run_integration_test.step);
}

fn setupEmbeddedFFmpegBuild(b: *std.Build, exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    _ = exe;
    _ = target;

    // Check if FFmpeg binaries exist, download if not
    const vendor_dir = "src/vendor/ffmpeg";
    std.fs.cwd().access(vendor_dir, .{}) catch {
        std.log.info("FFmpeg binaries not found, downloading...", .{});

        // Detect platform and run appropriate command
        const builtin = @import("builtin");
        const result = if (builtin.os.tag == .windows) blk: {
            // On Windows, run with bash (Git Bash is available in GitHub Actions)
            break :blk std.process.Child.run(.{
                .allocator = b.allocator,
                .argv = &[_][]const u8{ "bash", "./scripts/download-ffmpeg.sh" },
            }) catch |err| {
                std.log.err("Failed to run download script: {}", .{err});
                std.log.err("Please run manually: bash ./scripts/download-ffmpeg.sh", .{});
                std.process.exit(1);
            };
        } else blk: {
            // On Unix systems, make executable first then run
            _ = std.process.Child.run(.{
                .allocator = b.allocator,
                .argv = &[_][]const u8{ "chmod", "+x", "./scripts/download-ffmpeg.sh" },
            }) catch {};

            break :blk std.process.Child.run(.{
                .allocator = b.allocator,
                .argv = &[_][]const u8{"./scripts/download-ffmpeg.sh"},
            }) catch |err| {
                std.log.err("Failed to run download script: {}", .{err});
                std.log.err("Please run manually: chmod +x ./scripts/download-ffmpeg.sh && ./scripts/download-ffmpeg.sh", .{});
                std.process.exit(1);
            };
        };

        defer b.allocator.free(result.stdout);
        defer b.allocator.free(result.stderr);

        if (result.term.Exited != 0) {
            std.log.err("Download script failed with exit code: {}", .{result.term.Exited});
            if (result.stderr.len > 0) {
                std.log.err("Script error output: {s}", .{result.stderr});
            }
            const manual_cmd = if (builtin.os.tag == .windows)
                "Please run manually: bash ./scripts/download-ffmpeg.sh"
            else
                "Please run manually: chmod +x ./scripts/download-ffmpeg.sh && ./scripts/download-ffmpeg.sh";
            std.log.err("{s}", .{manual_cmd});
            std.process.exit(1);
        }

        std.log.info("FFmpeg binaries downloaded successfully", .{});
    };

    std.log.info("Building with embedded FFmpeg binaries", .{});
}
