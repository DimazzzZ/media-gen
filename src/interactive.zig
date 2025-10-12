const std = @import("std");
const print = std.debug.print;
const cli = @import("cli.zig");
const video_gen = @import("generators/video.zig");
const audio_gen = @import("generators/audio.zig");

const InteractiveConfig = union(cli.MediaType) {
    video: cli.VideoConfig,
    audio: cli.AudioConfig,
};

const Action = enum {
    generate,
    edit,
    cancel,
};

pub fn run(allocator: std.mem.Allocator) !void {
    print("\n🎬 Media Generator - Interactive Mode\n", .{});
    print("=====================================\n\n", .{});

    var config = try collectUserInput(allocator);
    defer freeConfig(allocator, &config);

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
                print("Generation cancelled.\n", .{});
                break;
            },
        }
    }
}

fn collectUserInput(allocator: std.mem.Allocator) !InteractiveConfig {
    // Step 1: Choose media type
    const media_type = try askMediaType();

    switch (media_type) {
        .video => {
            var config = cli.VideoConfig{};

            // Collect video parameters
            config.width = try askNumber(u32, "Video width", config.width);
            config.height = try askNumber(u32, "Video height", config.height);
            config.duration = try askNumber(u32, "Duration (seconds)", config.duration);
            config.fps = try askNumber(u32, "Frames per second", config.fps);
            config.bitrate = try askString(allocator, "Video bitrate", config.bitrate);
            config.format = try askChoice("Video format", &[_][]const u8{ "mp4", "avi", "mov", "mkv" }, config.format);
            config.codec = try askChoice("Video codec", &[_][]const u8{ "libx264", "libx265", "libvpx-vp9" }, config.codec);
            config.output = try askString(allocator, "Output filename", config.output);

            return InteractiveConfig{ .video = config };
        },
        .audio => {
            var config = cli.AudioConfig{};

            // Collect audio parameters
            config.duration = try askNumber(u32, "Duration (seconds)", config.duration);
            config.sample_rate = try askNumber(u32, "Sample rate (Hz)", config.sample_rate);
            config.frequency = try askNumber(u32, "Sine wave frequency (Hz)", config.frequency);
            config.bitrate = try askString(allocator, "Audio bitrate", config.bitrate);
            config.format = try askChoice("Audio format", &[_][]const u8{ "mp3", "wav", "aac", "flac" }, config.format);
            config.codec = try askChoice("Audio codec", &[_][]const u8{ "libmp3lame", "pcm_s16le", "aac" }, config.codec);
            config.output = try askString(allocator, "Output filename", config.output);

            return InteractiveConfig{ .audio = config };
        },
    }
}

fn askMediaType() !cli.MediaType {
    while (true) {
        print("What would you like to generate?\n", .{});
        print("  1) Video (default)\n", .{});
        print("  2) Audio\n", .{});
        print("Choice [1]: ", .{});

        const input = try readUserInput(std.heap.page_allocator);
        defer std.heap.page_allocator.free(input);

        const trimmed = std.mem.trim(u8, input, " \t\n\r");

        if (trimmed.len == 0 or std.mem.eql(u8, trimmed, "1")) {
            return .video;
        } else if (std.mem.eql(u8, trimmed, "2")) {
            return .audio;
        } else {
            print("Invalid choice. Please enter 1 or 2.\n\n", .{});
        }
    }
}

fn askNumber(comptime T: type, prompt: []const u8, default_value: T) !T {
    while (true) {
        print("{s} [{d}]: ", .{ prompt, default_value });

        const input = try readUserInput(std.heap.page_allocator);
        defer std.heap.page_allocator.free(input);

        const trimmed = std.mem.trim(u8, input, " \t\n\r");

        if (trimmed.len == 0) {
            return default_value;
        }

        if (std.fmt.parseInt(T, trimmed, 10)) |value| {
            return value;
        } else |_| {
            print("Invalid number. Please try again.\n", .{});
        }
    }
}

fn askString(allocator: std.mem.Allocator, prompt: []const u8, default_value: []const u8) ![]const u8 {
    print("{s} [{s}]: ", .{ prompt, default_value });

    const input = try readUserInput(std.heap.page_allocator);
    defer std.heap.page_allocator.free(input);

    const trimmed = std.mem.trim(u8, input, " \t\n\r");

    if (trimmed.len == 0) {
        return try allocator.dupe(u8, default_value);
    } else {
        return try allocator.dupe(u8, trimmed);
    }
}

fn askChoice(prompt: []const u8, choices: []const []const u8, default_value: []const u8) ![]const u8 {
    while (true) {
        print("{s}:\n", .{prompt});
        for (choices, 0..) |choice, i| {
            const marker = if (std.mem.eql(u8, choice, default_value)) " (default)" else "";
            print("  {d}) {s}{s}\n", .{ i + 1, choice, marker });
        }
        print("Choice: ", .{});

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

        print("Invalid choice. Please try again.\n\n", .{});
    }
}

