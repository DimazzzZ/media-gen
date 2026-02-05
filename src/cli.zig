const std = @import("std");
const video_gen = @import("generators/video.zig");
const audio_gen = @import("generators/audio.zig");
const ffmpeg = @import("ffmpeg.zig");

/// Supported media types for generation.
pub const MediaType = enum {
    video,
    audio,
};

/// Configuration for video generation.
pub const VideoConfig = struct {
    /// Video width in pixels.
    width: u32 = 1920,
    /// Video height in pixels.
    height: u32 = 1080,
    /// Duration in seconds.
    duration: u32 = 30,
    /// Frames per second.
    fps: u32 = 30,
    /// Video bitrate (e.g., "1000k").
    bitrate: []const u8 = "1000k",
    /// Output format (e.g., "mp4", "avi", "mov", "mkv").
    format: []const u8 = "mp4",
    /// Video codec (e.g., "libx264", "libx265", "libvpx-vp9").
    codec: []const u8 = "libx264",
    /// Output filename.
    output: []const u8 = "output.mp4",
};

/// Configuration for audio generation.
pub const AudioConfig = struct {
    /// Duration in seconds.
    duration: u32 = 30,
    /// Sample rate in Hz.
    sample_rate: u32 = 44100,
    /// Audio bitrate (e.g., "128k").
    bitrate: []const u8 = "128k",
    /// Output format (e.g., "mp3", "wav", "aac", "flac").
    format: []const u8 = "mp3",
    /// Audio codec (e.g., "libmp3lame", "pcm_s16le", "aac").
    codec: []const u8 = "libmp3lame",
    /// Sine wave frequency in Hz.
    frequency: u32 = 440,
    /// Output filename.
    output: []const u8 = "output.mp3",
};

/// Prints the help message to stdout.
pub fn printHelp() !void {
    std.debug.print("Media Generator - {s}\n", .{ffmpeg.getBuildInfo()});
    std.debug.print("Usage: media-gen <command> [options]\n\n", .{});
    std.debug.print("Commands:\n", .{});
    std.debug.print("  video        Generate video file with countdown timer\n", .{});
    std.debug.print("  audio        Generate audio file with test tones\n", .{});
    std.debug.print("  i, interactive  Interactive mode - guided setup\n", .{});
    std.debug.print("  help         Show this help message\n\n", .{});
    std.debug.print("Video options:\n", .{});
    std.debug.print("  --width <width>        Video width (default: 1920)\n", .{});
    std.debug.print("  --height <height>      Video height (default: 1080)\n", .{});
    std.debug.print("  --duration <seconds>   Duration in seconds (default: 30)\n", .{});
    std.debug.print("  --fps <fps>           Frames per second (default: 30)\n", .{});
    std.debug.print("  --bitrate <bitrate>   Video bitrate (default: 1000k)\n", .{});
    std.debug.print("  --format <format>     Output format (mp4, avi, mov, mkv)\n", .{});
    std.debug.print("  --codec <codec>       Video codec (libx264, libx265, libvpx-vp9)\n", .{});
    std.debug.print("  --output <filename>   Output filename (default: output.mp4)\n\n", .{});
    std.debug.print("Audio options:\n", .{});
    std.debug.print("  --duration <seconds>   Duration in seconds (default: 30)\n", .{});
    std.debug.print("  --sample-rate <rate>   Sample rate (default: 44100)\n", .{});
    std.debug.print("  --frequency <hz>      Sine wave frequency (default: 440)\n", .{});
    std.debug.print("  --bitrate <bitrate>   Audio bitrate (default: 128k)\n", .{});
    std.debug.print("  --format <format>     Output format (mp3, wav, aac, flac)\n", .{});
    std.debug.print("  --codec <codec>       Audio codec (libmp3lame, pcm_s16le, aac)\n", .{});
    std.debug.print("  --output <filename>   Output filename (default: output.mp3)\n\n", .{});
    std.debug.print("Examples:\n", .{});
    std.debug.print("  media-gen video --width 1280 --height 720 --duration 60 --output test.mp4\n", .{});
    std.debug.print("  media-gen audio --bitrate 320k --duration 120 --format wav --output test.wav\n", .{});
    std.debug.print("  media-gen audio --frequency 880 --sample-rate 48000 --output tone.wav\n", .{});
    if (ffmpeg.isEmbedded()) {
        std.debug.print("\nNote: FFmpeg is embedded - no external installation required!\n", .{});
    } else {
        std.debug.print("\nNote: This is the standalone edition - FFmpeg must be installed on your system.\n", .{});
        std.debug.print("      Install FFmpeg: brew install ffmpeg (macOS) | apt install ffmpeg (Linux) | choco install ffmpeg (Windows)\n", .{});
    }
}

/// Parses command-line arguments and executes the appropriate command.
/// Returns `error.UnknownCommand` if the command is not recognized.
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
        std.debug.print("Unknown command: {s}\n", .{args[1]});
        try printHelp();
        return error.UnknownCommand;
    }
}

/// Parses video-specific command-line arguments into the configuration struct.
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

/// Parses audio-specific command-line arguments into the configuration struct.
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
