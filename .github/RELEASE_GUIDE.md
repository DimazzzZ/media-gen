# Release Guide

This guide explains how to create releases for the Media Generator project.

## 🚀 Creating a Release

### Prerequisites
- All tests must be passing on main branch
- Code changes should be merged and tested
- Version number should follow [Semantic Versioning](https://semver.org/)

### Steps

1. **Navigate to Actions**
   - Go to the [Actions tab](../../actions)
   - Select "Manual Release" workflow

2. **Run Workflow**
   - Click "Run workflow" button
   - Fill in the required parameters:

   | Parameter | Description | Example |
   |-----------|-------------|----------|
   | **Version** | Release version (must start with 'v') | `v1.0.0` |
   | **Pre-release** | Mark as beta/alpha release | `false` |
   | **Draft** | Create as draft for review | `false` |

3. **Monitor Progress**
   - The workflow will validate the version
   - Build artifacts for all platforms
   - Create the GitHub release

4. **Verify Release**
   - Check the [Releases page](../../releases)
   - Download and test artifacts
   - Update release notes if needed

## 📋 Version Guidelines

### Format
- Must follow format: `vMAJOR.MINOR.PATCH`
- Examples: `v1.0.0`, `v2.1.3`, `v0.5.0`

### When to Increment
- **MAJOR**: Breaking changes, incompatible API changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

### Pre-release Versions
- Use for beta/alpha releases: `v1.0.0-beta.1`
- Mark "Pre-release" checkbox in workflow

## 🔧 Troubleshooting

### Common Issues

**"Tag already exists"**
- Choose a different version number
- Check existing releases to avoid conflicts

**"Invalid version format"**
- Ensure version starts with 'v'
- Follow semver format: `v1.2.3`

**"Build failed"**
- Check if all tests pass on main branch
- Verify FFmpeg download is working
- Check individual job logs for details

### Getting Help

- Check [workflow logs](../../actions) for detailed error messages
- Review [WORKFLOW_CHAIN.md](WORKFLOW_CHAIN.md) for technical details
- Open an issue if problems persist

## 📦 Release Artifacts

Each release includes:

| Platform | File | Description |
|----------|------|-------------|
| **Linux x86_64** | `media-gen-linux-x86_64` | Executable for Linux |
| **Windows x86_64** | `media-gen-windows-x86_64.exe` | Executable for Windows |
| **macOS Intel** | `media-gen-macos-x86_64` | Executable for Intel Macs |
| **macOS ARM64** | `media-gen-macos-arm64` | Executable for Apple Silicon Macs |

### File Sizes
- Each executable is ~45-50MB (includes embedded FFmpeg)
- No external dependencies required
- Ready to run out of the box

## 🎯 Best Practices

1. **Test Before Release**
   - Run local tests: `zig build test`
   - Test on multiple platforms if possible
   - Verify all features work as expected

2. **Write Good Release Notes**
   - Highlight new features and improvements
   - List any breaking changes
   - Include usage examples for new features

3. **Use Semantic Versioning**
   - Be consistent with version numbering
   - Clearly communicate the type of changes

4. **Draft Releases for Review**
   - Use draft option for major releases
   - Allow team review before publishing
   - Test download links and artifacts

## 📈 Release History

See [CHANGELOG.md](../CHANGELOG.md) for detailed version history and changes.