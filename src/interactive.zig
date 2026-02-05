//! Interactive mode for media-gen.
//!
//! This module provides a guided, menu-driven interface for configuring
//! and generating media files.

const std = @import("std");
const cli = @import("cli.zig");
const video_gen = @import("generators/video.zig");
const audio_gen = @import("generators/audio.zig");

/// Interactive configuration that wraps either video or audio config.
/// Tracks which string fields were dynamically allocated.
const InteractiveConfig = struct {
    media_type: cli.MediaType,

    // Video configuration fields
    video_width: u32 = 1920,
    video_height: u32 = 1080,
    video_duration: u32 = 30,
    video_fps: u32 = 30,
    video_bitrate: []const u8 = "1000k",
    video_bitrate_allocated: bool = false,
    video_format: []const u8 = "mp4",
    video_codec: []const u8 = "libx264",
    video_output: []const u8 = "output.mp4",
    video_output_allocated: bool = false,

    // Audio configuration fields
    audio_duration: u32 = 30,
    audio_sample_rate: u32 = 44100,
    audio_frequency: u32 = 440,
    audio_bitrate: []const u8 = "128k",
    audio_bitrate_allocated: bool = false,
    audio_format: []const u8 = "mp3",
    audio_codec: []const u8 = "libmp3lame",
    audio_output: []const u8 = "output.mp3",
    audio_output_allocated: bool = false,

    /// Converts to a VideoConfig struct for generation.
    fn toVideoConfig(self: *const InteractiveConfig) cli.VideoConfig {
        return .{
            .width = self.video_width,
            .height = self.video_height,
            .duration = self.video_duration,
            .fps = self.video_fps,
            .bitrate = self.video_bitrate,
            .format = self.video_format,
            .codec = self.video_codec,
            .output = self.video_output,
        };
    }

    /// Converts to an AudioConfig struct for generation.
    fn toAudioConfig(self: *const InteractiveConfig) cli.AudioConfig {
        return .{
            .duration = self.audio_duration,
            .sample_rate = self.audio_sample_rate,
            .frequency = self.audio_frequency,
            .bitrate = self.audio_bitrate,
            .format = self.audio_format,
            .codec = self.audio_codec,
            .output = self.audio_output,
        };
    }

    /// Frees any dynamically allocated string fields.
    fn deinit(self: *InteractiveConfig, allocator: std.mem.Allocator) void {
        if (self.video_bitrate_allocated) {
            allocator.free(self.video_bitrate);
        }
        if (self.video_output_allocated) {
            allocator.free(self.video_output);
        }
        if (self.audio_bitrate_allocated) {
            allocator.free(self.audio_bitrate);
        }
        if (self.audio_output_allocated) {
            allocator.free(self.audio_output);
        }
    }
};

const Action = enum {
    generate,
    edit,
    cancel,
};

/// Runs the interactive mode, guiding the user through media generation.
pub fn run(allocator: std.mem.Allocator) !void {
    std.debug.print("\n🎬 Media Generator - Interactive Mode\n", .{});
    std.debug.print("=====================================\n\n", .{});

    var config = try collectUserInput(allocator);
    defer config.deinit(allocator);

    // Show summary and allow editing
    while (true) {
        try showSummary(&config);

        const action = try askAction();
        switch (action) {
            .generate => {
                try generateMediaWithProgress(allocator, &config);
                break;
            },
            .edit => {
                try editConfig(allocator, &config);
            },
            .cancel => {
                std.debug.print("Generation cancelled.\n", .{});
                break;
            },
        }
    }
}

