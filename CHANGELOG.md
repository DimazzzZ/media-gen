# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-11

### Added
- FFmpeg is embedded directly into the executable
- No external dependencies required - works out of the box
- Video generation with animated countdown timer
- Audio generation with configurable sine wave test tones
- Support for multiple video formats: MP4, AVI, MOV, MKV
- Support for multiple audio formats: MP3, WAV, AAC, FLAC
- Configurable video parameters: resolution, bitrate, FPS, duration, codec
- Configurable audio parameters: sample rate, bitrate, duration, codec, frequency
- Cross-platform support: Windows, macOS (Intel & ARM), Linux
- Command-line interface with comprehensive help system
- Automatic codec selection for different audio formats
- Comprehensive test suite with unit and integration tests

### Technical
- Built with Zig 0.15+ for optimal performance
- FFmpeg binaries embedded using `@embedFile()` for zero-dependency deployment
- Automatic FFmpeg extraction and execution at runtime
- Fallback to system FFmpeg if available for better performance
- Cross-platform binary embedding for Linux, Windows, and macOS
- Comprehensive test coverage including FFmpeg extraction tests
