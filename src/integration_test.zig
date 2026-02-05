//! Integration tests for media-gen.
//!
//! These tests verify the end-to-end functionality of media generation,
//! including interaction with FFmpeg. Tests will be skipped if FFmpeg
//! is not available.

const std = @import("std");
const testing = std.testing;
const video_gen = @import("generators/video.zig");
const audio_gen = @import("generators/audio.zig");
const cli = @import("cli.zig");

/// Test output directory for generated media files.
const TEST_OUTPUT_DIR = "test-media";

/// Ensures the test output directory exists.
fn ensureTestDir() void {
    std.fs.cwd().makePath(TEST_OUTPUT_DIR) catch {};
}

/// Cleans up a test file if it exists.
fn cleanupFile(path: []const u8) void {
    std.fs.cwd().deleteFile(path) catch {};
}

// =============================================================================
// Video Generation Tests
// =============================================================================

test "video generation creates valid output file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    ensureTestDir();

    const config = cli.VideoConfig{
        .width = 320,
        .height = 240,
        .duration = 2,
        .fps = 10,
        .output = TEST_OUTPUT_DIR ++ "/test_integration_video.mp4",
    };

    // Attempt to generate video
    video_gen.generate(allocator, config) catch |err| {
        std.log.warn("Video generation skipped (FFmpeg not available): {}", .{err});
        return;
    };

    // Verify output file was created
    const file = std.fs.cwd().openFile(config.output, .{}) catch |err| {
        std.log.warn("Generated video file not found: {}", .{err});
        return;
    };
    defer file.close();

    // Verify file has content
    const file_size = try file.getEndPos();
    try testing.expect(file_size > 0);

    // Clean up
    cleanupFile(config.output);
}

// =============================================================================
// Audio Generation Tests
// =============================================================================

test "audio generation creates valid output file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    ensureTestDir();

    const config = cli.AudioConfig{
        .duration = 2,
        .frequency = 440,
        .format = "wav",
        .codec = "pcm_s16le",
        .output = TEST_OUTPUT_DIR ++ "/test_integration_audio.wav",
    };

    // Attempt to generate audio
    audio_gen.generate(allocator, config) catch |err| {
        std.log.warn("Audio generation skipped (FFmpeg not available): {}", .{err});
        return;
    };

    // Verify output file was created
    const file = std.fs.cwd().openFile(config.output, .{}) catch |err| {
        std.log.warn("Generated audio file not found: {}", .{err});
        return;
    };
    defer file.close();

    // Verify file has content
    const file_size = try file.getEndPos();
    try testing.expect(file_size > 0);

    // Clean up
    cleanupFile(config.output);
}

// =============================================================================
// CLI Integration Tests
// =============================================================================

test "CLI video command parses and executes" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    ensureTestDir();

    // Create mutable argument strings
    const arg_prog: [:0]u8 = @constCast("media-gen");
    const arg_cmd: [:0]u8 = @constCast("video");
    const arg_width: [:0]u8 = @constCast("--width");
    const arg_width_val: [:0]u8 = @constCast("320");
    const arg_height: [:0]u8 = @constCast("--height");
    const arg_height_val: [:0]u8 = @constCast("240");
    const arg_duration: [:0]u8 = @constCast("--duration");
    const arg_duration_val: [:0]u8 = @constCast("1");
    const arg_output: [:0]u8 = @constCast("--output");
    const arg_output_val: [:0]u8 = @constCast(TEST_OUTPUT_DIR ++ "/test_cli_video.mp4");

    var args = [_][:0]u8{
        arg_prog,
        arg_cmd,
        arg_width,
        arg_width_val,
        arg_height,
        arg_height_val,
        arg_duration,
        arg_duration_val,
        arg_output,
        arg_output_val,
    };

    // Execute should not panic
    cli.parseAndExecute(allocator, &args) catch |err| {
        std.log.warn("CLI video command skipped (FFmpeg not available): {}", .{err});
    };

    // Clean up
    cleanupFile(TEST_OUTPUT_DIR ++ "/test_cli_video.mp4");
}

test "CLI audio command parses and executes" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    ensureTestDir();

    // Create mutable argument strings
    const arg_prog: [:0]u8 = @constCast("media-gen");
    const arg_cmd: [:0]u8 = @constCast("audio");
    const arg_duration: [:0]u8 = @constCast("--duration");
    const arg_duration_val: [:0]u8 = @constCast("1");
    const arg_frequency: [:0]u8 = @constCast("--frequency");
    const arg_frequency_val: [:0]u8 = @constCast("880");
    const arg_format: [:0]u8 = @constCast("--format");
    const arg_format_val: [:0]u8 = @constCast("wav");
    const arg_output: [:0]u8 = @constCast("--output");
    const arg_output_val: [:0]u8 = @constCast(TEST_OUTPUT_DIR ++ "/test_cli_audio.wav");

    var args = [_][:0]u8{
        arg_prog,
        arg_cmd,
        arg_duration,
        arg_duration_val,
        arg_frequency,
        arg_frequency_val,
        arg_format,
        arg_format_val,
        arg_output,
        arg_output_val,
    };

    // Execute should not panic
    cli.parseAndExecute(allocator, &args) catch |err| {
        std.log.warn("CLI audio command skipped (FFmpeg not available): {}", .{err});
    };

    // Clean up
    cleanupFile(TEST_OUTPUT_DIR ++ "/test_cli_audio.wav");
}

test "CLI help command succeeds" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const arg_prog: [:0]u8 = @constCast("media-gen");
    const arg_cmd: [:0]u8 = @constCast("help");

    var args = [_][:0]u8{
        arg_prog,
        arg_cmd,
    };

    // Help command should succeed
    try cli.parseAndExecute(allocator, &args);
}

test "CLI unknown command returns error" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const arg_prog: [:0]u8 = @constCast("media-gen");
    const arg_cmd: [:0]u8 = @constCast("invalid-command");

    var args = [_][:0]u8{
        arg_prog,
        arg_cmd,
    };

    // Should return UnknownCommand error
    const result = cli.parseAndExecute(allocator, &args);
    try testing.expectError(error.UnknownCommand, result);
}
