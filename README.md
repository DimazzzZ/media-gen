# Media Generator

A command-line utility for generating test media files (video and audio) with customizable parameters.

[![Build and Test](https://github.com/your-username/media-gen/actions/workflows/build.yml/badge.svg)](https://github.com/your-username/media-gen/actions/workflows/build.yml)
[![Test Suite](https://github.com/your-username/media-gen/actions/workflows/test.yml/badge.svg)](https://github.com/your-username/media-gen/actions/workflows/test.yml)

## Features

- **Video generation** with countdown timer
- **Audio generation** with test tone
- Support for various formats and codecs
- Configurable resolution, bitrate, duration
- Cross-platform (Windows, macOS, Linux)

## Requirements

- Zig 0.15+ for building
- FFmpeg for media generation (must be installed on system)

## Building

```bash
# Build for current platform
zig build

# Run tests
zig build test

# Run the executable
./zig-out/bin/media-gen help

# Cross-platform builds
zig build -Dtarget=x86_64-windows
zig build -Dtarget=x86_64-macos
zig build -Dtarget=x86_64-linux

# Build all platforms (using script)
./build-all.sh
```

## Usage

### Video Generation

```bash
# Basic usage
./media-gen video

# With custom settings
./media-gen video --width 1280 --height 720 --duration 60 --bitrate 2000k --output test.mp4

# Different formats
./media-gen video --format mov --codec libx265 --output test.mov
```

### Audio Generation

```bash
# Basic usage
./media-gen audio

# With custom settings
./media-gen audio --duration 120 --bitrate 320k --format wav --output test.wav

# Different formats
./media-gen audio --format flac --sample-rate 48000 --output test.flac
```

## Supported Formats

### Video
- **Formats**: MP4, AVI, MOV, MKV
- **Codecs**: libx264, libx265, libvpx-vp9

### Audio
- **Formats**: MP3, WAV, AAC, FLAC
- **Codecs**: libmp3lame, pcm_s16le, aac
- **Sample Rates**: 8000, 11025, 22050, 44100, 48000, 96000 Hz (and others)

## Default Parameters

### Video
- Resolution: 1920x1080
- Duration: 30 seconds
- FPS: 30
- Bitrate: 1000k
- Format: MP4
- Codec: libx264

### Audio
- Duration: 30 seconds
- Sample rate: 44100 Hz
- Bitrate: 128k
- Format: MP3
- Codec: libmp3lame

## Usage Examples

```bash
# Create test video for mobile app
./media-gen video --width 720 --height 1280 --duration 15 --bitrate 500k --output mobile_test.mp4

# Create high-quality audio for testing
./media-gen audio --bitrate 320k --sample-rate 48000 --format wav --duration 300 --output hq_test.wav

# Create CD-quality audio
./media-gen audio --sample-rate 44100 --bitrate 320k --format wav --output cd_quality.wav

# Create professional audio (96kHz)
./media-gen audio --sample-rate 96000 --bitrate 320k --format flac --output professional.flac

# Create web-optimized video
./media-gen video --width 854 --height 480 --bitrate 800k --format mp4 --output web_test.mp4
```

## Development

### Running Tests

```bash
# Run unit tests
zig build test

# Run integration tests (requires FFmpeg)
./zig-out/bin/media-gen video --duration 2 --output test.mp4
./zig-out/bin/media-gen audio --duration 2 --output test.mp3
```

### CI/CD

The project uses GitHub Actions for continuous integration:

- **Build and Test**: Runs on push/PR, builds for all platforms
- **Manual Build**: Allows manual building for specific platforms
- **Test Suite**: Comprehensive testing including performance tests
- **Workflow Validation**: Validates CI/CD configuration files

See [.github/README.md](.github/README.md) for detailed CI/CD documentation.

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `zig build test`
5. Submit a pull request

All PRs are automatically tested on Linux, Windows, and macOS.