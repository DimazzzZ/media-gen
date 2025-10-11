# Media Generator

A fast, cross-platform command-line utility for generating test media files with customizable parameters. Perfect for testing applications, creating placeholder content, or generating media samples.

**No external dependencies required** - FFmpeg is embedded directly into the executable!

[![Build and Test](https://github.com/DimazzzZ/media-gen/actions/workflows/build.yml/badge.svg)](https://github.com/DimazzzZ/media-gen/actions/workflows/build.yml)
[![Test Suite](https://github.com/DimazzzZ/media-gen/actions/workflows/test.yml/badge.svg)](https://github.com/DimazzzZ/media-gen/actions/workflows/test.yml)

## ✨ Features

- 🎬 **Video generation** with animated countdown timer
- 🎵 **Audio generation** with customizable sine wave test tones
- 🎯 **Multiple formats** - MP4, AVI, MOV, MKV, MP3, WAV, AAC, FLAC
- ⚙️ **Highly configurable** - resolution, bitrate, duration, codecs, frequency
- 🚀 **Cross-platform** - Windows, macOS, Linux (Intel & ARM)
- ⚡ **Fast** - Built with Zig for optimal performance
- 📦 **Zero dependencies** - FFmpeg embedded, no installation required

## 🚀 Quick Start

### Installation

Download the latest release for your platform:
- [Linux x86_64](https://github.com/DimazzzZ/media-gen/releases/latest/download/media-gen-linux-x86_64)
- [Windows x86_64](https://github.com/DimazzzZ/media-gen/releases/latest/download/media-gen-windows-x86_64.exe)
- [macOS Intel](https://github.com/DimazzzZ/media-gen/releases/latest/download/media-gen-macos-x86_64)
- [macOS ARM](https://github.com/DimazzzZ/media-gen/releases/latest/download/media-gen-macos-arm64)

### Requirements

**None!** FFmpeg is embedded directly into the executable.

- No external dependencies to install
- No system configuration required
- Works out of the box on all supported platforms

### Basic Usage

```bash
# Generate a 10-second countdown video
./media-gen video --duration 10 --output countdown.mp4

# Generate a 30-second audio test tone
./media-gen audio --duration 30 --output test-tone.mp3

# Generate custom frequency audio
./media-gen audio --frequency 880 --duration 5 --output tone.wav

# Show help
./media-gen help
```

## 📖 Usage Guide

### Video Generation

Create test videos with animated countdown timers:

```bash
# Basic HD video (1920x1080, 30 seconds)
./media-gen video --output my-video.mp4

# Mobile-friendly video
./media-gen video --width 720 --height 1280 --duration 15 --output mobile.mp4

# High-quality video with custom settings
./media-gen video \
  --width 1920 --height 1080 \
  --duration 60 \
  --fps 60 \
  --bitrate 5000k \
  --codec libx265 \
  --output hq-video.mp4

# Different formats
./media-gen video --format mov --output test.mov
./media-gen video --format avi --output test.avi
```

### Audio Generation

Create test audio files with sine wave tones:

```bash
# Basic audio (44.1kHz, 30 seconds)
./media-gen audio --output my-audio.mp3

# High-quality audio
./media-gen audio \
  --sample-rate 48000 \
  --bitrate 320k \
  --format wav \
  --duration 120 \
  --output hq-audio.wav

# Professional audio formats
./media-gen audio --sample-rate 96000 --format flac --output pro.flac
./media-gen audio --format aac --output test.aac
```

📚 **Want more examples?** Check out [EXAMPLES.md](EXAMPLES.md) for comprehensive usage scenarios including mobile app testing, web development, social media formats, and batch generation scripts.

## ⚙️ Configuration Options

### Video Options

| Option | Description | Default | Examples |
|--------|-------------|---------|----------|
| `--width` | Video width in pixels | 1920 | 1280, 1920, 3840 |
| `--height` | Video height in pixels | 1080 | 720, 1080, 2160 |
| `--duration` | Duration in seconds | 30 | 10, 60, 300 |
| `--fps` | Frames per second | 30 | 24, 30, 60 |
| `--bitrate` | Video bitrate | 1000k | 500k, 2000k, 10M |
| `--format` | Output format | mp4 | mp4, avi, mov, mkv |
| `--codec` | Video codec | libx264 | libx264, libx265, libvpx-vp9 |
| `--output` | Output filename | output.mp4 | my-video.mp4 |

### Audio Options

| Option | Description | Default | Examples |
|--------|-------------|---------|----------|
| `--duration` | Duration in seconds | 30 | 10, 60, 300 |
| `--sample-rate` | Sample rate in Hz | 44100 | 22050, 48000, 96000 |
| `--frequency` | Sine wave frequency in Hz | 440 | 220, 880, 1000 |
| `--bitrate` | Audio bitrate | 128k | 96k, 192k, 320k |
| `--format` | Output format | mp3 | mp3, wav, aac, flac |
| `--codec` | Audio codec | libmp3lame | pcm_s16le, aac, flac |
| `--output` | Output filename | output.mp3 | my-audio.wav |

### Audio Options

| Option | Description | Default | Examples |
|--------|-------------|---------|----------|
| `--duration` | Duration in seconds | 30 | 10, 60, 300 |
| `--sample-rate` | Sample rate in Hz | 44100 | 22050, 48000, 96000 |
| `--bitrate` | Audio bitrate | 128k | 96k, 320k, 1411k |
| `--format` | Output format | mp3 | mp3, wav, aac, flac |
| `--codec` | Audio codec | libmp3lame | libmp3lame, pcm_s16le, aac |
| `--output` | Output filename | output.mp3 | my-audio.mp3 |

## 🎯 Use Cases

### Testing & Development
```bash
# Quick test files for development
./media-gen video --duration 5 --width 640 --height 480 --output dev-test.mp4
./media-gen audio --duration 3 --output dev-test.mp3
```

### Mobile App Testing
```bash
# Portrait video for mobile
./media-gen video --width 720 --height 1280 --duration 10 --output mobile-portrait.mp4

# Landscape video for mobile
./media-gen video --width 1280 --height 720 --duration 10 --output mobile-landscape.mp4
```

### Web Development
```bash
# Web-optimized video
./media-gen video --width 854 --height 480 --bitrate 800k --output web-video.mp4

# Compressed audio for web
./media-gen audio --bitrate 96k --format mp3 --output web-audio.mp3
```

### Quality Assurance
```bash
# Various quality levels for testing
./media-gen video --bitrate 500k --output low-quality.mp4
./media-gen video --bitrate 2000k --output medium-quality.mp4
./media-gen video --bitrate 8000k --output high-quality.mp4
```

## 🛠️ Building from Source

### Prerequisites
- [Zig 0.15+](https://ziglang.org/download/)
- Internet connection (for automatic FFmpeg download)

### Build Commands
```bash
# Clone the repository
git clone https://github.com/DimazzzZ/media-gen.git
cd media-gen

# Build for your platform (FFmpeg downloaded automatically)
zig build

# Run tests
zig build test
zig build test-integration

# Build for all platforms
./build-all.sh
```

**Note:** FFmpeg binaries are downloaded automatically during the first build. No manual installation required!

### Cross-compilation
```bash
# Windows
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe

# macOS
zig build -Dtarget=x86_64-macos -Doptimize=ReleaseSafe
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSafe

# Linux
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe
```

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Make** your changes
4. **Test** your changes: `zig build test`
5. **Validate** workflows: `./scripts/validate-workflows.sh`
6. **Commit** your changes: `git commit -m 'Add amazing feature'`
7. **Push** to the branch: `git push origin feature/amazing-feature`
8. **Open** a Pull Request

### Development Setup
```bash
# Install dependencies
# (FFmpeg installation varies by platform - see Requirements section)

# Run development build
zig build

# Run all tests
zig build test

# Validate CI/CD configuration
./scripts/validate-workflows.sh
```

## 📋 Supported Formats

### Video Formats
- **MP4** (H.264, H.265) - Most compatible
- **AVI** (H.264) - Legacy support
- **MOV** (H.264, H.265) - Apple ecosystem
- **MKV** (H.264, H.265, VP9) - Open standard

### Audio Formats
- **MP3** (LAME) - Universal compatibility
- **WAV** (PCM) - Uncompressed, high quality
- **AAC** - Modern, efficient compression
- **FLAC** - Lossless compression

### Sample Rates
8000, 11025, 22050, 44100, 48000, 96000 Hz and more

## 🐛 Troubleshooting

### Common Issues

**FFmpeg not found**
```bash
# Check if FFmpeg is installed
ffmpeg -version

# Install FFmpeg if missing (see Requirements section)
```

**Permission denied**
```bash
# Make the binary executable (Linux/macOS)
chmod +x media-gen
```

**Large file sizes**
```bash
# Reduce bitrate for smaller files
./media-gen video --bitrate 500k --output smaller.mp4
./media-gen audio --bitrate 96k --output smaller.mp3
```

### Getting Help

- 📖 Check this README for usage examples
- � Breowse [EXAMPLES.md](EXAMPLES.md) for comprehensive scenarios
- � [Reqport bugs](https://github.com/DimazzzZ/media-gen/issues)
- � [Rtequest features](https://github.com/DimazzzZ/media-gen/issues)
- 💬 [Start a discussion](https://github.com/DimazzzZ/media-gen/discussions)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Zig](https://ziglang.org/) for performance and reliability
- Powered by [FFmpeg](https://ffmpeg.org/) for media processing
- Inspired by the need for simple, reliable test media generation

---

**Made with ❤️ for developers who need reliable test media files**