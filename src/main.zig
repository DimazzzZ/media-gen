//! Media Generator - A CLI tool for generating test video and audio files.
//!
//! This is the main entry point for the application. It parses command-line
//! arguments and dispatches to the appropriate generator or interactive mode.

const std = @import("std");
const cli = @import("cli.zig");

/// Main entry point for the media-gen application.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try cli.printHelp();
        return;
    }

    cli.parseAndExecute(allocator, args) catch |err| {
        switch (err) {
            error.UnknownCommand => std.process.exit(1),
            else => return err,
        }
    };
}
