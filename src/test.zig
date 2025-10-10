const std = @import("std");
const testing = std.testing;
const cli = @import("cli.zig");

test "VideoConfig default values" {
    const config = cli.VideoConfig{};

    try testing.expect(config.width == 1920);
    try testing.expect(config.height == 1080);
    try testing.expect(config.duration == 30);
    try testing.expect(config.fps == 30);
    try testing.expectEqualStrings(config.bitrate, "1000k");
    try testing.expectEqualStrings(config.format, "mp4");
    try testing.expectEqualStrings(config.codec, "libx264");
    try testing.expectEqualStrings(config.output, "output.mp4");
}

test "AudioConfig default values" {
    const config = cli.AudioConfig{};

    try testing.expect(config.duration == 30);
    try testing.expect(config.sample_rate == 44100);
    try testing.expectEqualStrings(config.bitrate, "128k");
    try testing.expectEqualStrings(config.format, "mp3");
    try testing.expectEqualStrings(config.codec, "libmp3lame");
    try testing.expectEqualStrings(config.output, "output.mp3");
}

test "MediaType enum values" {
    try testing.expect(cli.MediaType.video != cli.MediaType.audio);
}

test "VideoConfig custom values" {
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

    try testing.expect(config.width == 1280);
    try testing.expect(config.height == 720);
    try testing.expect(config.duration == 60);
    try testing.expect(config.fps == 25);
    try testing.expectEqualStrings(config.bitrate, "2000k");
    try testing.expectEqualStrings(config.format, "avi");
    try testing.expectEqualStrings(config.codec, "libx265");
    try testing.expectEqualStrings(config.output, "test.avi");
}

test "AudioConfig custom values" {
    const config = cli.AudioConfig{
        .duration = 120,
        .sample_rate = 48000,
        .bitrate = "320k",
        .format = "wav",
        .codec = "pcm_s16le",
        .output = "test.wav",
    };

    try testing.expect(config.duration == 120);
    try testing.expect(config.sample_rate == 48000);
    try testing.expectEqualStrings(config.bitrate, "320k");
    try testing.expectEqualStrings(config.format, "wav");
    try testing.expectEqualStrings(config.codec, "pcm_s16le");
    try testing.expectEqualStrings(config.output, "test.wav");
}

test "VideoConfig edge cases" {
    const config = cli.VideoConfig{
        .width = 0,
        .height = 0,
        .duration = 0,
        .fps = 0,
    };

    try testing.expect(config.width == 0);
    try testing.expect(config.height == 0);
    try testing.expect(config.duration == 0);
    try testing.expect(config.fps == 0);
}

test "AudioConfig edge cases" {
    const config = cli.AudioConfig{
        .duration = 0,
        .sample_rate = 0,
    };

    try testing.expect(config.duration == 0);
    try testing.expect(config.sample_rate == 0);
}

test "VideoConfig large values" {
    const config = cli.VideoConfig{
        .width = 7680,
        .height = 4320,
        .duration = 3600,
        .fps = 120,
    };

    try testing.expect(config.width == 7680);
    try testing.expect(config.height == 4320);
    try testing.expect(config.duration == 3600);
    try testing.expect(config.fps == 120);
}

test "AudioConfig high sample rate" {
    const config = cli.AudioConfig{
        .sample_rate = 192000,
        .duration = 7200,
    };

    try testing.expect(config.sample_rate == 192000);
    try testing.expect(config.duration == 7200);
}
