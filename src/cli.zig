const std = @import("std");
const print = std.debug.print;
const video_gen = @import("generators/video.zig");
const audio_gen = @import("generators/audio.zig");

pub const MediaType = enum {
    video,
    audio,
};

pub const VideoConfig = struct {
    width: u32 = 1920,
    height: u32 = 1080,
    duration: u32 = 30, // seconds
    fps: u32 = 30,
    bitrate: []const u8 = "1000k",
    format: []const u8 = "mp4",
    codec: []const u8 = "libx264",
    output: []const u8 = "output.mp4",
};

pub const AudioConfig = struct {
    duration: u32 = 30, // seconds
    sample_rate: u32 = 44100,
    bitrate: []const u8 = "128k",
    format: []const u8 = "mp3",
    codec: []const u8 = "libmp3lame",
    frequency: u32 = 440, // Hz for sine wave
    output: []const u8 = "output.mp3",
};

pub fn printHelp() !void {
    print("Media Generator - Embedded FFmpeg Edition\n", .{});
    print("Usage: media-gen <command> [options]\n\n", .{});
    print("Commands:\n", .{});
    print("  video        Generate video file with countdown timer\n", .{});
    print("  audio        Generate audio file with test tones\n", .{});
    print("  i, interactive  Interactive mode - guided setup\n", .{});
    print("  help         Show this help message\n\n", .{});
    print("Video options:\n", .{});
    print("  --width <width>        Video width (default: 1920)\n", .{});
    print("  --height <height>      Video height (default: 1080)\n", .{});
    print("  --duration <seconds>   Duration in seconds (default: 30)\n", .{});
    print("  --fps <fps>           Frames per second (default: 30)\n", .{});
    print("  --bitrate <bitrate>   Video bitrate (default: 1000k)\n", .{});
    print("  --format <format>     Output format (mp4, avi, mov, mkv)\n", .{});
    print("  --codec <codec>       Video codec (libx264, libx265, libvpx-vp9)\n", .{});
    print("  --output <filename>   Output filename (default: output.mp4)\n\n", .{});
    print("Audio options:\n", .{});
    print("  --duration <seconds>   Duration in seconds (default: 30)\n", .{});
    print("  --sample-rate <rate>   Sample rate (default: 44100)\n", .{});
    print("  --frequency <hz>      Sine wave frequency (default: 440)\n", .{});
    print("  --bitrate <bitrate>   Audio bitrate (default: 128k)\n", .{});
    print("  --format <format>     Output format (mp3, wav, aac, flac)\n", .{});
    print("  --codec <codec>       Audio codec (libmp3lame, pcm_s16le, aac)\n", .{});
    print("  --output <filename>   Output filename (default: output.mp3)\n\n", .{});
    print("Examples:\n", .{});
    print("  media-gen video --width 1280 --height 720 --duration 60 --output test.mp4\n", .{});
    print("  media-gen audio --bitrate 320k --duration 120 --format wav --output test.wav\n", .{});
    print("  media-gen audio --frequency 880 --sample-rate 48000 --output tone.wav\n", .{});
    print("\nNote: FFmpeg is embedded - no external installation required!\n", .{});
}

pub fn parseAndExecute(allocator: std.mem.Allocator, args: [][:0]u8) !void {
    if (std.mem.eql(u8, args[1], "help")) {
        try printHelp();
        return;
    }

    if (std.mem.eql(u8, args[1], "i") or std.mem.eql(u8, args[1], "interactive")) {
        const interactive = @import("interactive.zig");
        try interactive.run(allocator);
        return;
    }

    if (std.mem.eql(u8, args[1], "video")) {
        var config = VideoConfig{};
        try parseVideoArgs(args[2..], &config);
        try video_gen.generate(allocator, config);
    } else if (std.mem.eql(u8, args[1], "audio")) {
        var config = AudioConfig{};
        try parseAudioArgs(args[2..], &config);
        try audio_gen.generate(allocator, config);
    } else {
        print("Unknown command: {s}\n", .{args[1]});
        try printHelp();
        return error.UnknownCommand;
    }
}

pub fn parseVideoArgs(args: [][:0]u8, config: *VideoConfig) !void {
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--width") and i + 1 < args.len) {
            config.width = try std.fmt.parseInt(u32, args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, arg, "--height") and i + 1 < args.len) {
            config.height = try std.fmt.parseInt(u32, args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, arg, "--duration") and i + 1 < args.len) {
            config.duration = try std.fmt.parseInt(u32, args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, arg, "--fps") and i + 1 < args.len) {
            config.fps = try std.fmt.parseInt(u32, args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, arg, "--bitrate") and i + 1 < args.len) {
            config.bitrate = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--format") and i + 1 < args.len) {
            config.format = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--codec") and i + 1 < args.len) {
            config.codec = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--output") and i + 1 < args.len) {
            config.output = args[i + 1];
            i += 1;
        }
    }
}

pub fn parseAudioArgs(args: [][:0]u8, config: *AudioConfig) !void {
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--duration") and i + 1 < args.len) {
            config.duration = try std.fmt.parseInt(u32, args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, arg, "--sample-rate") and i + 1 < args.len) {
            config.sample_rate = try std.fmt.parseInt(u32, args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, arg, "--frequency") and i + 1 < args.len) {
            config.frequency = try std.fmt.parseInt(u32, args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, arg, "--bitrate") and i + 1 < args.len) {
            config.bitrate = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--format") and i + 1 < args.len) {
            config.format = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--codec") and i + 1 < args.len) {
            config.codec = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--output") and i + 1 < args.len) {
            config.output = args[i + 1];
            i += 1;
        }
    }
}
