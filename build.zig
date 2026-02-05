//! Build configuration for media-gen.
//!
//! This build script supports two editions:
//! - Bundled Edition (default): FFmpeg binaries are embedded in the executable
//! - Standalone Edition: Requires system-installed FFmpeg
//!
//! Build options:
//! - `-Dno-embed-ffmpeg=true`: Build standalone edition without embedded FFmpeg

const std = @import("std");

/// Main build function called by the Zig build system.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build option: -Dno-embed-ffmpeg=true to build without embedded FFmpeg
    const no_embed_ffmpeg = b.option(bool, "no-embed-ffmpeg", "Build without embedded FFmpeg (standalone edition)") orelse false;
    const embed_ffmpeg = !no_embed_ffmpeg;

    // Create build options module
    const build_options = b.addOptions();
    build_options.addOption(bool, "embed_ffmpeg", embed_ffmpeg);

    // Create root module
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add build options as import
    root_module.addImport("build_options", build_options.createModule());

    const exe = b.addExecutable(.{
        .name = if (embed_ffmpeg) "media-gen" else "media-gen-standalone",
        .root_module = root_module,
    });

    // Link system libraries
    exe.linkLibC();

    // Only download/setup FFmpeg binaries if embedding
    if (embed_ffmpeg) {
        setupEmbeddedFFmpegBuild(b);
    } else {
        std.log.info("Building standalone edition (no embedded FFmpeg)", .{});
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
    const integration_test_step = b.step("test-integration", "Run integration tests");

    // Unit tests
    const test_module = b.createModule(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_module.addImport("build_options", build_options.createModule());

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
    integration_test_module.addImport("build_options", build_options.createModule());

    const integration_test_exe = b.addTest(.{
        .root_module = integration_test_module,
    });

    const run_integration_test = b.addRunArtifact(integration_test_exe);
    integration_test_step.dependOn(&run_integration_test.step);
}

/// Sets up the build for embedded FFmpeg.
/// Downloads FFmpeg binaries if they don't exist in the vendor directory.
fn setupEmbeddedFFmpegBuild(b: *std.Build) void {
    const vendor_dir = "src/vendor/ffmpeg";
    std.fs.cwd().access(vendor_dir, .{}) catch {
        std.log.info("FFmpeg binaries not found, downloading...", .{});

        // Detect platform and run appropriate command
        const builtin = @import("builtin");
        const result = if (builtin.os.tag == .windows) blk: {
            // On Windows, use PowerShell for faster execution
            break :blk std.process.Child.run(.{
                .allocator = b.allocator,
                .argv = &[_][]const u8{ "powershell", "-ExecutionPolicy", "Bypass", "-File", "./scripts/download-ffmpeg-windows.ps1" },
            }) catch |err| {
                // Fallback to bash if PowerShell fails
                std.log.warn("PowerShell script failed, trying bash fallback: {}", .{err});
                break :blk std.process.Child.run(.{
                    .allocator = b.allocator,
                    .argv = &[_][]const u8{ "bash", "./scripts/download-ffmpeg.sh" },
                }) catch |bash_err| {
                    std.log.err("Both PowerShell and bash failed: {}", .{bash_err});
                    std.log.err("Please run manually: powershell -File ./scripts/download-ffmpeg-windows.ps1", .{});
                    std.process.exit(1);
                };
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
                "Please run manually: powershell -File ./scripts/download-ffmpeg-windows.ps1"
            else
                "Please run manually: chmod +x ./scripts/download-ffmpeg.sh && ./scripts/download-ffmpeg.sh";
            std.log.err("{s}", .{manual_cmd});
            std.process.exit(1);
        }

        std.log.info("FFmpeg binaries downloaded successfully", .{});
    };

    std.log.info("Building bundled edition with embedded FFmpeg binaries", .{});
}
