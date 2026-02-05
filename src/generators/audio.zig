const std = @import("std");
const cli = @import("../cli.zig");
const ffmpeg = @import("../ffmpeg.zig");

/// Error types for audio generation.
pub const AudioGenError = error{
    FFmpegNotFound,
    FFmpegExecutionFailed,
    FFmpegEncodingFailed,
    OutOfMemory,
};

/// Generates an audio file with the specified configuration.
/// This is a convenience wrapper around `generateWithProgress` with progress disabled.
pub fn generate(allocator: std.mem.Allocator, config: cli.AudioConfig) AudioGenError!void {
    return generateWithProgress(allocator, config, false);
}

/// Generates an audio file with the specified configuration.
/// If `show_progress` is true, displays progress information during encoding.
pub fn generateWithProgress(allocator: std.mem.Allocator, config: cli.AudioConfig, show_progress: bool) AudioGenError!void {
    std.debug.print("Generating audio with parameters:\n", .{});
    std.debug.print("  Duration: {d}s\n", .{config.duration});
    std.debug.print("  Sample rate: {d}Hz\n", .{config.sample_rate});
    std.debug.print("  Bitrate: {s}\n", .{config.bitrate});
    std.debug.print("  Format: {s}\n", .{config.format});
    std.debug.print("  Codec: {s}\n", .{config.codec});
    std.debug.print("  Output: {s}\n", .{config.output});

    // Create test tone filter
    const filter = std.fmt.allocPrint(allocator, "sine=frequency=1000:sample_rate={d}:duration={d}", .{ config.sample_rate, config.duration }) catch {
        return AudioGenError.OutOfMemory;
    };
    defer allocator.free(filter);

    // Sample rate string
    const sample_rate_str = std.fmt.allocPrint(allocator, "{d}", .{config.sample_rate}) catch {
        return AudioGenError.OutOfMemory;
    };
    defer allocator.free(sample_rate_str);

    // Auto-select codec based on format if using default codec
    const codec = if (std.mem.eql(u8, config.codec, "libmp3lame")) blk: {
        if (std.mem.eql(u8, config.format, "aac")) {
            break :blk "aac";
        } else if (std.mem.eql(u8, config.format, "flac")) {
            break :blk "flac";
        } else if (std.mem.eql(u8, config.format, "wav")) {
            break :blk "pcm_s16le";
        } else {
            break :blk config.codec;
        }
    } else config.codec;

    // Get FFmpeg path (system or embedded)
    const ffmpeg_path = ffmpeg.getFFmpegPath(allocator) catch {
        std.debug.print("Error: Cannot find or extract FFmpeg\n", .{});
        return AudioGenError.FFmpegNotFound;
    };
    defer allocator.free(ffmpeg_path);

    // Build FFmpeg command array
    var cmd_args: []const []const u8 = undefined;

    if (std.mem.eql(u8, config.format, "wav")) {
        // WAV doesn't need bitrate
        cmd_args = &[_][]const u8{
            ffmpeg_path,
            "-y", // Overwrite output file
            "-f",
            "lavfi",
            "-i",
            filter,
            "-c:a",
            codec,
            "-ar",
            sample_rate_str,
            config.output,
        };
    } else {
        // Other formats need bitrate
        cmd_args = &[_][]const u8{
            ffmpeg_path,
            "-y", // Overwrite output file
            "-f",
            "lavfi",
            "-i",
            filter,
            "-c:a",
            codec,
            "-b:a",
            config.bitrate,
            "-ar",
            sample_rate_str,
            config.output,
        };
    }

    // Execute FFmpeg command
    if (show_progress) {
        std.debug.print("🎵 Running FFmpeg encoder...\n", .{});
        std.debug.print("⏳ Please wait, encoding {d}s audio...\n", .{config.duration});
    }

    // Run FFmpeg
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = cmd_args,
    }) catch {
        std.debug.print("Error executing FFmpeg\n", .{});
        return AudioGenError.FFmpegExecutionFailed;
    };

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    switch (result.term) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("✅ Audio generated successfully: {s}\n", .{config.output});
            } else {
                std.debug.print("❌ FFmpeg failed with exit code: {d}\n", .{code});
                if (result.stderr.len > 0) {
                    std.debug.print("Error output: {s}\n", .{result.stderr});
                }
                return AudioGenError.FFmpegEncodingFailed;
            }
        },
        else => {
            std.debug.print("❌ FFmpeg process terminated abnormally\n", .{});
            return AudioGenError.FFmpegEncodingFailed;
        },
    }
}
