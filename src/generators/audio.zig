const std = @import("std");
const print = std.debug.print;
const cli = @import("../cli.zig");

pub fn generate(allocator: std.mem.Allocator, config: cli.AudioConfig) !void {
    print("Generating audio with parameters:\n", .{});
    print("  Duration: {}s\n", .{config.duration});
    print("  Sample rate: {}Hz\n", .{config.sample_rate});
    print("  Bitrate: {s}\n", .{config.bitrate});
    print("  Format: {s}\n", .{config.format});
    print("  Codec: {s}\n", .{config.codec});
    print("  Output: {s}\n", .{config.output});

    // Create test tone filter
    const filter = try std.fmt.allocPrint(allocator, "sine=frequency=1000:sample_rate={}:duration={}", .{ config.sample_rate, config.duration });
    defer allocator.free(filter);

    // Sample rate string
    const sample_rate_str = try std.fmt.allocPrint(allocator, "{}", .{config.sample_rate});
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

    // Build FFmpeg command array
    var cmd_args: []const []const u8 = undefined;

    if (std.mem.eql(u8, config.format, "wav")) {
        // WAV doesn't need bitrate
        cmd_args = &[_][]const u8{
            "ffmpeg",
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
            "ffmpeg",
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
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = cmd_args,
    }) catch |err| {
        print("Error executing FFmpeg: {}\n", .{err});
        print("Make sure FFmpeg is installed and available in PATH\n", .{});
        return;
    };

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited == 0) {
        print("✅ Audio generated successfully: {s}\n", .{config.output});
    } else {
        print("❌ FFmpeg failed with exit code: {}\n", .{result.term.Exited});
        if (result.stderr.len > 0) {
            print("Error output: {s}\n", .{result.stderr});
        }
    }
}
