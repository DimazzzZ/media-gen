# CI/CD Troubleshooting Guide

This guide helps resolve common issues with GitHub Actions workflows.

## 🚨 Current GitHub Service Issues

### Cache Service Down (400 errors)
**Symptoms:**
- `Failed to restore: Cache service responded with 400`
- `Failed to save: <h2>Our services aren't available right now</h2>`

**Solutions:**
1. **Use Resilient Build**: Run `build-resilient.yml` workflow
   - Go to Actions → "Resilient Build (No External Dependencies)"
   - Check "Skip caching" option
   - This workflow works without GitHub cache service

2. **Manual workaround**: 
   ```bash
   # Locally pre-download FFmpeg
   ./scripts/download-ffmpeg.sh
   git add src/vendor/ffmpeg
   git commit -m "Add pre-downloaded FFmpeg for CI"
   git push
   ```

### Artifact Upload Failures
**Symptoms:**
- `Failed to CreateArtifact: Unable to make request: ENOTFOUND`
- `The operation was canceled`

**Solutions:**
1. **Check build success**: Even if upload fails, build may have succeeded
2. **Use resilient workflow**: Artifacts are optional in `build-resilient.yml`
3. **Manual download**: SSH into runner and download artifacts manually

## 🔧 Common Build Issues

### FFmpeg Download Failures
**Symptoms:**
- `tar: Pattern matching characters used in file names`
- `Download script failed with exit code: 2`

**Solutions:**
1. **Use PowerShell script** (Windows):
   ```powershell
   .\scripts\download-ffmpeg-windows.ps1
   ```

2. **Fix tar patterns** (Unix):
   ```bash
   # Use updated script without wildcards
   chmod +x ./scripts/download-ffmpeg.sh
   ./scripts/download-ffmpeg.sh
   ```

### Windows Build Slow
**Symptoms:**
- Windows builds taking 5+ minutes
- Timeout errors on Windows

**Solutions:**
1. **Use optimized Windows workflow**:
   - Actions → "Windows Build (Optimized)"
   - Uses PowerShell and parallel compilation

2. **Enable parallel builds**:
   ```bash
   zig build --parallel -Doptimize=ReleaseFast
   ```

### macOS Runner Issues
**Symptoms:**
- `macos-13` vs `macos-latest` confusion
- ARM64 vs Intel build issues

**Solutions:**
1. **Use specific runners**:
   - Intel: `macos-13`
   - ARM64: `macos-latest`

2. **Check target architecture**:
   ```bash
   zig build -Dtarget=x86_64-macos    # Intel
   zig build -Dtarget=aarch64-macos   # ARM64
   ```

## 🛠️ Workflow Selection Guide

### When to use each workflow:

| Situation | Recommended Workflow | Reason |
|-----------|---------------------|---------|
| **Normal development** | `quick-test.yml` | Fast feedback on PRs |
| **GitHub cache is down** | `build-resilient.yml` | No external dependencies |
| **Windows optimization needed** | `windows-build.yml` | PowerShell + parallel builds |
| **Full testing** | `test.yml` | Comprehensive platform testing |
| **Creating releases** | `manual-release.yml` | Version control + artifacts |
| **Emergency builds** | `build-resilient.yml` | Works in any conditions |

## 🔍 Debugging Steps

### 1. Check GitHub Status
- Visit [GitHub Status](https://www.githubstatus.com/)
- Look for issues with Actions, Packages, or API

### 2. Identify the Problem
```bash
# Check recent workflow runs
gh run list --limit 5

# View specific run details
gh run view <run-id>

# Download logs
gh run download <run-id>
```

### 3. Try Alternative Workflows
```bash
# If normal build fails, try resilient
gh workflow run build-resilient.yml

# For Windows-specific issues
gh workflow run windows-build.yml

# For quick validation
gh workflow run quick-test.yml
```

### 4. Local Reproduction
```bash
# Test locally first
zig build test
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe

# Test FFmpeg download
./scripts/download-ffmpeg.sh
```

## 📊 Performance Expectations

### Normal Conditions (with cache):
- **Quick tests**: 1-2 minutes
- **Full build**: 2-4 minutes
- **Windows build**: 2-3 minutes
- **Release**: 8-12 minutes

### Degraded Conditions (no cache):
- **Quick tests**: 3-4 minutes
- **Full build**: 5-8 minutes
- **Windows build**: 4-6 minutes
- **Release**: 15-20 minutes

## 🆘 Emergency Procedures

### Complete GitHub Actions Outage
1. **Build locally**:
   ```bash
   ./scripts/download-ffmpeg.sh
   zig build -Doptimize=ReleaseSafe
   ```

2. **Create manual release**:
   ```bash
   # Build all platforms locally
   zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe
   zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe
   zig build -Dtarget=x86_64-macos -Doptimize=ReleaseSafe
   zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSafe
   
   # Upload manually via GitHub web interface
   ```

### Cache Corruption
1. **Clear all caches**:
   - Go to repository Settings → Actions → Caches
   - Delete all cache entries
   - Run `build-resilient.yml` to rebuild fresh

2. **Update cache keys**:
   ```yaml
   # Increment version in cache keys
   key: ffmpeg-binaries-${{ matrix.os }}-v2  # was v1
   ```

## 📞 Getting Help

1. **Check this guide first**
2. **Review workflow logs** in GitHub Actions
3. **Try resilient workflows** before reporting issues
4. **Check GitHub Status** for service outages
5. **Open issue** with full error logs and context

## 🔄 Recovery Checklist

- [ ] Identified the failing component (cache/artifacts/build)
- [ ] Checked GitHub Status for known issues
- [ ] Tried appropriate alternative workflow
- [ ] Verified local build works
- [ ] Documented the issue for future reference