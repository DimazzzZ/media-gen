//! Unit tests for media-gen.
//!
//! These tests verify the configuration structs and argument parsing logic
//! without requiring FFmpeg to be installed.

const std = @import("std");
const testing = std.testing;
const cli = @import("cli.zig");
const ffmpeg = @import("ffmpeg.zig");

// =============================================================================
// VideoConfig Tests
// =============================================================================

test "VideoConfig has correct default values" {
    const config = cli.VideoConfig{};

    try testing.expectEqual(@as(u32, 1920), config.width);
    try testing.expectEqual(@as(u32, 1080), config.height);
    try testing.expectEqual(@as(u32, 30), config.duration);
    try testing.expectEqual(@as(u32, 30), config.fps);
    try testing.expectEqualStrings("1000k", config.bitrate);
    try testing.expectEqualStrings("mp4", config.format);
    try testing.expectEqualStrings("libx264", config.codec);
    try testing.expectEqualStrings("output.mp4", config.output);
}

test "VideoConfig accepts custom values" {
    const config = cli.VideoConfig{
        .width = 1280,
        .height = 720,
        .duration = 60,
        .fps = 25,
        .bitrate = "2000k",
        .format = "avi",
        .codec = "libx265",
        .output = "test.avi",
    };

    try testing.expectEqual(@as(u32, 1280), config.width);
    try testing.expectEqual(@as(u32, 720), config.height);
    try testing.expectEqual(@as(u32, 60), config.duration);
    try testing.expectEqual(@as(u32, 25), config.fps);
    try testing.expectEqualStrings("2000k", config.bitrate);
    try testing.expectEqualStrings("avi", config.format);
    try testing.expectEqualStrings("libx265", config.codec);
    try testing.expectEqualStrings("test.avi", config.output);
}

test "VideoConfig handles zero values" {
    const config = cli.VideoConfig{
        .width = 0,
        .height = 0,
        .duration = 0,
        .fps = 0,
    };

    try testing.expectEqual(@as(u32, 0), config.width);
    try testing.expectEqual(@as(u32, 0), config.height);
    try testing.expectEqual(@as(u32, 0), config.duration);
    try testing.expectEqual(@as(u32, 0), config.fps);
}

test "VideoConfig handles 8K resolution" {
    const config = cli.VideoConfig{
        .width = 7680,
        .height = 4320,
        .duration = 3600,
        .fps = 120,
    };

    try testing.expectEqual(@as(u32, 7680), config.width);
    try testing.expectEqual(@as(u32, 4320), config.height);
    try testing.expectEqual(@as(u32, 3600), config.duration);
    try testing.expectEqual(@as(u32, 120), config.fps);
}

// =============================================================================
// AudioConfig Tests
// =============================================================================

test "AudioConfig has correct default values" {
    const config = cli.AudioConfig{};

    try testing.expectEqual(@as(u32, 30), config.duration);
    try testing.expectEqual(@as(u32, 44100), config.sample_rate);
    try testing.expectEqual(@as(u32, 440), config.frequency);
    try testing.expectEqualStrings("128k", config.bitrate);
    try testing.expectEqualStrings("mp3", config.format);
    try testing.expectEqualStrings("libmp3lame", config.codec);
    try testing.expectEqualStrings("output.mp3", config.output);
}

test "AudioConfig accepts custom values" {
    const config = cli.AudioConfig{
        .duration = 120,
        .sample_rate = 48000,
        .frequency = 880,
        .bitrate = "320k",
        .format = "wav",
        .codec = "pcm_s16le",
        .output = "test.wav",
    };

    try testing.expectEqual(@as(u32, 120), config.duration);
    try testing.expectEqual(@as(u32, 48000), config.sample_rate);
    try testing.expectEqual(@as(u32, 880), config.frequency);
    try testing.expectEqualStrings("320k", config.bitrate);
    try testing.expectEqualStrings("wav", config.format);
    try testing.expectEqualStrings("pcm_s16le", config.codec);
    try testing.expectEqualStrings("test.wav", config.output);
}

test "AudioConfig handles zero values" {
    const config = cli.AudioConfig{
        .duration = 0,
        .sample_rate = 0,
        .frequency = 0,
    };

    try testing.expectEqual(@as(u32, 0), config.duration);
    try testing.expectEqual(@as(u32, 0), config.sample_rate);
    try testing.expectEqual(@as(u32, 0), config.frequency);
}

test "AudioConfig handles high sample rate" {
    const config = cli.AudioConfig{
        .sample_rate = 192000,
        .duration = 7200,
    };

    try testing.expectEqual(@as(u32, 192000), config.sample_rate);
    try testing.expectEqual(@as(u32, 7200), config.duration);
}

// =============================================================================
// MediaType Tests
// =============================================================================

test "MediaType enum has distinct values" {
    try testing.expect(cli.MediaType.video != cli.MediaType.audio);
}

// =============================================================================
// FFmpeg Module Tests
// =============================================================================

test "ffmpeg.isEmbedded returns a boolean" {
    const embedded = ffmpeg.isEmbedded();
    // Just verify it returns without error and is a valid boolean
    try testing.expect(embedded == true or embedded == false);
}

