# Media Generator Examples

This document provides practical examples for using Media Generator in various scenarios.

## 🎬 Video Examples

### Basic Video Generation
```bash
# Simple 10-second countdown video
./media-gen video --duration 10 --output countdown.mp4

# HD video with custom settings
./media-gen video --width 1920 --height 1080 --duration 30 --output hd-video.mp4
```

### Mobile App Testing
```bash
# iPhone portrait (9:16 aspect ratio)
./media-gen video --width 720 --height 1280 --duration 15 --output iphone-portrait.mp4

# iPhone landscape (16:9 aspect ratio)
./media-gen video --width 1280 --height 720 --duration 15 --output iphone-landscape.mp4

# iPad (4:3 aspect ratio)
./media-gen video --width 1024 --height 768 --duration 20 --output ipad-video.mp4

# Android tablet (16:10 aspect ratio)
./media-gen video --width 1280 --height 800 --duration 20 --output android-tablet.mp4
```

### Web Development
```bash
# Small web video (low bandwidth)
./media-gen video --width 640 --height 360 --bitrate 500k --duration 30 --output web-small.mp4

# Medium web video
./media-gen video --width 854 --height 480 --bitrate 1000k --duration 30 --output web-medium.mp4

# Large web video (high quality)
./media-gen video --width 1280 --height 720 --bitrate 2500k --duration 30 --output web-large.mp4

# 4K web video (premium quality)
./media-gen video --width 3840 --height 2160 --bitrate 15000k --duration 10 --output web-4k.mp4
```

### Social Media Formats
```bash
# Instagram Story (9:16)
./media-gen video --width 1080 --height 1920 --duration 15 --output instagram-story.mp4

# Instagram Post (1:1)
./media-gen video --width 1080 --height 1080 --duration 30 --output instagram-post.mp4

# YouTube Thumbnail Test (16:9)
./media-gen video --width 1920 --height 1080 --duration 5 --output youtube-thumb.mp4

# TikTok (9:16)
./media-gen video --width 720 --height 1280 --duration 15 --output tiktok.mp4
```

### Quality Testing
```bash
# Low quality (for bandwidth testing)
./media-gen video --bitrate 250k --width 480 --height 270 --output low-quality.mp4

# Medium quality
./media-gen video --bitrate 1000k --width 854 --height 480 --output medium-quality.mp4

# High quality
./media-gen video --bitrate 5000k --width 1920 --height 1080 --output high-quality.mp4

# Ultra quality (for stress testing)
./media-gen video --bitrate 20000k --width 3840 --height 2160 --fps 60 --output ultra-quality.mp4
```

### Different Codecs and Formats
```bash
# H.264 (most compatible)
./media-gen video --codec libx264 --format mp4 --output h264-video.mp4

# H.265 (better compression)
./media-gen video --codec libx265 --format mp4 --output h265-video.mp4

# VP9 (open source)
./media-gen video --codec libvpx-vp9 --format mkv --output vp9-video.mkv

# Apple ProRes (MOV format)
./media-gen video --format mov --output apple-video.mov

# Legacy AVI format
./media-gen video --format avi --output legacy-video.avi
```

## 🎵 Audio Examples

### Basic Audio Generation
```bash
# Simple test tone
./media-gen audio --duration 10 --output test-tone.mp3

# High-quality audio
./media-gen audio --sample-rate 48000 --bitrate 320k --output hq-audio.mp3
```

### Different Sample Rates
```bash
# Telephone quality (8kHz)
./media-gen audio --sample-rate 8000 --duration 30 --output telephone.wav

# AM Radio quality (11kHz)
./media-gen audio --sample-rate 11025 --duration 30 --output am-radio.wav

# FM Radio quality (22kHz)
./media-gen audio --sample-rate 22050 --duration 30 --output fm-radio.wav

# CD quality (44.1kHz)
./media-gen audio --sample-rate 44100 --bitrate 1411k --format wav --output cd-quality.wav

# Professional quality (48kHz)
./media-gen audio --sample-rate 48000 --bitrate 320k --format wav --output pro-audio.wav

# High-resolution audio (96kHz)
./media-gen audio --sample-rate 96000 --format flac --output hi-res.flac
```

### Different Formats and Codecs
```bash
# MP3 (universal compatibility)
./media-gen audio --format mp3 --codec libmp3lame --bitrate 320k --output universal.mp3

# WAV (uncompressed)
./media-gen audio --format wav --codec pcm_s16le --output uncompressed.wav

# AAC (modern compression)
./media-gen audio --format aac --codec aac --bitrate 256k --output modern.aac

# FLAC (lossless compression)
./media-gen audio --format flac --sample-rate 48000 --output lossless.flac
```

### Bitrate Testing
```bash
# Low bitrate (for bandwidth testing)
./media-gen audio --bitrate 64k --output low-bitrate.mp3

# Standard bitrate
./media-gen audio --bitrate 128k --output standard.mp3

# High bitrate
./media-gen audio --bitrate 320k --output high-bitrate.mp3

# Variable bitrate simulation (using high quality)
./media-gen audio --bitrate 320k --format mp3 --output vbr-sim.mp3
```