fn collectUserInput(allocator: std.mem.Allocator) !InteractiveConfig {
    // Step 1: Choose media type
    const media_type = try askMediaType();

    var config = InteractiveConfig{ .media_type = media_type };

    switch (media_type) {
        .video => {
            config.video_width = try askNumber(u32, "Video width", config.video_width);
            config.video_height = try askNumber(u32, "Video height", config.video_height);
            config.video_duration = try askNumber(u32, "Duration (seconds)", config.video_duration);
            config.video_fps = try askNumber(u32, "Frames per second", config.video_fps);

            const bitrate_result = try askString(allocator, "Video bitrate", config.video_bitrate);
            config.video_bitrate = bitrate_result.value;
            config.video_bitrate_allocated = bitrate_result.allocated;

            config.video_format = try askChoice("Video format", &[_][]const u8{ "mp4", "avi", "mov", "mkv" }, config.video_format);
            config.video_codec = try askChoice("Video codec", &[_][]const u8{ "libx264", "libx265", "libvpx-vp9" }, config.video_codec);

            const output_result = try askString(allocator, "Output filename", config.video_output);
            config.video_output = output_result.value;
            config.video_output_allocated = output_result.allocated;
        },
        .audio => {
            config.audio_duration = try askNumber(u32, "Duration (seconds)", config.audio_duration);
            config.audio_sample_rate = try askNumber(u32, "Sample rate (Hz)", config.audio_sample_rate);
            config.audio_frequency = try askNumber(u32, "Sine wave frequency (Hz)", config.audio_frequency);

            const bitrate_result = try askString(allocator, "Audio bitrate", config.audio_bitrate);
            config.audio_bitrate = bitrate_result.value;
            config.audio_bitrate_allocated = bitrate_result.allocated;

            config.audio_format = try askChoice("Audio format", &[_][]const u8{ "mp3", "wav", "aac", "flac" }, config.audio_format);
            config.audio_codec = try askChoice("Audio codec", &[_][]const u8{ "libmp3lame", "pcm_s16le", "aac" }, config.audio_codec);

            const output_result = try askString(allocator, "Output filename", config.audio_output);
            config.audio_output = output_result.value;
            config.audio_output_allocated = output_result.allocated;
        },
    }

    return config;
}

fn askMediaType() !cli.MediaType {
    while (true) {
        std.debug.print("What would you like to generate?\n", .{});
        std.debug.print("  1) Video (default)\n", .{});
        std.debug.print("  2) Audio\n", .{});
        std.debug.print("Choice [1]: ", .{});

        const input = try readUserInput(std.heap.page_allocator);
        defer std.heap.page_allocator.free(input);

        const trimmed = std.mem.trim(u8, input, " \t\n\r");

        if (trimmed.len == 0 or std.mem.eql(u8, trimmed, "1")) {
            return .video;
        } else if (std.mem.eql(u8, trimmed, "2")) {
            return .audio;
        } else {
            std.debug.print("Invalid choice. Please enter 1 or 2.\n\n", .{});
        }
    }
}

fn askNumber(comptime T: type, prompt: []const u8, default_value: T) !T {
    while (true) {
        std.debug.print("{s} [{d}]: ", .{ prompt, default_value });

        const input = try readUserInput(std.heap.page_allocator);
        defer std.heap.page_allocator.free(input);

        const trimmed = std.mem.trim(u8, input, " \t\n\r");

        if (trimmed.len == 0) {
            return default_value;
        }

        if (std.fmt.parseInt(T, trimmed, 10)) |value| {
            return value;
        } else |_| {
            std.debug.print("Invalid number. Please try again.\n", .{});
        }
    }
}

/// Result of askString, tracking whether memory was allocated.
const StringResult = struct {
    value: []const u8,
    allocated: bool,
};

fn askString(allocator: std.mem.Allocator, prompt: []const u8, default_value: []const u8) !StringResult {
    std.debug.print("{s} [{s}]: ", .{ prompt, default_value });

    const input = try readUserInput(std.heap.page_allocator);
    defer std.heap.page_allocator.free(input);

    const trimmed = std.mem.trim(u8, input, " \t\n\r");

    if (trimmed.len == 0) {
        return .{ .value = default_value, .allocated = false };
    } else {
        return .{ .value = try allocator.dupe(u8, trimmed), .allocated = true };
    }
}

