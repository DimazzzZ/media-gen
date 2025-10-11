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

### test.yml  
- **Triggers:** Push/PR to main/develop, schedule, manual
- **Purpose:** Run all tests with validation
- **Jobs:** validate, unit-tests, integration-tests, performance-tests

### build.yml
- **Triggers:** Push to main, manual
- **Purpose:** Build artifacts and create releases
- **Jobs:** build, release

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