fn askAction() !Action {
    while (true) {
        print("What would you like to do?\n", .{});
        print("  1) Generate file (default)\n", .{});
        print("  2) Edit parameters\n", .{});
        print("  3) Cancel\n", .{});
        print("Choice [1]: ", .{});

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
            print("Invalid choice. Please enter 1, 2, or 3.\n\n", .{});
        }
    }
}

fn askConfirmation(prompt: []const u8) !bool {
    while (true) {
        print("{s} [Y/n]: ", .{prompt});

        const input = try readUserInput(std.heap.page_allocator);
        defer std.heap.page_allocator.free(input);

        const trimmed = std.mem.trim(u8, input, " \t\n\r");

        if (trimmed.len == 0 or
            std.mem.eql(u8, trimmed, "y") or
            std.mem.eql(u8, trimmed, "Y") or
            std.mem.eql(u8, trimmed, "yes") or
            std.mem.eql(u8, trimmed, "Yes"))
        {
            return true;
        } else if (std.mem.eql(u8, trimmed, "n") or
            std.mem.eql(u8, trimmed, "N") or
            std.mem.eql(u8, trimmed, "no") or
            std.mem.eql(u8, trimmed, "No"))
        {
            return false;
        } else {
            print("Please enter 'y' for yes or 'n' for no.\n", .{});
        }
    }
}

fn showSummary(config: *const InteractiveConfig) !void {
    print("\n📋 Generation Summary\n", .{});
    print("====================\n", .{});

    switch (config.*) {
        .video => |video_config| {
            print("Type: Video\n", .{});
            print("Resolution: {d}x{d}\n", .{ video_config.width, video_config.height });
            print("Duration: {d} seconds\n", .{video_config.duration});
            print("FPS: {d}\n", .{video_config.fps});
            print("Bitrate: {s}\n", .{video_config.bitrate});
            print("Format: {s}\n", .{video_config.format});
            print("Codec: {s}\n", .{video_config.codec});
            print("Output: {s}\n", .{video_config.output});
        },
        .audio => |audio_config| {
            print("Type: Audio\n", .{});
            print("Duration: {d} seconds\n", .{audio_config.duration});
            print("Sample Rate: {d} Hz\n", .{audio_config.sample_rate});
            print("Frequency: {d} Hz\n", .{audio_config.frequency});
            print("Bitrate: {s}\n", .{audio_config.bitrate});
            print("Format: {s}\n", .{audio_config.format});
            print("Codec: {s}\n", .{audio_config.codec});
            print("Output: {s}\n", .{audio_config.output});
        },
    }
    print("\n", .{});
}

