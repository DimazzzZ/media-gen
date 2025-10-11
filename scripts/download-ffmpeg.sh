#!/bin/bash

# Script to download FFmpeg binaries for embedding
set -e

VENDOR_DIR="src/vendor/ffmpeg"
mkdir -p "$VENDOR_DIR"

echo "📥 Downloading FFmpeg binaries for embedding..."

# Function to download with retry
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts: Downloading from $url"
        if curl -L --fail --retry 3 --retry-delay 5 -o "$output" "$url"; then
            echo "✅ Download successful"
            return 0
        else
            echo "❌ Download failed (attempt $attempt/$max_attempts)"
            attempt=$((attempt + 1))
            sleep 5
        fi
    done
    
    echo "❌ All download attempts failed for $url"
    return 1
}

# Linux x86_64
echo "Downloading Linux x86_64..."
mkdir -p "$VENDOR_DIR/linux-x64"
if download_with_retry "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz" "/tmp/ffmpeg-linux64.tar.xz"; then
    tar -xJ --strip-components=2 -C "$VENDOR_DIR/linux-x64" -f "/tmp/ffmpeg-linux64.tar.xz" "*/bin/ffmpeg"
    rm "/tmp/ffmpeg-linux64.tar.xz"
else
    echo "❌ Failed to download Linux FFmpeg"
    exit 1
fi

# Windows x86_64
echo "Downloading Windows x86_64..."
mkdir -p "$VENDOR_DIR/windows-x64"
if download_with_retry "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" "/tmp/ffmpeg-win64.zip"; then
    unzip -o -j "/tmp/ffmpeg-win64.zip" "*/bin/ffmpeg.exe" -d "$VENDOR_DIR/windows-x64"
    rm "/tmp/ffmpeg-win64.zip"
else
    echo "❌ Failed to download Windows FFmpeg"
    exit 1
fi

# macOS x86_64 - try multiple sources
echo "Downloading macOS x86_64..."
mkdir -p "$VENDOR_DIR/macos-x64"
if download_with_retry "https://evermeet.cx/ffmpeg/ffmpeg-6.1.zip" "/tmp/ffmpeg-macos-x64.zip"; then
    unzip -o -j "/tmp/ffmpeg-macos-x64.zip" "ffmpeg" -d "$VENDOR_DIR/macos-x64"
    rm "/tmp/ffmpeg-macos-x64.zip"
elif download_with_retry "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-macos64-gpl.zip" "/tmp/ffmpeg-macos-x64-alt.zip"; then
    unzip -o -j "/tmp/ffmpeg-macos-x64-alt.zip" "*/bin/ffmpeg" -d "$VENDOR_DIR/macos-x64"
    rm "/tmp/ffmpeg-macos-x64-alt.zip"
else
    echo "❌ Failed to download macOS x64 FFmpeg"
    exit 1
fi

# macOS ARM64 - fallback to x64 if not available
echo "Downloading macOS ARM64..."
mkdir -p "$VENDOR_DIR/macos-arm64"
if download_with_retry "https://www.osxexperts.net/ffmpeg6arm.zip" "/tmp/ffmpeg-macos-arm64.zip"; then
    unzip -o -j "/tmp/ffmpeg-macos-arm64.zip" "ffmpeg" -d "$VENDOR_DIR/macos-arm64"
    rm "/tmp/ffmpeg-macos-arm64.zip"
else
    echo "⚠️  ARM64 macOS FFmpeg not available, copying x64 version"
    cp "$VENDOR_DIR/macos-x64/ffmpeg" "$VENDOR_DIR/macos-arm64/"
fi

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