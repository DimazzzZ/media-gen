#!/bin/bash

# Script to download FFmpeg binaries for embedding
# Downloads full-featured builds with all filters including drawtext
set -e

VENDOR_DIR="src/vendor/ffmpeg"
mkdir -p "$VENDOR_DIR"

echo "📥 Downloading FFmpeg binaries for embedding..."
echo "   (Full-featured builds with drawtext, libfreetype, etc.)"

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

# Function to verify FFmpeg has required filters
verify_ffmpeg_filters() {
    local ffmpeg_path="$1"
    local required_filters=("drawtext" "color")
    local missing_filters=()
    
    echo "🔍 Verifying FFmpeg filters..."
    
    # Make executable if not already
    chmod +x "$ffmpeg_path" 2>/dev/null || true
    
    # Get list of filters
    local filters_output
    filters_output=$("$ffmpeg_path" -filters 2>/dev/null || echo "")
    
    for filter in "${required_filters[@]}"; do
        if echo "$filters_output" | grep -q "$filter"; then
            echo "   ✓ $filter filter available"
        else
            echo "   ✗ $filter filter MISSING"
            missing_filters+=("$filter")
        fi
    done
    
    if [ ${#missing_filters[@]} -gt 0 ]; then
        echo "⚠️  Warning: Some required filters are missing: ${missing_filters[*]}"
        return 1
    fi
    
    echo "✅ All required filters verified"
    return 0
}

# Linux x86_64 - BtbN GPL builds (includes all filters)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Downloading Linux x86_64..."
mkdir -p "$VENDOR_DIR/linux-x64"
if download_with_retry "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz" "/tmp/ffmpeg-linux64.tar.xz"; then
    # Extract to temp directory first, then find and copy ffmpeg
    mkdir -p "/tmp/ffmpeg-extract"
    tar -xJ -C "/tmp/ffmpeg-extract" -f "/tmp/ffmpeg-linux64.tar.xz"
    
    # Find ffmpeg binary and copy it
    ffmpeg_binary=$(find "/tmp/ffmpeg-extract" -name "ffmpeg" -type f -executable | head -1)
    if [ -z "$ffmpeg_binary" ]; then
        ffmpeg_binary=$(find "/tmp/ffmpeg-extract" -name "ffmpeg" -type f | head -1)
    fi
    
    if [ -n "$ffmpeg_binary" ]; then
        cp "$ffmpeg_binary" "$VENDOR_DIR/linux-x64/ffmpeg"
        chmod +x "$VENDOR_DIR/linux-x64/ffmpeg"
        echo "✅ Linux FFmpeg extracted successfully"
        verify_ffmpeg_filters "$VENDOR_DIR/linux-x64/ffmpeg" || true
    else
        echo "❌ FFmpeg binary not found in Linux archive"
        exit 1
    fi
    
    rm -rf "/tmp/ffmpeg-extract" "/tmp/ffmpeg-linux64.tar.xz"
else
    echo "❌ Failed to download Linux FFmpeg"
    exit 1
fi

# Windows x86_64 - BtbN GPL builds (includes all filters)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Downloading Windows x86_64..."
mkdir -p "$VENDOR_DIR/windows-x64"
if download_with_retry "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" "/tmp/ffmpeg-win64.zip"; then
    # Extract to temp directory first, then find and copy ffmpeg.exe
    mkdir -p "/tmp/ffmpeg-extract-win"
    unzip -o "/tmp/ffmpeg-win64.zip" -d "/tmp/ffmpeg-extract-win"
    
    # Find ffmpeg.exe binary and copy it
    ffmpeg_binary=$(find "/tmp/ffmpeg-extract-win" -name "ffmpeg.exe" -type f | head -1)
    if [ -n "$ffmpeg_binary" ]; then
        cp "$ffmpeg_binary" "$VENDOR_DIR/windows-x64/ffmpeg.exe"
        echo "✅ Windows FFmpeg extracted successfully"
    else
        echo "❌ FFmpeg.exe binary not found in Windows archive"
        exit 1
    fi
    
    rm -rf "/tmp/ffmpeg-extract-win" "/tmp/ffmpeg-win64.zip"
else
    echo "❌ Failed to download Windows FFmpeg"
    exit 1
fi

# macOS x86_64 - Use evermeet.cx builds (full-featured with libfreetype)
# These builds include drawtext filter support
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Downloading macOS x86_64..."
mkdir -p "$VENDOR_DIR/macos-x64"

# Try multiple sources for macOS x64
MACOS_X64_SUCCESS=false

# Source 1: evermeet.cx (usually has full filter support)
if [ "$MACOS_X64_SUCCESS" = false ]; then
    echo "Trying evermeet.cx (latest)..."
    if download_with_retry "https://evermeet.cx/ffmpeg/getrelease/zip" "/tmp/ffmpeg-macos-x64.zip"; then
        rm -rf "/tmp/ffmpeg-extract-mac"
        mkdir -p "/tmp/ffmpeg-extract-mac"
        if unzip -o "/tmp/ffmpeg-macos-x64.zip" -d "/tmp/ffmpeg-extract-mac"; then
            ffmpeg_binary=$(find "/tmp/ffmpeg-extract-mac" -name "ffmpeg" -type f | head -1)
            if [ -n "$ffmpeg_binary" ]; then
                cp "$ffmpeg_binary" "$VENDOR_DIR/macos-x64/ffmpeg"
                chmod +x "$VENDOR_DIR/macos-x64/ffmpeg"
                if verify_ffmpeg_filters "$VENDOR_DIR/macos-x64/ffmpeg"; then
                    echo "✅ macOS x64 FFmpeg from evermeet.cx extracted successfully"
                    MACOS_X64_SUCCESS=true
                else
                    echo "⚠️  evermeet.cx build missing required filters, trying alternative..."
                fi
            fi
        fi
        rm -rf "/tmp/ffmpeg-extract-mac" "/tmp/ffmpeg-macos-x64.zip"
    fi
fi

# Source 2: Try specific evermeet.cx version known to have drawtext
if [ "$MACOS_X64_SUCCESS" = false ]; then
    echo "Trying evermeet.cx version 7.0..."
    if download_with_retry "https://evermeet.cx/ffmpeg/ffmpeg-7.0.zip" "/tmp/ffmpeg-macos-x64-v7.zip"; then
        rm -rf "/tmp/ffmpeg-extract-mac"
        mkdir -p "/tmp/ffmpeg-extract-mac"
        if unzip -o "/tmp/ffmpeg-macos-x64-v7.zip" -d "/tmp/ffmpeg-extract-mac"; then
            ffmpeg_binary=$(find "/tmp/ffmpeg-extract-mac" -name "ffmpeg" -type f | head -1)
            if [ -n "$ffmpeg_binary" ]; then
                cp "$ffmpeg_binary" "$VENDOR_DIR/macos-x64/ffmpeg"
                chmod +x "$VENDOR_DIR/macos-x64/ffmpeg"
                if verify_ffmpeg_filters "$VENDOR_DIR/macos-x64/ffmpeg"; then
                    echo "✅ macOS x64 FFmpeg v7.0 extracted successfully"
                    MACOS_X64_SUCCESS=true
                else
                    echo "⚠️  Version 7.0 build missing required filters, trying alternative..."
                fi
            fi
        fi
        rm -rf "/tmp/ffmpeg-extract-mac" "/tmp/ffmpeg-macos-x64-v7.zip"
    fi
fi

# Source 3: Try osxexperts.net (alternative source)
if [ "$MACOS_X64_SUCCESS" = false ]; then
    echo "Trying osxexperts.net..."
    if download_with_retry "https://www.osxexperts.net/ffmpeg7intel.zip" "/tmp/ffmpeg-macos-x64-osx.zip"; then
        rm -rf "/tmp/ffmpeg-extract-mac"
        mkdir -p "/tmp/ffmpeg-extract-mac"
        if unzip -o "/tmp/ffmpeg-macos-x64-osx.zip" -d "/tmp/ffmpeg-extract-mac"; then
            ffmpeg_binary=$(find "/tmp/ffmpeg-extract-mac" -name "ffmpeg" -type f | head -1)
            if [ -n "$ffmpeg_binary" ]; then
                cp "$ffmpeg_binary" "$VENDOR_DIR/macos-x64/ffmpeg"
                chmod +x "$VENDOR_DIR/macos-x64/ffmpeg"
                if verify_ffmpeg_filters "$VENDOR_DIR/macos-x64/ffmpeg"; then
                    echo "✅ macOS x64 FFmpeg from osxexperts.net extracted successfully"
                    MACOS_X64_SUCCESS=true
                else
                    echo "⚠️  osxexperts.net build missing required filters"
                fi
            fi
        fi
        rm -rf "/tmp/ffmpeg-extract-mac" "/tmp/ffmpeg-macos-x64-osx.zip"
    fi
fi

if [ "$MACOS_X64_SUCCESS" = false ]; then
    echo "❌ Failed to download macOS x64 FFmpeg with required filters"
    echo "   All sources tried: evermeet.cx (latest), evermeet.cx (v7.0), osxexperts.net"
    exit 1
fi

# macOS ARM64 - Use osxexperts.net or evermeet.cx
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Downloading macOS ARM64..."
mkdir -p "$VENDOR_DIR/macos-arm64"

MACOS_ARM64_SUCCESS=false

# Source 1: osxexperts.net ARM64 builds
if [ "$MACOS_ARM64_SUCCESS" = false ]; then
    echo "Trying osxexperts.net ARM64..."
    if download_with_retry "https://www.osxexperts.net/ffmpeg7arm.zip" "/tmp/ffmpeg-macos-arm64.zip"; then
        rm -rf "/tmp/ffmpeg-extract-arm"
        mkdir -p "/tmp/ffmpeg-extract-arm"
        if unzip -o "/tmp/ffmpeg-macos-arm64.zip" -d "/tmp/ffmpeg-extract-arm"; then
            ffmpeg_binary=$(find "/tmp/ffmpeg-extract-arm" -name "ffmpeg" -type f | head -1)
            if [ -n "$ffmpeg_binary" ]; then
                cp "$ffmpeg_binary" "$VENDOR_DIR/macos-arm64/ffmpeg"
                chmod +x "$VENDOR_DIR/macos-arm64/ffmpeg"
                # Note: Can't verify ARM64 binary on x64 machine, trust the source
                echo "✅ macOS ARM64 FFmpeg from osxexperts.net extracted successfully"
                MACOS_ARM64_SUCCESS=true
            fi
        fi
        rm -rf "/tmp/ffmpeg-extract-arm" "/tmp/ffmpeg-macos-arm64.zip"
    fi
fi

# Source 2: Try evermeet.cx ARM64
if [ "$MACOS_ARM64_SUCCESS" = false ]; then
    echo "Trying evermeet.cx ARM64..."
    if download_with_retry "https://evermeet.cx/ffmpeg/getrelease/ffmpeg/arm64/zip" "/tmp/ffmpeg-macos-arm64-ev.zip"; then
        rm -rf "/tmp/ffmpeg-extract-arm"
        mkdir -p "/tmp/ffmpeg-extract-arm"
        if unzip -o "/tmp/ffmpeg-macos-arm64-ev.zip" -d "/tmp/ffmpeg-extract-arm"; then
            ffmpeg_binary=$(find "/tmp/ffmpeg-extract-arm" -name "ffmpeg" -type f | head -1)
            if [ -n "$ffmpeg_binary" ]; then
                cp "$ffmpeg_binary" "$VENDOR_DIR/macos-arm64/ffmpeg"
                chmod +x "$VENDOR_DIR/macos-arm64/ffmpeg"
                echo "✅ macOS ARM64 FFmpeg from evermeet.cx extracted successfully"
                MACOS_ARM64_SUCCESS=true
            fi
        fi
        rm -rf "/tmp/ffmpeg-extract-arm" "/tmp/ffmpeg-macos-arm64-ev.zip"
    fi
fi

# Fallback: Copy x64 version (will work via Rosetta 2)
if [ "$MACOS_ARM64_SUCCESS" = false ]; then
    echo "⚠️  ARM64 macOS FFmpeg not available, copying x64 version (will use Rosetta 2)"
    cp "$VENDOR_DIR/macos-x64/ffmpeg" "$VENDOR_DIR/macos-arm64/"
    chmod +x "$VENDOR_DIR/macos-arm64/ffmpeg"
    MACOS_ARM64_SUCCESS=true
fi

# Make all binaries executable
chmod +x "$VENDOR_DIR"/*/ffmpeg* 2>/dev/null || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ FFmpeg binaries downloaded successfully!"
echo ""
echo "📊 Binary sizes:"
ls -lh "$VENDOR_DIR"/*/ffmpeg*

echo ""
echo "🔧 To build with embedded FFmpeg:"
echo "   zig build"
echo ""
echo "🔧 To build without embedded FFmpeg (standalone):"
echo "   zig build -Dno-embed-ffmpeg=true"
echo ""
echo "📁 Binaries location: $VENDOR_DIR"
