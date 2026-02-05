const std = @import("std");
const builtin = @import("builtin");

// Build option to control FFmpeg embedding
const embed_ffmpeg = @import("build_options").embed_ffmpeg;

// Conditionally embed FFmpeg binaries based on build option
const ffmpeg_linux_x64 = if (embed_ffmpeg) @embedFile("vendor/ffmpeg/linux-x64/ffmpeg") else "";
const ffmpeg_windows_x64 = if (embed_ffmpeg) @embedFile("vendor/ffmpeg/windows-x64/ffmpeg.exe") else "";
const ffmpeg_macos_x64 = if (embed_ffmpeg) @embedFile("vendor/ffmpeg/macos-x64/ffmpeg") else "";
const ffmpeg_macos_arm64 = if (embed_ffmpeg) @embedFile("vendor/ffmpeg/macos-arm64/ffmpeg") else "";

/// Returns whether FFmpeg is embedded in this build
pub fn isEmbedded() bool {
    return embed_ffmpeg;
}

/// Extract embedded FFmpeg to a temporary location
/// Returns error if FFmpeg is not embedded in this build
pub fn extractFFmpeg(allocator: std.mem.Allocator) ![]const u8 {
    if (!embed_ffmpeg) {
        return error.FFmpegNotEmbedded;
    }

    // Create temp directory
    std.fs.cwd().makeDir("temp") catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ffmpeg_binary = switch (builtin.target.os.tag) {
        .linux => switch (builtin.target.cpu.arch) {
            .x86_64 => ffmpeg_linux_x64,
            else => return error.UnsupportedPlatform,
        },
        .windows => switch (builtin.target.cpu.arch) {
            .x86_64 => ffmpeg_windows_x64,
            else => return error.UnsupportedPlatform,
        },
        .macos => switch (builtin.target.cpu.arch) {
            .x86_64 => ffmpeg_macos_x64,
            .aarch64 => ffmpeg_macos_arm64,
            else => return error.UnsupportedPlatform,
        },
        else => return error.UnsupportedPlatform,
    };

    const filename = if (builtin.target.os.tag == .windows) "ffmpeg.exe" else "ffmpeg";
    const ffmpeg_path = try std.fmt.allocPrint(allocator, "temp/{s}", .{filename});

    const file = try std.fs.cwd().createFile(ffmpeg_path, .{ .mode = 0o755 });
    defer file.close();

    try file.writeAll(ffmpeg_binary);

    return ffmpeg_path;
}

/// Get FFmpeg path - for bundled edition, uses embedded FFmpeg; for standalone, uses system FFmpeg
pub fn getFFmpegPath(allocator: std.mem.Allocator) ![]const u8 {
    // For bundled edition, prioritize embedded FFmpeg for consistency
    if (embed_ffmpeg) {
        return extractFFmpeg(allocator);
    }

    // For standalone edition, use system FFmpeg
    if (findSystemFFmpeg(allocator)) |path| {
        return path;
    }

    // No FFmpeg available
    return error.FFmpegNotFound;
}

/// Find system-installed FFmpeg
fn findSystemFFmpeg(allocator: std.mem.Allocator) ?[]const u8 {
    // Check if FFmpeg is available in system
    const which_cmd = if (builtin.target.os.tag == .windows) "where" else "which";

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ which_cmd, "ffmpeg" },
    }) catch return null;

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited == 0 and result.stdout.len > 0) {
        const trimmed = std.mem.trim(u8, result.stdout, " \n\r\t");
        // On Windows, 'where' might return multiple lines, take the first one
        const first_line = if (std.mem.indexOf(u8, trimmed, "\n")) |idx| trimmed[0..idx] else trimmed;
        return allocator.dupe(u8, first_line) catch null;
    }

    return null;
}

/// Check if FFmpeg has a specific filter available
pub fn hasFilter(allocator: std.mem.Allocator, filter_name: []const u8) bool {
    const ffmpeg_path = getFFmpegPath(allocator) catch return false;
    defer allocator.free(ffmpeg_path);

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ ffmpeg_path, "-filters" },
    }) catch return false;

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    // Check in both stdout and stderr as FFmpeg might output to either
    if (std.mem.indexOf(u8, result.stdout, filter_name) != null) {
        return true;
    }
    if (std.mem.indexOf(u8, result.stderr, filter_name) != null) {
        return true;
    }

    return false;
}

/// Get build info string
pub fn getBuildInfo() []const u8 {
    if (embed_ffmpeg) {
        return "Bundled Edition (FFmpeg embedded)";
    } else {
        return "Standalone Edition (requires system FFmpeg)";
    }
}
