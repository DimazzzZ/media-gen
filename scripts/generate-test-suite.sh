#!/bin/bash

# Media Generator Test Suite Generator
# This script generates a comprehensive set of test media files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MEDIA_GEN="./zig-out/bin/media-gen"
OUTPUT_DIR="test-media"
DURATION=5  # Short duration for quick testing

echo -e "${BLUE}🎬 Media Generator Test Suite${NC}"
echo "=================================="

# Check if media-gen exists
if [ ! -f "$MEDIA_GEN" ]; then
    echo -e "${RED}❌ media-gen not found at $MEDIA_GEN${NC}"
    echo "Please build the project first: zig build"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo -e "${YELLOW}📁 Created output directory: $OUTPUT_DIR${NC}"

echo ""
echo -e "${BLUE}🎥 Generating Video Test Files...${NC}"

# Video test files
declare -a video_tests=(
    "--width 640 --height 480 --output $OUTPUT_DIR/video-480p.mp4"
    "--width 1280 --height 720 --output $OUTPUT_DIR/video-720p.mp4"
    "--width 1920 --height 1080 --output $OUTPUT_DIR/video-1080p.mp4"
    "--width 720 --height 1280 --output $OUTPUT_DIR/video-mobile-portrait.mp4"
    "--width 1080 --height 1080 --output $OUTPUT_DIR/video-square.mp4"
    "--format avi --output $OUTPUT_DIR/video-avi.avi"
    "--format mov --output $OUTPUT_DIR/video-mov.mov"
    "--codec libx265 --output $OUTPUT_DIR/video-h265.mp4"
    "--bitrate 500k --output $OUTPUT_DIR/video-low-bitrate.mp4"
    "--bitrate 5000k --output $OUTPUT_DIR/video-high-bitrate.mp4"
    "--fps 60 --output $OUTPUT_DIR/video-60fps.mp4"
)

for test in "${video_tests[@]}"; do
    echo -e "${YELLOW}  Generating:${NC} $test"
    $MEDIA_GEN video --duration $DURATION $test
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✅ Success${NC}"
    else
        echo -e "${RED}  ❌ Failed${NC}"
    fi
done

echo ""
echo -e "${BLUE}🎵 Generating Audio Test Files...${NC}"

# Audio test files
declare -a audio_tests=(
    "--sample-rate 22050 --output $OUTPUT_DIR/audio-22k.mp3"
    "--sample-rate 44100 --output $OUTPUT_DIR/audio-44k.mp3"
    "--sample-rate 48000 --output $OUTPUT_DIR/audio-48k.mp3"
    "--bitrate 64k --output $OUTPUT_DIR/audio-64k.mp3"
    "--bitrate 128k --output $OUTPUT_DIR/audio-128k.mp3"
    "--bitrate 320k --output $OUTPUT_DIR/audio-320k.mp3"
    "--format wav --output $OUTPUT_DIR/audio-wav.wav"
    "--format aac --output $OUTPUT_DIR/audio-aac.aac"
    "--format flac --sample-rate 48000 --output $OUTPUT_DIR/audio-flac.flac"
)

for test in "${audio_tests[@]}"; do
    echo -e "${YELLOW}  Generating:${NC} $test"
    $MEDIA_GEN audio --duration $DURATION $test
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✅ Success${NC}"
    else
        echo -e "${RED}  ❌ Failed${NC}"
    fi
done

echo ""
echo -e "${BLUE}📊 Test Suite Summary${NC}"
echo "======================"

# Count generated files
video_count=$(find "$OUTPUT_DIR" -name "video-*" | wc -l)
audio_count=$(find "$OUTPUT_DIR" -name "audio-*" | wc -l)
total_count=$((video_count + audio_count))

echo -e "${GREEN}📹 Video files: $video_count${NC}"
echo -e "${GREEN}🎵 Audio files: $audio_count${NC}"
echo -e "${GREEN}📁 Total files: $total_count${NC}"

# Calculate total size
if command -v du &> /dev/null; then
    total_size=$(du -sh "$OUTPUT_DIR" | cut -f1)
    echo -e "${GREEN}💾 Total size: $total_size${NC}"
fi

echo ""
echo -e "${BLUE}📋 Generated Files:${NC}"
ls -la "$OUTPUT_DIR"

echo ""
echo -e "${GREEN}🎉 Test suite generation complete!${NC}"
echo -e "${YELLOW}💡 Files are located in: $OUTPUT_DIR${NC}"
echo -e "${YELLOW}🧪 Use these files for testing your applications${NC}"