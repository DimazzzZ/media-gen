const std = @import("std");
const print = std.debug.print;
const cli = @import("../cli.zig");
const ffmpeg = @import("../ffmpeg.zig");

pub fn generate(allocator: std.mem.Allocator, config: cli.VideoConfig) !void {
    try generateWithProgress(allocator, config, false);
}

pub fn generateWithProgress(allocator: std.mem.Allocator, config: cli.VideoConfig, show_progress: bool) !void {
    print("Generating video with parameters:\n", .{});
    print("  Resolution: {}x{}\n", .{ config.width, config.height });
    print("  Duration: {}s\n", .{config.duration});
    print("  FPS: {}\n", .{config.fps});
    print("  Bitrate: {s}\n", .{config.bitrate});
    print("  Format: {s}\n", .{config.format});
    print("  Codec: {s}\n", .{config.codec});
    print("  Output: {s}\n", .{config.output});

    // Create input filter with countdown timer - black background with large white numbers
    const filter = try std.fmt.allocPrint(allocator, "color=c=black:size={}x{}:duration={}:rate={},drawtext=text='%{{eif\\:floor({}-t)\\:d}}.%{{eif\\:floor((({}-t)-floor({}-t))*100)\\:d\\:2}}':fontsize=200:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2", .{ config.width, config.height, config.duration, config.fps, config.duration, config.duration, config.duration });
    defer allocator.free(filter);

    // Get FFmpeg path (system or embedded)
    const ffmpeg_path = ffmpeg.getFFmpegPath(allocator) catch |err| {
        print("Error: Cannot find or extract FFmpeg: {}\n", .{err});
        return;
    };
    defer allocator.free(ffmpeg_path);

    // Build FFmpeg command array
    const cmd_args = [_][]const u8{
        ffmpeg_path,
        "-y", // Overwrite output file
        "-f",
        "lavfi",
        "-i",
        filter,
        "-c:v",
        config.codec,
        "-b:v",
        config.bitrate,
        config.output,
    };

    // Execute FFmpeg command
    if (show_progress) {
        print("🎬 Running FFmpeg encoder...\n", .{});
        print("⏳ Please wait, encoding {d}s video...\n", .{config.duration});
    }

    // Run FFmpeg
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &cmd_args,
    }) catch |err| {
        print("Error executing FFmpeg: {}\n", .{err});
        return;
    };

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited == 0) {
        print("✅ Video generated successfully: {s}\n", .{config.output});
    } else {
        print("❌ FFmpeg failed with exit code: {}\n", .{result.term.Exited});
        if (result.stderr.len > 0) {
            print("Error output: {s}\n", .{result.stderr});
        }
    }
}