fn editConfig(allocator: std.mem.Allocator, config: *InteractiveConfig) !void {
    print("\n🔧 Edit Parameters\n", .{});
    print("==================\n", .{});

    switch (config.*) {
        .video => |*video_config| {
            print("Which parameter would you like to edit?\n", .{});
            print("  1) Width ({d})\n", .{video_config.width});
            print("  2) Height ({d})\n", .{video_config.height});
            print("  3) Duration ({d}s)\n", .{video_config.duration});
            print("  4) FPS ({d})\n", .{video_config.fps});
            print("  5) Bitrate ({s})\n", .{video_config.bitrate});
            print("  6) Format ({s})\n", .{video_config.format});
            print("  7) Codec ({s})\n", .{video_config.codec});
            print("  8) Output filename ({s})\n", .{video_config.output});
            print("Choice: ", .{});

            const input = try readUserInput(std.heap.page_allocator);
            defer std.heap.page_allocator.free(input);

            const trimmed = std.mem.trim(u8, input, " \t\n\r");

            if (std.mem.eql(u8, trimmed, "1")) {
                video_config.width = try askNumber(u32, "Video width", video_config.width);
            } else if (std.mem.eql(u8, trimmed, "2")) {
                video_config.height = try askNumber(u32, "Video height", video_config.height);
            } else if (std.mem.eql(u8, trimmed, "3")) {
                video_config.duration = try askNumber(u32, "Duration (seconds)", video_config.duration);
            } else if (std.mem.eql(u8, trimmed, "4")) {
                video_config.fps = try askNumber(u32, "Frames per second", video_config.fps);
            } else if (std.mem.eql(u8, trimmed, "5")) {
                allocator.free(video_config.bitrate);
                video_config.bitrate = try askString(allocator, "Video bitrate", "1000k");
            } else if (std.mem.eql(u8, trimmed, "6")) {
                video_config.format = try askChoice("Video format", &[_][]const u8{ "mp4", "avi", "mov", "mkv" }, video_config.format);
            } else if (std.mem.eql(u8, trimmed, "7")) {
                video_config.codec = try askChoice("Video codec", &[_][]const u8{ "libx264", "libx265", "libvpx-vp9" }, video_config.codec);
            } else if (std.mem.eql(u8, trimmed, "8")) {
                allocator.free(video_config.output);
                video_config.output = try askString(allocator, "Output filename", "output.mp4");
            } else {
                print("Invalid choice.\n", .{});
            }
        },
        .audio => |*audio_config| {
            print("Which parameter would you like to edit?\n", .{});
            print("  1) Duration ({d}s)\n", .{audio_config.duration});
            print("  2) Sample rate ({d}Hz)\n", .{audio_config.sample_rate});
            print("  3) Frequency ({d}Hz)\n", .{audio_config.frequency});
            print("  4) Bitrate ({s})\n", .{audio_config.bitrate});
            print("  5) Format ({s})\n", .{audio_config.format});
            print("  6) Codec ({s})\n", .{audio_config.codec});
            print("  7) Output filename ({s})\n", .{audio_config.output});
            print("Choice: ", .{});

            const input = try readUserInput(std.heap.page_allocator);
            defer std.heap.page_allocator.free(input);

            const trimmed = std.mem.trim(u8, input, " \t\n\r");

            if (std.mem.eql(u8, trimmed, "1")) {
                audio_config.duration = try askNumber(u32, "Duration (seconds)", audio_config.duration);
            } else if (std.mem.eql(u8, trimmed, "2")) {
                audio_config.sample_rate = try askNumber(u32, "Sample rate (Hz)", audio_config.sample_rate);
            } else if (std.mem.eql(u8, trimmed, "3")) {
                audio_config.frequency = try askNumber(u32, "Sine wave frequency (Hz)", audio_config.frequency);
            } else if (std.mem.eql(u8, trimmed, "4")) {
                allocator.free(audio_config.bitrate);
                audio_config.bitrate = try askString(allocator, "Audio bitrate", "128k");
            } else if (std.mem.eql(u8, trimmed, "5")) {
                audio_config.format = try askChoice("Audio format", &[_][]const u8{ "mp3", "wav", "aac", "flac" }, audio_config.format);
            } else if (std.mem.eql(u8, trimmed, "6")) {
                audio_config.codec = try askChoice("Audio codec", &[_][]const u8{ "libmp3lame", "pcm_s16le", "aac" }, audio_config.codec);
            } else if (std.mem.eql(u8, trimmed, "7")) {
                allocator.free(audio_config.output);
                audio_config.output = try askString(allocator, "Output filename", "output.mp3");
            } else {
                print("Invalid choice.\n", .{});
            }
        },
    }
    print("\n", .{});
}

fn generateMediaWithProgress(allocator: std.mem.Allocator, config: *const InteractiveConfig) !void {
    print("🚀 Generating media file...\n", .{});

    const duration = switch (config.*) {
        .video => |video_config| video_config.duration,
        .audio => |audio_config| audio_config.duration,
    };

    print("\n⏱️  Estimated time: ~{d} seconds\n", .{duration});
    print("🔄 Processing", .{});

    // Show simple spinner during actual generation
    const spinner_chars = [_][]const u8{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" };
    var spinner_index: usize = 0;

    // Start a simple animation before generation
    var pre_steps: u32 = 0;
    while (pre_steps < 10) : (pre_steps += 1) {
        print("\r🔄 Processing {s} Starting...", .{spinner_chars[spinner_index]});
        spinner_index = (spinner_index + 1) % spinner_chars.len;

        var delay: u32 = 0;
        while (delay < 3000000) : (delay += 1) {
            // Short delay
        }
    }

    print("\r🔄 Processing... Running FFmpeg\n", .{});

    // Now do the actual generation with progress
    switch (config.*) {
        .video => |video_config| {
            try video_gen.generateWithProgress(allocator, video_config, true);
        },
        .audio => |audio_config| {
            try audio_gen.generateWithProgress(allocator, audio_config, true);
        },
    }
}

fn generateMedia(allocator: std.mem.Allocator, config: *const InteractiveConfig) !void {
    print("🚀 Generating media file...\n\n", .{});

    switch (config.*) {
        .video => |video_config| {
            try video_gen.generate(allocator, video_config);
        },
        .audio => |audio_config| {
            try audio_gen.generate(allocator, audio_config);
        },
    }
}

fn freeConfig(allocator: std.mem.Allocator, config: *const InteractiveConfig) void {
    switch (config.*) {
        .video => |video_config| {
            allocator.free(video_config.bitrate);
            allocator.free(video_config.output);
        },
        .audio => |audio_config| {
            allocator.free(audio_config.bitrate);
            allocator.free(audio_config.output);
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
            buffer.ptr,
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
