const std = @import("std");
const cli = @import("../cli.zig");
const ffmpeg = @import("../ffmpeg.zig");

/// Error types for video generation.
pub const VideoGenError = error{
    FFmpegNotFound,
    FFmpegExecutionFailed,
    FFmpegEncodingFailed,
    OutOfMemory,
};

/// Generates a video file with the specified configuration.
/// This is a convenience wrapper around `generateWithProgress` with progress disabled.
pub fn generate(allocator: std.mem.Allocator, config: cli.VideoConfig) VideoGenError!void {
    return generateWithProgress(allocator, config, false);
}

/// Generates a video file with the specified configuration.
/// If `show_progress` is true, displays progress information during encoding.
pub fn generateWithProgress(allocator: std.mem.Allocator, config: cli.VideoConfig, show_progress: bool) VideoGenError!void {
    std.debug.print("Generating video with parameters:\n", .{});
    std.debug.print("  Resolution: {d}x{d}\n", .{ config.width, config.height });
    std.debug.print("  Duration: {d}s\n", .{config.duration});
    std.debug.print("  FPS: {d}\n", .{config.fps});
    std.debug.print("  Bitrate: {s}\n", .{config.bitrate});
    std.debug.print("  Format: {s}\n", .{config.format});
    std.debug.print("  Codec: {s}\n", .{config.codec});
    std.debug.print("  Output: {s}\n", .{config.output});

    // Create input filter with countdown timer - black background with large white numbers
    const filter = std.fmt.allocPrint(allocator, "color=c=black:size={d}x{d}:duration={d}:rate={d},drawtext=text='%{{eif\\:floor({d}-t)\\:d}}.%{{eif\\:floor((({d}-t)-floor({d}-t))*100)\\:d\\:2}}':fontsize=200:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2", .{ config.width, config.height, config.duration, config.fps, config.duration, config.duration, config.duration }) catch {
        return VideoGenError.OutOfMemory;
    };
    defer allocator.free(filter);

    // Get FFmpeg path (system or embedded)
    const ffmpeg_path = ffmpeg.getFFmpegPath(allocator) catch {
        std.debug.print("Error: Cannot find or extract FFmpeg\n", .{});
        return VideoGenError.FFmpegNotFound;
    };
    defer allocator.free(ffmpeg_path);

    // Build FFmpeg command array
    const cmd_args = [_][]const u8{
        ffmpeg_path,
        "-y", // Overwrite output file
        "-f",
        "lavfi",
        "-i",
        filter,
        "-c:v",
        config.codec,
        "-b:v",
        config.bitrate,
        config.output,
    };

    // Execute FFmpeg command
    if (show_progress) {
        std.debug.print("🎬 Running FFmpeg encoder...\n", .{});
        std.debug.print("⏳ Please wait, encoding {d}s video...\n", .{config.duration});
    }

    // Run FFmpeg
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &cmd_args,
    }) catch {
        std.debug.print("Error executing FFmpeg\n", .{});
        return VideoGenError.FFmpegExecutionFailed;
    };

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    switch (result.term) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("✅ Video generated successfully: {s}\n", .{config.output});
            } else {
                std.debug.print("❌ FFmpeg failed with exit code: {d}\n", .{code});
                if (result.stderr.len > 0) {
                    std.debug.print("Error output: {s}\n", .{result.stderr});
                }
                return VideoGenError.FFmpegEncodingFailed;
            }
        },
        else => {
            std.debug.print("❌ FFmpeg process terminated abnormally\n", .{});
            return VideoGenError.FFmpegEncodingFailed;
        },
    }
}
