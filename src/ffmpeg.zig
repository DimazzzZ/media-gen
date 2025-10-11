const std = @import("std");
const builtin = @import("builtin");

// Embedded FFmpeg binaries for different platforms
const ffmpeg_linux_x64 = @embedFile("vendor/ffmpeg/linux-x64/ffmpeg");
const ffmpeg_windows_x64 = @embedFile("vendor/ffmpeg/windows-x64/ffmpeg.exe");
const ffmpeg_macos_x64 = @embedFile("vendor/ffmpeg/macos-x64/ffmpeg");
const ffmpeg_macos_arm64 = @embedFile("vendor/ffmpeg/macos-arm64/ffmpeg");

pub fn extractFFmpeg(allocator: std.mem.Allocator) ![]const u8 {
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

pub fn getFFmpegPath(allocator: std.mem.Allocator) ![]const u8 {
    // First check for system FFmpeg
    if (findSystemFFmpeg(allocator)) |path| {
        return path;
    }

    // If system FFmpeg not found, extract embedded
    return extractFFmpeg(allocator);
}

fn findSystemFFmpeg(allocator: std.mem.Allocator) ?[]const u8 {
    // Check if FFmpeg is available in system
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "which", "ffmpeg" },
    }) catch return null;

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited == 0 and result.stdout.len > 0) {
        const trimmed = std.mem.trim(u8, result.stdout, " \n\r\t");
        return allocator.dupe(u8, trimmed) catch null;
    }

    return null;
}