fn askChoice(prompt: []const u8, choices: []const []const u8, default_value: []const u8) ![]const u8 {
    while (true) {
        std.debug.print("{s}:\n", .{prompt});
        for (choices, 0..) |choice, i| {
            const marker = if (std.mem.eql(u8, choice, default_value)) " (default)" else "";
            std.debug.print("  {d}) {s}{s}\n", .{ i + 1, choice, marker });
        }
        std.debug.print("Choice: ", .{});

        const input = try readUserInput(std.heap.page_allocator);
        defer std.heap.page_allocator.free(input);

        const trimmed = std.mem.trim(u8, input, " \t\n\r");

        if (trimmed.len == 0) {
            return default_value;
        }

        // Try to parse as number
        if (std.fmt.parseInt(usize, trimmed, 10)) |choice_num| {
            if (choice_num >= 1 and choice_num <= choices.len) {
                return choices[choice_num - 1];
            }
        } else |_| {
            // Try to match by name
            for (choices) |choice| {
                if (std.mem.eql(u8, trimmed, choice)) {
                    return choice;
                }
            }
        }

        std.debug.print("Invalid choice. Please try again.\n\n", .{});
    }
}

fn askAction() !Action {
    while (true) {
        std.debug.print("What would you like to do?\n", .{});
        std.debug.print("  1) Generate file (default)\n", .{});
        std.debug.print("  2) Edit parameters\n", .{});
        std.debug.print("  3) Cancel\n", .{});
        std.debug.print("Choice [1]: ", .{});

        const input = try readUserInput(std.heap.page_allocator);
        defer std.heap.page_allocator.free(input);

        const trimmed = std.mem.trim(u8, input, " \t\n\r");

        if (trimmed.len == 0 or std.mem.eql(u8, trimmed, "1")) {
            return .generate;
        } else if (std.mem.eql(u8, trimmed, "2")) {
            return .edit;
        } else if (std.mem.eql(u8, trimmed, "3")) {
            return .cancel;
        } else {
            std.debug.print("Invalid choice. Please enter 1, 2, or 3.\n\n", .{});
        }
    }
}

fn showSummary(config: *const InteractiveConfig) !void {
    std.debug.print("\n📋 Generation Summary\n", .{});
    std.debug.print("====================\n", .{});

    switch (config.media_type) {
        .video => {
            std.debug.print("Type: Video\n", .{});
            std.debug.print("Resolution: {d}x{d}\n", .{ config.video_width, config.video_height });
            std.debug.print("Duration: {d} seconds\n", .{config.video_duration});
            std.debug.print("FPS: {d}\n", .{config.video_fps});
            std.debug.print("Bitrate: {s}\n", .{config.video_bitrate});
            std.debug.print("Format: {s}\n", .{config.video_format});
            std.debug.print("Codec: {s}\n", .{config.video_codec});
            std.debug.print("Output: {s}\n", .{config.video_output});
        },
        .audio => {
            std.debug.print("Type: Audio\n", .{});
            std.debug.print("Duration: {d} seconds\n", .{config.audio_duration});
            std.debug.print("Sample Rate: {d} Hz\n", .{config.audio_sample_rate});
            std.debug.print("Frequency: {d} Hz\n", .{config.audio_frequency});
            std.debug.print("Bitrate: {s}\n", .{config.audio_bitrate});
            std.debug.print("Format: {s}\n", .{config.audio_format});
            std.debug.print("Codec: {s}\n", .{config.audio_codec});
            std.debug.print("Output: {s}\n", .{config.audio_output});
        },
    }
    std.debug.print("\n", .{});
}