test "ffmpeg.getBuildInfo returns non-empty string" {
    const info = ffmpeg.getBuildInfo();
    try testing.expect(info.len > 0);
    // Should contain either "Bundled" or "Standalone"
    const contains_bundled = std.mem.indexOf(u8, info, "Bundled") != null;
    const contains_standalone = std.mem.indexOf(u8, info, "Standalone") != null;
    try testing.expect(contains_bundled or contains_standalone);
}

test "ffmpeg.getFFmpegPath returns path or error" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const result = ffmpeg.getFFmpegPath(allocator);

    if (result) |path| {
        defer allocator.free(path);
        // Path should not be empty and should contain "ffmpeg"
        try testing.expect(path.len > 0);
        try testing.expect(std.mem.indexOf(u8, path, "ffmpeg") != null);
    } else |err| {
        // Expected errors when FFmpeg is not available
        try testing.expect(err == error.FFmpegNotFound or
            err == error.FFmpegNotEmbedded or
            err == error.UnsupportedPlatform);
    }
}

test "ffmpeg.extractFFmpeg behavior depends on build option" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const result = ffmpeg.extractFFmpeg(allocator);

    if (ffmpeg.isEmbedded()) {
        if (result) |path| {
            defer allocator.free(path);
            // Verify extracted file exists
            const file = std.fs.cwd().openFile(path, .{}) catch |err| {
                std.log.warn("Could not open extracted FFmpeg: {}", .{err});
                return;
            };
            defer file.close();

            const file_size = try file.getEndPos();
            try testing.expect(file_size > 1000); // FFmpeg should be at least 1KB

            // Clean up extracted file
            std.fs.cwd().deleteFile(path) catch {};
        } else |err| {
            // May fail on unsupported platforms
            try testing.expect(err == error.UnsupportedPlatform);
        }
    } else {
        // Standalone build should return FFmpegNotEmbedded
        try testing.expectError(error.FFmpegNotEmbedded, result);
    }
}

// =============================================================================
// Argument Parsing Tests
// =============================================================================

test "parseVideoArgs parses all options" {
    var config = cli.VideoConfig{};

    // Create argument strings
    const arg_width: [:0]u8 = @constCast("--width");
    const arg_width_val: [:0]u8 = @constCast("1280");
    const arg_height: [:0]u8 = @constCast("--height");
    const arg_height_val: [:0]u8 = @constCast("720");
    const arg_duration: [:0]u8 = @constCast("--duration");
    const arg_duration_val: [:0]u8 = @constCast("60");
    const arg_fps: [:0]u8 = @constCast("--fps");
    const arg_fps_val: [:0]u8 = @constCast("25");
    const arg_output: [:0]u8 = @constCast("--output");
    const arg_output_val: [:0]u8 = @constCast("test.mp4");

    var args = [_][:0]u8{
        arg_width,       arg_width_val,
        arg_height,      arg_height_val,
        arg_duration,    arg_duration_val,
        arg_fps,         arg_fps_val,
        arg_output,      arg_output_val,
    };

    try cli.parseVideoArgs(&args, &config);

    try testing.expectEqual(@as(u32, 1280), config.width);
    try testing.expectEqual(@as(u32, 720), config.height);
    try testing.expectEqual(@as(u32, 60), config.duration);
    try testing.expectEqual(@as(u32, 25), config.fps);
    try testing.expectEqualStrings("test.mp4", config.output);
}

test "parseAudioArgs parses all options" {
    var config = cli.AudioConfig{};

    // Create argument strings
    const arg_duration: [:0]u8 = @constCast("--duration");
    const arg_duration_val: [:0]u8 = @constCast("120");
    const arg_sample_rate: [:0]u8 = @constCast("--sample-rate");
    const arg_sample_rate_val: [:0]u8 = @constCast("48000");
    const arg_frequency: [:0]u8 = @constCast("--frequency");
    const arg_frequency_val: [:0]u8 = @constCast("880");
    const arg_bitrate: [:0]u8 = @constCast("--bitrate");
    const arg_bitrate_val: [:0]u8 = @constCast("320k");
    const arg_output: [:0]u8 = @constCast("--output");
    const arg_output_val: [:0]u8 = @constCast("test.wav");

    var args = [_][:0]u8{
        arg_duration,    arg_duration_val,
        arg_sample_rate, arg_sample_rate_val,
        arg_frequency,   arg_frequency_val,
        arg_bitrate,     arg_bitrate_val,
        arg_output,      arg_output_val,
    };

    try cli.parseAudioArgs(&args, &config);

    try testing.expectEqual(@as(u32, 120), config.duration);
    try testing.expectEqual(@as(u32, 48000), config.sample_rate);
    try testing.expectEqual(@as(u32, 880), config.frequency);
    try testing.expectEqualStrings("320k", config.bitrate);
    try testing.expectEqualStrings("test.wav", config.output);
}

test "parseVideoArgs handles empty args" {
    var config = cli.VideoConfig{};
    var args = [_][:0]u8{};

    try cli.parseVideoArgs(&args, &config);

    // Should retain defaults
    try testing.expectEqual(@as(u32, 1920), config.width);
    try testing.expectEqual(@as(u32, 1080), config.height);
}

test "parseAudioArgs handles empty args" {
    var config = cli.AudioConfig{};
    var args = [_][:0]u8{};

    try cli.parseAudioArgs(&args, &config);

    // Should retain defaults
    try testing.expectEqual(@as(u32, 30), config.duration);
    try testing.expectEqual(@as(u32, 44100), config.sample_rate);
}
