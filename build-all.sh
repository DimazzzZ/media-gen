#!/bin/bash

echo "Building media-gen for all platforms..."

# Clean previous builds
rm -rf zig-out/

# Build for different platforms
echo "Building for Linux x86_64..."
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe
cp zig-out/bin/media-gen media-gen-linux-x86_64

echo "Building for Windows x86_64..."
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe
cp zig-out/bin/media-gen.exe media-gen-windows-x86_64.exe

echo "Building for macOS x86_64..."
zig build -Dtarget=x86_64-macos -Doptimize=ReleaseSafe
cp zig-out/bin/media-gen media-gen-macos-x86_64

echo "Building for macOS ARM64..."
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSafe
cp zig-out/bin/media-gen media-gen-macos-arm64

echo "All builds completed!"
echo "Files created:"
ls -la media-gen-*