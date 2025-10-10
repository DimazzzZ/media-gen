# CI/CD Documentation

This directory contains GitHub Actions workflows for the Media Generator project.

## Workflows

### 1. `build.yml` - Main Build and Test Pipeline
- **Triggers**: Push to main/develop, Pull requests, Manual dispatch
- **Purpose**: Runs tests and builds for all platforms
- **Outputs**: Release artifacts for Linux, Windows, macOS (Intel & ARM)
- **Features**:
  - Unit and integration tests
  - Cross-platform builds
  - Automatic releases on main branch

### 2. `manual-build.yml` - Manual Build Workflow
- **Triggers**: Manual dispatch only
- **Purpose**: Allows manual building for specific platforms
- **Options**:
  - Platform selection (all, linux, windows, macos, or combinations)
  - Optimization level (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
- **Use case**: Testing specific configurations or building for specific platforms

### 3. `test.yml` - Comprehensive Test Suite
- **Triggers**: Push, Pull requests, Daily schedule, Manual dispatch
- **Purpose**: Runs comprehensive tests across multiple platforms
- **Test types**:
  - Unit tests
  - Integration tests (video/audio generation)
  - Performance tests
  - Cross-platform compatibility tests

### 4. `validate-workflows.yml` - Workflow Validation
- **Triggers**: Changes to workflow files, Manual dispatch
- **Purpose**: Validates GitHub Actions workflow files
- **Checks**:
  - YAML syntax validation
  - Required fields verification
  - Security best practices
  - Action version checking

## Manual Workflow Usage

### Building for Specific Platforms

1. Go to the "Actions" tab in GitHub
2. Select "Manual Build" workflow
3. Click "Run workflow"
4. Choose your options:
   - **Platforms**: Select which platforms to build for
   - **Optimization**: Choose optimization level
5. Click "Run workflow"

### Available Platform Options
- `all` - Build for all platforms (Linux, Windows, macOS Intel, macOS ARM)
- `linux` - Linux x86_64 only
- `windows` - Windows x86_64 only
- `macos` - macOS Intel and ARM
- `linux,windows` - Linux and Windows
- `linux,macos` - Linux and macOS
- `windows,macos` - Windows and macOS

### Optimization Levels
- `Debug` - Debug build with symbols
- `ReleaseSafe` - Optimized with safety checks
- `ReleaseFast` - Maximum performance optimization
- `ReleaseSmall` - Optimized for size

## Artifacts

Build artifacts are automatically uploaded and can be downloaded from:
- Workflow run pages (for manual builds)
- Release pages (for automatic releases)

Artifact naming convention:
- `media-gen-linux-x86_64` - Linux binary
- `media-gen-windows-x86_64.exe` - Windows executable
- `media-gen-macos-x86_64` - macOS Intel binary
- `media-gen-macos-arm64` - macOS ARM binary

## Testing

### Local Testing
```bash
# Run unit tests
zig build test

# Build and test manually
zig build
./zig-out/bin/media-gen video --duration 2 --output test.mp4
./zig-out/bin/media-gen audio --duration 2 --output test.mp3
```

### CI Testing
Tests run automatically on:
- Every push to main/develop branches
- Every pull request
- Daily at 2 AM UTC (scheduled)
- Manual trigger

### Test Coverage
- Unit tests for CLI argument parsing
- Integration tests for video/audio generation
- Cross-platform compatibility tests
- Performance benchmarks
- Error handling tests

## Requirements

### Build Requirements
- Zig 0.15.1+
- FFmpeg (for media generation)

### Platform-Specific Notes

#### Linux (Ubuntu)
- FFmpeg installed via apt
- Standard build process

#### Windows
- FFmpeg installed via Chocolatey
- Uses Windows-specific paths

#### macOS
- FFmpeg installed via Homebrew
- Supports both Intel and ARM architectures

## Security

### Best Practices Implemented
- Pinned action versions where possible
- Minimal required permissions
- Secure artifact handling
- No hardcoded secrets in workflows

### Secrets Used
- `GITHUB_TOKEN` - Automatic token for releases (provided by GitHub)

## Troubleshooting

### Common Issues

1. **FFmpeg not found**
   - Ensure FFmpeg is properly installed on the runner
   - Check PATH configuration

2. **Build failures**
   - Verify Zig version compatibility
   - Check for platform-specific issues

3. **Test failures**
   - Ensure generated files have reasonable sizes
   - Check FFmpeg functionality

4. **Workflow validation errors**
   - Verify YAML syntax
   - Check for required fields
   - Ensure proper indentation

### Getting Help
- Check workflow logs for detailed error messages
- Review test output for specific failures
- Ensure all dependencies are properly installed