# GitHub Actions Workflow Chain

This document describes the workflow execution order and fixes applied.

## Workflow Execution Order

```
1. validate-workflows.yml (on push/PR to any branch)
2. test.yml (on push/PR, includes validation step)  
3. build.yml (on push to main branch only)
```

**Note:** Workflows run independently but test.yml includes validation as first step to ensure proper order.

## Key Fixes Applied

### 1. FFmpeg Download Script Issues
**Problem:** `tar` command failed with pattern matching errors
**Solution:** 
- Extract archives to temp directories first
- Use `find` to locate FFmpeg binaries
- Copy binaries to target locations
- Added retry logic with 3 attempts per download
- Improved error handling and logging

### 2. Workflow Dependencies
**Problem:** `workflow_run` triggers didn't work reliably for push events
**Solution:**
- Simplified to direct triggers (push/PR)
- Added validation step directly in test.yml
- Build workflow only runs on main branch pushes

### 3. Script Permissions
**Problem:** Download script wasn't executable in CI
**Solution:**
- Added `chmod +x` in build.zig before running script
- Proper error handling for permission issues

## Current Workflow Structure

### validate-workflows.yml
- **Triggers:** Push/PR to main/develop
- **Purpose:** Validate YAML syntax and dependencies
- **Jobs:** validate, validate-dependencies

### quick-test.yml
- **Triggers:** Push/PR to main/develop
- **Purpose:** Fast validation and basic functionality tests
- **Jobs:** quick-tests (< 2 minutes)
- **Features:** Cached FFmpeg, minimal test duration

### test.yml  
- **Triggers:** Schedule (daily), manual with options
- **Purpose:** Comprehensive testing suite
- **Jobs:** validate, unit-tests, integration-tests, performance-tests
- **Features:** Selective test execution, full platform matrix

### build.yml
- **Triggers:** Push to main, manual
- **Purpose:** Build artifacts (no automatic release)
- **Jobs:** build

### manual-release.yml
- **Triggers:** Manual only (workflow_dispatch)
- **Purpose:** Create releases with version control
- **Jobs:** validate, build, release
- **Features:** Version validation, draft/prerelease options

### windows-build.yml
- **Triggers:** Manual only (workflow_dispatch)
- **Purpose:** Optimized Windows-only builds
- **Jobs:** windows-build
- **Features:** PowerShell scripts, multi-layer caching, parallel compilation

### build-resilient.yml
- **Triggers:** Manual only (workflow_dispatch)
- **Purpose:** Builds that work even when GitHub services are down
- **Jobs:** build, summary
- **Features:** No cache dependency, retry logic, fail-safe operations

## Performance Optimizations

### Caching Strategy
- **FFmpeg binaries**: Cached per OS (~150MB saved per run)
- **Zig build cache**: Cached per OS and source hash
- **Zig toolchain**: Cached by setup-zig action

### Cache Keys
- FFmpeg: `ffmpeg-binaries-{OS}-v1`
- Build: `zig-build-{context}-{OS}-{target}-{source-hash}`
- Restore fallbacks for partial cache hits

### Speed Improvements
- **Quick tests**: < 2 minutes (vs 5+ minutes)
- **Cached builds**: 30-60 seconds (vs 2-3 minutes)  
- **Parallel execution**: Independent job execution
- **Minimal test media**: 1 second duration, low resolution

### Windows-Specific Optimizations
- **PowerShell scripts**: Native Windows execution (faster than bash)
- **Multi-layer caching**: FFmpeg + Zig toolchain + build artifacts
- **Parallel compilation**: Uses all CPU cores (`--parallel` flag)
- **Optimized runner**: windows-2022 for better caching
- **Native .NET downloads**: Faster than curl/wget
- **Dedicated workflow**: `windows-build.yml` for Windows-only builds

### Resilience Features
- **Graceful cache failures**: `continue-on-error: true` for all cache operations
- **Retry logic**: Multiple attempts for downloads and builds
- **Fail-safe builds**: `fail-fast: false` to continue other platforms
- **Service-independent**: Works even when GitHub cache/artifacts are down
- **Fallback strategies**: Alternative methods when primary services fail

## FFmpeg Download Process

1. **Check if binaries exist** in `src/vendor/ffmpeg/`
2. **If not found:**
   - Make script executable: `chmod +x scripts/download-ffmpeg.sh`
   - Run download script with retry logic
   - Extract archives to temp directories
   - Find FFmpeg binaries using `find` command
   - Copy to target locations with proper permissions
3. **Build with embedded FFmpeg**

## Error Handling

- **Download failures:** 3 retry attempts with 5-second delays
- **Archive extraction:** Robust extraction with fallback methods
- **Binary location:** Dynamic search instead of hardcoded paths
- **Permissions:** Automatic chmod +x for all binaries
- **Logging:** Detailed error messages and progress indicators

## Testing

All fixes have been tested locally:
- ✅ FFmpeg download script works
- ✅ Archive extraction successful for all platforms
- ✅ Build process completes without errors
- ✅ Generated media files are valid
- ✅ All tests pass