# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-11

### Added
- Video generation with animated countdown timer
- Audio generation with sine wave test tones
- Support for multiple video formats: MP4, AVI, MOV, MKV
- Support for multiple audio formats: MP3, WAV, AAC, FLAC
- Configurable video parameters: resolution, bitrate, FPS, duration, codec
- Configurable audio parameters: sample rate, bitrate, duration, codec
- Cross-platform support: Windows, macOS (Intel & ARM), Linux
- Command-line interface with comprehensive help system
- Automatic codec selection for different audio formats
- Cross-platform build scripts and CI/CD pipeline

### Technical
- Built with Zig 0.15+ for optimal performance
- Uses FFmpeg for media processing
- Comprehensive test suite with unit and integration tests
- GitHub Actions workflows for automated building and testing