fn editConfig(allocator: std.mem.Allocator, config: *InteractiveConfig) !void {
    std.debug.print("\n🔧 Edit Parameters\n", .{});
    std.debug.print("==================\n", .{});

    switch (config.media_type) {
        .video => {
            std.debug.print("Which parameter would you like to edit?\n", .{});
            std.debug.print("  1) Width ({d})\n", .{config.video_width});
            std.debug.print("  2) Height ({d})\n", .{config.video_height});
            std.debug.print("  3) Duration ({d}s)\n", .{config.video_duration});
            std.debug.print("  4) FPS ({d})\n", .{config.video_fps});
            std.debug.print("  5) Bitrate ({s})\n", .{config.video_bitrate});
            std.debug.print("  6) Format ({s})\n", .{config.video_format});
            std.debug.print("  7) Codec ({s})\n", .{config.video_codec});
            std.debug.print("  8) Output filename ({s})\n", .{config.video_output});
            std.debug.print("Choice: ", .{});

            const input = try readUserInput(std.heap.page_allocator);
            defer std.heap.page_allocator.free(input);

            const trimmed = std.mem.trim(u8, input, " \t\n\r");

            if (std.mem.eql(u8, trimmed, "1")) {
                config.video_width = try askNumber(u32, "Video width", config.video_width);
            } else if (std.mem.eql(u8, trimmed, "2")) {
                config.video_height = try askNumber(u32, "Video height", config.video_height);
            } else if (std.mem.eql(u8, trimmed, "3")) {
                config.video_duration = try askNumber(u32, "Duration (seconds)", config.video_duration);
            } else if (std.mem.eql(u8, trimmed, "4")) {
                config.video_fps = try askNumber(u32, "Frames per second", config.video_fps);
            } else if (std.mem.eql(u8, trimmed, "5")) {
                if (config.video_bitrate_allocated) {
                    allocator.free(config.video_bitrate);
                }
                const result = try askString(allocator, "Video bitrate", "1000k");
                config.video_bitrate = result.value;
                config.video_bitrate_allocated = result.allocated;
            } else if (std.mem.eql(u8, trimmed, "6")) {
                config.video_format = try askChoice("Video format", &[_][]const u8{ "mp4", "avi", "mov", "mkv" }, config.video_format);
            } else if (std.mem.eql(u8, trimmed, "7")) {
                config.video_codec = try askChoice("Video codec", &[_][]const u8{ "libx264", "libx265", "libvpx-vp9" }, config.video_codec);
            } else if (std.mem.eql(u8, trimmed, "8")) {
                if (config.video_output_allocated) {
                    allocator.free(config.video_output);
                }
                const result = try askString(allocator, "Output filename", "output.mp4");
                config.video_output = result.value;
                config.video_output_allocated = result.allocated;
            } else {
                std.debug.print("Invalid choice.\n", .{});
            }
        },
        .audio => {
            std.debug.print("Which parameter would you like to edit?\n", .{});
            std.debug.print("  1) Duration ({d}s)\n", .{config.audio_duration});
            std.debug.print("  2) Sample rate ({d}Hz)\n", .{config.audio_sample_rate});
            std.debug.print("  3) Frequency ({d}Hz)\n", .{config.audio_frequency});
            std.debug.print("  4) Bitrate ({s})\n", .{config.audio_bitrate});
            std.debug.print("  5) Format ({s})\n", .{config.audio_format});
            std.debug.print("  6) Codec ({s})\n", .{config.audio_codec});
            std.debug.print("  7) Output filename ({s})\n", .{config.audio_output});
            std.debug.print("Choice: ", .{});

            const input = try readUserInput(std.heap.page_allocator);
            defer std.heap.page_allocator.free(input);

            const trimmed = std.mem.trim(u8, input, " \t\n\r");

            if (std.mem.eql(u8, trimmed, "1")) {
                config.audio_duration = try askNumber(u32, "Duration (seconds)", config.audio_duration);
            } else if (std.mem.eql(u8, trimmed, "2")) {
                config.audio_sample_rate = try askNumber(u32, "Sample rate (Hz)", config.audio_sample_rate);
            } else if (std.mem.eql(u8, trimmed, "3")) {
                config.audio_frequency = try askNumber(u32, "Sine wave frequency (Hz)", config.audio_frequency);
            } else if (std.mem.eql(u8, trimmed, "4")) {
                if (config.audio_bitrate_allocated) {
                    allocator.free(config.audio_bitrate);
                }
                const result = try askString(allocator, "Audio bitrate", "128k");
                config.audio_bitrate = result.value;
                config.audio_bitrate_allocated = result.allocated;
            } else if (std.mem.eql(u8, trimmed, "5")) {
                config.audio_format = try askChoice("Audio format", &[_][]const u8{ "mp3", "wav", "aac", "flac" }, config.audio_format);
            } else if (std.mem.eql(u8, trimmed, "6")) {
                config.audio_codec = try askChoice("Audio codec", &[_][]const u8{ "libmp3lame", "pcm_s16le", "aac" }, config.audio_codec);
            } else if (std.mem.eql(u8, trimmed, "7")) {
                if (config.audio_output_allocated) {
                    allocator.free(config.audio_output);
                }
                const result = try askString(allocator, "Output filename", "output.mp3");
                config.audio_output = result.value;
                config.audio_output_allocated = result.allocated;
            } else {
                std.debug.print("Invalid choice.\n", .{});
            }
        },
    }
    std.debug.print("\n", .{});
}

