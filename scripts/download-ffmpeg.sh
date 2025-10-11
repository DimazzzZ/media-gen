#!/bin/bash

# Script to download FFmpeg binaries for embedding
set -e

VENDOR_DIR="src/vendor/ffmpeg"
mkdir -p "$VENDOR_DIR"

echo "📥 Downloading FFmpeg binaries for embedding..."

# Linux x86_64
echo "Downloading Linux x86_64..."
mkdir -p "$VENDOR_DIR/linux-x64"
curl -L "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz" \
  | tar -xJ --strip-components=2 -C "$VENDOR_DIR/linux-x64" "*/bin/ffmpeg"

# Windows x86_64
echo "Downloading Windows x86_64..."
mkdir -p "$VENDOR_DIR/windows-x64"
curl -L "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" \
  -o "/tmp/ffmpeg-win64.zip"
unzip -o -j "/tmp/ffmpeg-win64.zip" "*/bin/ffmpeg.exe" -d "$VENDOR_DIR/windows-x64"
rm "/tmp/ffmpeg-win64.zip"

# macOS x86_64
echo "Downloading macOS x86_64..."
mkdir -p "$VENDOR_DIR/macos-x64"
curl -L "https://evermeet.cx/ffmpeg/ffmpeg-6.1.zip" -o "/tmp/ffmpeg-macos-x64.zip"
unzip -o -j "/tmp/ffmpeg-macos-x64.zip" "ffmpeg" -d "$VENDOR_DIR/macos-x64"
rm "/tmp/ffmpeg-macos-x64.zip"

# macOS ARM64
echo "Downloading macOS ARM64..."
mkdir -p "$VENDOR_DIR/macos-arm64"
curl -L "https://www.osxexperts.net/ffmpeg6arm.zip" -o "/tmp/ffmpeg-macos-arm64.zip"
unzip -o -j "/tmp/ffmpeg-macos-arm64.zip" "ffmpeg" -d "$VENDOR_DIR/macos-arm64" || {
  echo "⚠️  ARM64 macOS FFmpeg not available, copying x64 version"
  cp "$VENDOR_DIR/macos-x64/ffmpeg" "$VENDOR_DIR/macos-arm64/"
}
rm -f "/tmp/ffmpeg-macos-arm64.zip"

# Make binaries executable
chmod +x "$VENDOR_DIR"/*/ffmpeg*

echo "✅ FFmpeg binaries downloaded successfully!"
echo "📊 Binary sizes:"
ls -lh "$VENDOR_DIR"/*/ffmpeg*

echo ""
echo "🔧 To build with embedded FFmpeg:"
echo "  zig build"
echo ""
echo "📁 Binaries location: $VENDOR_DIR"