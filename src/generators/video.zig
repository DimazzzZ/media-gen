const std = @import("std");
const print = std.debug.print;
const cli = @import("../cli.zig");

pub fn generate(allocator: std.mem.Allocator, config: cli.VideoConfig) !void {
    print("Generating video with parameters:\n", .{});
    print("  Resolution: {}x{}\n", .{ config.width, config.height });
    print("  Duration: {}s\n", .{config.duration});
    print("  FPS: {}\n", .{config.fps});
    print("  Bitrate: {s}\n", .{config.bitrate});
    print("  Format: {s}\n", .{config.format});
    print("  Codec: {s}\n", .{config.codec});
    print("  Output: {s}\n", .{config.output});

    // Create input filter with countdown
    const filter = try std.fmt.allocPrint(allocator, "color=c=black:size={}x{}:duration={}:rate={},drawtext=fontfile=/System/Library/Fonts/Arial.ttf:text='%{{eif\\:{}-%{{t}}\\:d}}':fontsize=72:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2", .{ config.width, config.height, config.duration, config.fps, config.duration });
    defer allocator.free(filter);

    // Build FFmpeg command array
    const cmd_args = [_][]const u8{
        "ffmpeg",
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
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &cmd_args,
    }) catch |err| {
        print("Error executing FFmpeg: {}\n", .{err});
        print("Make sure FFmpeg is installed and available in PATH\n", .{});
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