fn generateMediaWithProgress(allocator: std.mem.Allocator, config: *const InteractiveConfig) !void {
    std.debug.print("🚀 Generating media file...\n", .{});

    const duration = switch (config.media_type) {
        .video => config.video_duration,
        .audio => config.audio_duration,
    };

    std.debug.print("\n⏱️  Estimated time: ~{d} seconds\n", .{duration});
    std.debug.print("🔄 Processing", .{});

    // Show simple spinner animation before generation using proper sleep
    const spinner_chars = [_][]const u8{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" };
    var spinner_index: usize = 0;

    var pre_steps: u32 = 0;
    while (pre_steps < 10) : (pre_steps += 1) {
        std.debug.print("\r🔄 Processing {s} Starting...", .{spinner_chars[spinner_index]});
        spinner_index = (spinner_index + 1) % spinner_chars.len;

        // Use proper sleep instead of busy-wait (100ms)
        std.Thread.sleep(100 * std.time.ns_per_ms);
    }

    std.debug.print("\r🔄 Processing... Running FFmpeg\n", .{});

    // Now do the actual generation with progress
    switch (config.media_type) {
        .video => {
            try video_gen.generateWithProgress(allocator, config.toVideoConfig(), true);
        },
        .audio => {
            try audio_gen.generateWithProgress(allocator, config.toAudioConfig(), true);
        },
    }
}

fn readUserInput(allocator: std.mem.Allocator) ![]u8 {
    const builtin = @import("builtin");

    if (builtin.os.tag == .windows) {
        // Windows-specific implementation
        const stdin_handle = std.os.windows.GetStdHandle(std.os.windows.STD_INPUT_HANDLE) catch return error.StdinUnavailable;
        var buffer: [1024]u8 = undefined;
        var bytes_read: std.os.windows.DWORD = undefined;

        const success = std.os.windows.kernel32.ReadFile(
            stdin_handle,
            &buffer,
            buffer.len,
            &bytes_read,
            null,
        );

        if (success == 0) return error.ReadFailed;

        if (bytes_read > 0) {
            // Remove trailing newline if present
            const end = if (buffer[bytes_read - 1] == '\n') bytes_read - 1 else bytes_read;
            return try allocator.dupe(u8, buffer[0..end]);
        } else {
            return try allocator.dupe(u8, "");
        }
    } else {
        // Unix-like systems
        var buffer: [1024]u8 = undefined;
        const bytes_read = try std.posix.read(@as(std.posix.fd_t, 0), buffer[0..]);

        if (bytes_read > 0) {
            // Remove trailing newline if present
            const end = if (buffer[bytes_read - 1] == '\n') bytes_read - 1 else bytes_read;
            return try allocator.dupe(u8, buffer[0..end]);
        } else {
            return try allocator.dupe(u8, "");
        }
    }
}
