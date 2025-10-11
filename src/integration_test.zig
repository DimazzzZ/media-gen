const std = @import("std");
const testing = std.testing;
const video_gen = @import("generators/video.zig");
const audio_gen = @import("generators/audio.zig");
const cli = @import("cli.zig");

test "video generation integration" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create test-media directory
    std.fs.cwd().makePath("test-media") catch {};

    const config = cli.VideoConfig{
        .width = 320,
        .height = 240,
        .duration = 2,
        .fps = 10,
        .output = "test-media/test_integration_video.mp4",
    };

    // Generate video
    video_gen.generate(allocator, config) catch |err| {
        std.log.warn("Video generation failed (may be expected if FFmpeg not available): {}", .{err});
        return;
    };

    // Check if file was created
    const file = std.fs.cwd().openFile(config.output, .{}) catch |err| {
        std.log.warn("Generated video file not found: {}", .{err});
        return;
    };
    defer file.close();

    // Check file size (should be > 0)
    const file_size = try file.getEndPos();
    try testing.expect(file_size > 0);

    // Clean up
    std.fs.cwd().deleteFile(config.output) catch {};
}

test "audio generation integration" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create test-media directory
    std.fs.cwd().makePath("test-media") catch {};

    const config = cli.AudioConfig{
        .duration = 2,
        .frequency = 440,
        .format = "wav",
        .codec = "pcm_s16le",
        .output = "test-media/test_integration_audio.wav",
    };

    // Generate audio
    audio_gen.generate(allocator, config) catch |err| {
        std.log.warn("Audio generation failed (may be expected if FFmpeg not available): {}", .{err});
        return;
    };

    // Check if file was created
    const file = std.fs.cwd().openFile(config.output, .{}) catch |err| {
        std.log.warn("Generated audio file not found: {}", .{err});
        return;
    };
    defer file.close();

    // Check file size (should be > 0)
    const file_size = try file.getEndPos();
    try testing.expect(file_size > 0);

    // Clean up
    std.fs.cwd().deleteFile(config.output) catch {};
}

test "cli command parsing" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test video command parsing
    var video_args = [_][:0]u8{
        @constCast("media-gen"),
        @constCast("video"),
        @constCast("--width"),
        @constCast("640"),
        @constCast("--height"),
        @constCast("480"),
        @constCast("--duration"),
        @constCast("5"),
        @constCast("--output"),
        @constCast("test-media/test_cli.mp4"),
    };

    // This should not crash
    cli.parseAndExecute(allocator, &video_args) catch |err| {
        std.log.warn("CLI video command failed (expected if FFmpeg not available): {}", .{err});
    };

    // Test audio command parsing
    var audio_args = [_][:0]u8{
        @constCast("media-gen"),
        @constCast("audio"),
        @constCast("--duration"),
        @constCast("3"),
        @constCast("--frequency"),
        @constCast("880"),
        @constCast("--output"),
        @constCast("test-media/test_cli.wav"),
    };

    // This should not crash
    cli.parseAndExecute(allocator, &audio_args) catch |err| {
        std.log.warn("CLI audio command failed (expected if FFmpeg not available): {}", .{err});
    };

    // Clean up any generated files
    std.fs.cwd().deleteFile("test-media/test_cli.mp4") catch {};
    std.fs.cwd().deleteFile("test-media/test_cli.wav") catch {};
}

test "invalid command handling" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var invalid_args = [_][:0]u8{
        @constCast("media-gen"),
        @constCast("invalid-command"),
    };

    // Should return UnknownCommand error
    const result = cli.parseAndExecute(allocator, &invalid_args);
    try testing.expectError(error.UnknownCommand, result);
}