### Podcast and Streaming
```bash
# Podcast quality (mono simulation)
./media-gen audio --sample-rate 22050 --bitrate 64k --duration 300 --output podcast.mp3

# Music streaming quality
./media-gen audio --sample-rate 44100 --bitrate 256k --duration 180 --output streaming.mp3

# High-quality streaming
./media-gen audio --sample-rate 48000 --bitrate 320k --duration 180 --output hq-streaming.mp3
```

## 🔄 Batch Generation Scripts

### Generate Multiple Test Files
```bash
#!/bin/bash
# generate-test-suite.sh

echo "Generating video test suite..."

# Mobile formats
./media-gen video --width 720 --height 1280 --duration 10 --output mobile-portrait.mp4
./media-gen video --width 1280 --height 720 --duration 10 --output mobile-landscape.mp4

# Web formats
./media-gen video --width 640 --height 360 --bitrate 500k --duration 15 --output web-360p.mp4
./media-gen video --width 854 --height 480 --bitrate 1000k --duration 15 --output web-480p.mp4
./media-gen video --width 1280 --height 720 --bitrate 2500k --duration 15 --output web-720p.mp4

echo "Generating audio test suite..."

# Audio formats
./media-gen audio --sample-rate 22050 --bitrate 128k --duration 30 --output audio-22k.mp3
./media-gen audio --sample-rate 44100 --bitrate 192k --duration 30 --output audio-44k.mp3
./media-gen audio --sample-rate 48000 --bitrate 320k --duration 30 --output audio-48k.mp3

echo "Test suite generation complete!"
```

### Quality Comparison Set
```bash
#!/bin/bash
# generate-quality-comparison.sh

DURATION=30
BASE_NAME="quality-test"

echo "Generating quality comparison videos..."

# Different bitrates, same resolution
./media-gen video --width 1920 --height 1080 --bitrate 500k --duration $DURATION --output "${BASE_NAME}-500k.mp4"
./media-gen video --width 1920 --height 1080 --bitrate 1000k --duration $DURATION --output "${BASE_NAME}-1000k.mp4"
./media-gen video --width 1920 --height 1080 --bitrate 2500k --duration $DURATION --output "${BASE_NAME}-2500k.mp4"
./media-gen video --width 1920 --height 1080 --bitrate 5000k --duration $DURATION --output "${BASE_NAME}-5000k.mp4"

echo "Quality comparison set complete!"
```

## 🧪 Testing Scenarios

### Performance Testing
```bash
# Quick generation test (should be fast)
time ./media-gen video --duration 1 --width 320 --height 240 --output perf-test-small.mp4

# Medium generation test
time ./media-gen video --duration 10 --width 1280 --height 720 --output perf-test-medium.mp4

# Large generation test (stress test)
time ./media-gen video --duration 60 --width 1920 --height 1080 --bitrate 5000k --output perf-test-large.mp4
```

### Compatibility Testing
```bash
# Test different containers with same codec
./media-gen video --codec libx264 --format mp4 --output compat-h264.mp4
./media-gen video --codec libx264 --format avi --output compat-h264.avi
./media-gen video --codec libx264 --format mkv --output compat-h264.mkv

# Test different audio containers
./media-gen audio --codec libmp3lame --format mp3 --output compat-mp3.mp3
./media-gen audio --codec pcm_s16le --format wav --output compat-wav.wav
./media-gen audio --codec aac --format aac --output compat-aac.aac
```

### Edge Cases
```bash
# Very short duration
./media-gen video --duration 1 --output edge-short.mp4
./media-gen audio --duration 1 --output edge-short.mp3

# Very small resolution
./media-gen video --width 160 --height 120 --duration 5 --output edge-tiny.mp4

# Very low bitrate
./media-gen video --bitrate 100k --duration 10 --output edge-low-bitrate.mp4
./media-gen audio --bitrate 32k --duration 10 --output edge-low-bitrate.mp3
```

## 📊 File Size Estimation

### Approximate Video File Sizes (per minute)
- **480p @ 500k**: ~3.75 MB/min
- **720p @ 1000k**: ~7.5 MB/min  
- **1080p @ 2500k**: ~18.75 MB/min
- **4K @ 15000k**: ~112.5 MB/min

### Approximate Audio File Sizes (per minute)
- **64k MP3**: ~0.48 MB/min
- **128k MP3**: ~0.96 MB/min
- **320k MP3**: ~2.4 MB/min
- **1411k WAV**: ~10.6 MB/min

## 💡 Tips and Best Practices

### For Development Testing
- Use short durations (5-10 seconds) for quick iteration
- Start with lower resolutions and bitrates for faster generation
- Use consistent naming conventions for easy file management

### For Production Testing
- Generate files that match your target specifications exactly
- Test with multiple formats to ensure compatibility
- Consider file size constraints for your use case

### For Performance Testing
- Generate files of various sizes to test different scenarios
- Use realistic bitrates for your target platform
- Test both quick generation (small files) and stress scenarios (large files)

---

**Need more examples?** Check the main [README.md](README.md) or open an [issue](https://github.com/your-username/media-gen/issues) with your specific use case!