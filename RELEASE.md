# Release Process Documentation

## Overview

This project uses GitHub Actions for automated cross-platform desktop builds. The CI/CD pipeline builds desktop applications for Windows, Linux, and macOS automatically when you create a new release tag.

## Generated Icons

All platform-specific icons have been generated from `assets/appicon.png`:

- `icon.png` (512x512) - Linux AppImage/Deb packages
- `icon.ico` (multi-size) - Windows executable and installer
- `icon.icns` (multi-resolution) - macOS app bundle and DMG

To regenerate icons from a custom source image:

```bash
# Replace assets/appicon.png with your 1024x1024 source image, then:
cd assets

# Generate standard PNG
magick appicon.png -resize 512x512 icon.png

# Generate Windows ICO
magick appicon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico

# Generate macOS ICNS
mkdir -p icon.iconset
for size in 16 32 64 128 256 512; do
  magick appicon.png -resize ${size}x${size} icon.iconset/icon_${size}x${size}.png
done
for size in 32 64 256 512; do
  magick appicon.png -resize ${size}x${size} icon.iconset/icon_$((size/2))x$((size/2))@2x.png
done
iconutil -c icns icon.iconset -o icon.icns
rm -rf icon.iconset
```

## Local Development

### Desktop Testing (macOS)

```bash
# Run in development mode
dx serve --platform desktop

# Build local macOS bundle
dx bundle --platform desktop --release
```

### Mobile Testing (iOS & Android)

```bash
# iOS (requires macOS, Xcode, and iOS simulator)
dx serve --platform ios

# Android (requires Android SDK/NDK)
dx serve --platform android
```

### Web Testing

```bash
# Development server
dx serve --platform web

# Production build
dx bundle --platform web --release
```

## Creating a Release

### 1. Update Version

Update the version in both files:

**Cargo.toml**:
```toml
[package]
version = "0.2.0"  # Update this
```

**Dioxus.toml**:
```toml
[bundle]
version = "0.2.0"  # Update this to match
```

### 2. Commit Changes

```bash
git add .
git commit -m "Release v0.2.0"
git push origin main
```

### 3. Create and Push Tag

```bash
# Create annotated tag
git tag -a v0.2.0 -m "Release version 0.2.0"

# Push tag to trigger workflow
git push origin v0.2.0
```

### 4. Monitor Build Progress

1. Go to your repository on GitHub
2. Navigate to **Actions** tab
3. Watch the "Release Desktop Apps" workflow
4. The workflow builds for all three platforms in parallel

### 5. Download Artifacts

Once the workflow completes:

1. Go to **Actions** → **Release Desktop Apps** → Latest run
2. Download portable artifacts:
   - `dxrc-windows` - Contains .exe portable executable
   - `dxrc-linux` - Contains .AppImage portable app
   - `dxrc-macos` - Contains .app.zip (zipped app bundle)

If the tag was pushed, artifacts are automatically attached to the GitHub Release.

**All builds are portable** - users can download and run directly without installation!

## Package Formats

All builds are **portable** - no installation required, just download and run!

### Windows
- **EXE** (`dxrc-0.1.0-x86_64.exe`) - Portable standalone executable

### Linux
- **AppImage** (`dxrc-0.1.0-x86_64.AppImage`) - Universal portable Linux app

### macOS
- **APP** (`dxrc.app.zip`) - Zipped portable application bundle (extract and run)
- **Note**: Unsigned app - see "macOS Security" section below for how to run

## Workflow Triggers

Each platform has its own independent workflow for better isolation and debugging.

### Available Workflows

1. **Build macOS** - Builds macOS .app bundle
2. **Build Windows** - Builds Windows .exe portable
3. **Build Linux** - Builds Linux .AppImage and .deb

### Manual Workflow Dispatch

To trigger builds manually:

1. Go to your GitHub repository: `https://github.com/deckyfx/LearningDioxus`
2. Click **Actions** tab
3. Select the platform workflow (e.g., "Build macOS")
4. Click **Run workflow** button (top right)
5. Select branch (usually `main`)
6. Click the green **Run workflow** button

### Benefits of Separate Workflows

✅ **Independent execution** - One platform failure doesn't cancel others
✅ **Easier debugging** - Clear logs per platform
✅ **Faster iterations** - Test only the platform you're working on
✅ **Parallel execution** - All can run simultaneously if triggered together

### Optional: Enable Auto-Trigger on Tags

If you want to enable automatic builds when creating release tags, uncomment lines in `.github/workflows/release.yml`:

```yaml
on:
  workflow_dispatch:

  # Uncomment these lines to enable auto-trigger on tags:
  push:
    tags:
      - 'v*'
```

Then you can create releases with:
```bash
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

### Current Configuration

✅ **Manual trigger**: Enabled (primary method)
❌ **Auto-trigger on push**: Disabled
⚠️ **Auto-trigger on tags**: Disabled (can be enabled)

## Windows Toolchain Choice

We use **`x86_64-pc-windows-msvc`** (Microsoft Visual C++ toolchain) for Windows builds.

### Why MSVC over GNU?

**MSVC (Microsoft Visual C++)**:
- ✅ Official Microsoft toolchain
- ✅ Better Windows integration and compatibility
- ✅ Better performance with Windows-specific features
- ✅ Standard for Dioxus desktop apps
- ✅ Required for some Windows libraries

**GNU (MinGW-w64)** - Alternative option:
- Good for cross-compiling from Linux
- Fully open-source toolchain
- May have compatibility issues with some Windows libraries

**Current setup**: The GitHub Actions workflow uses `x86_64-pc-windows-msvc` on `windows-latest` runners.

## Platform-Specific Build Paths

We use `--out-dir="dist"` for predictable output paths:

```bash
# Build commands
dx bundle --macos --release --package-types="macos" --out-dir="dist"
dx bundle --windows --release --package-types="nsis" --out-dir="dist"
dx bundle --linux --release --package-types="appimage" --out-dir="dist"
```

**Output location**: All artifacts go to `dist/` folder:
```
dist/
├── Dxrc.app           # macOS app bundle
├── dxrc.exe           # Windows portable executable
├── dxrc.AppImage      # Linux portable app
└── dxrc.deb           # Linux Debian package
```

**Example**: `Bundled app at: /path/to/dxrc/dist/Dxrc.app`

## Dioxus CLI Version Management

This project uses **Dioxus CLI 0.7.0-rc.3** and installs pre-built binaries from GitHub releases (much faster than compiling from source!).

### Install Locally

**macOS/Linux:**
```bash
# Install specific version (recommended)
./install-dx-rc.sh v0.7.0-rc.3

# Or install latest RC/pre-release
./install-dx-rc.sh

# Or install latest stable only
./install-dx-rc.sh --stable
```

**Windows (PowerShell):**
```powershell
# Install specific version (recommended)
.\install-dx-rc.ps1 v0.7.0-rc.3

# Or install latest RC/pre-release
.\install-dx-rc.ps1

# Or install latest stable only
.\install-dx-rc.ps1 -Stable
```

**Installation Location:** `~/.dx/bin/dx` (also copied to `~/.cargo/bin/dx` if it exists)

### Why Use These Scripts Instead of Cargo?

- ✅ **Much faster** - Downloads pre-built binaries instead of compiling
- ✅ **RC versions available** - Can install pre-release/RC versions not yet on crates.io
- ✅ **Auto-update** - Built-in version checking and update capability
- ✅ **Cross-platform** - Works on macOS, Linux, and Windows

### Updating Dioxus CLI Version

When upgrading to a new Dioxus CLI version:

1. Update `.github/workflows/release.yml` (lines 73 and 82)
2. Test locally:
   - Unix: `./install-dx-rc.sh v<new-version>`
   - Windows: `.\install-dx-rc.ps1 v<new-version>`
3. Commit and test workflow

**Current version**: v0.7.0-rc.3

## macOS Security - "App is damaged" Error

When you download and extract the app, macOS shows: **"Dxrc.app is damaged and can't be opened. You should move it to the Trash."**

This is NOT a real virus or damage - it's macOS quarantine protection for unsigned apps.

### Fix (REQUIRED - Only takes 10 seconds):

**Option 1: Terminal Command (Recommended)**
```bash
# After extracting the zip, open Terminal and run:
cd ~/Downloads  # or wherever you extracted the app
xattr -cr Dxrc.app
```

Then double-click `Dxrc.app` to open normally.

**Option 2: One-Line Command**
```bash
# If app is in Downloads folder:
xattr -cr ~/Downloads/Dxrc.app && open ~/Downloads/Dxrc.app
```

### Why This Happens

- Apps built on GitHub Actions are unsigned
- macOS quarantines all downloaded files as security measure
- `xattr -cr` removes the quarantine attribute
- Only needed once per download
- Your locally-built apps don't have this issue

### For Local Development
```bash
# After building locally
dx bundle --platform desktop --release
xattr -cr dist/Dxrc.app
open dist/Dxrc.app
```

## Troubleshooting

### Build Fails on Specific Platform

Check the Actions log for that platform. Common issues:

**Linux**: Missing system dependencies (WebKit, GTK)
- Solution: Workflow installs `libwebkit2gtk-4.1-dev` and dependencies automatically
- **Note**: Ubuntu 24.04 uses `libwebkit2gtk-4.1-dev` (not 4.0)

**Windows**: WiX toolset issues
- Solution: Ensure `wix = true` in Dioxus.toml

**macOS**: Code signing (if enabled)
- Solution: Disable signing or configure certificates in GitHub Secrets

**Dioxus CLI Version Mismatch**:
- Solution: Ensure `install-dx.sh` and workflow use same version

### Artifacts Not Uploaded

Check if bundles were created:
- View workflow logs
- Look for "Upload artifacts" step
- Verify `dist/bundle/` contains files

### Version Mismatch

Ensure versions match in:
1. `Cargo.toml` → `[package] version`
2. `Dioxus.toml` → `[bundle] version`
3. Git tag (e.g., `v0.1.0`)

## Code Signing (Future Enhancement)

For production distribution, you'll need to sign your apps:

- **macOS**: Apple Developer certificate + notarization
- **Windows**: Code signing certificate
- **Linux**: GPG signing for packages

Refer to [Tauri signing documentation](https://tauri.app/distribute/sign/) for detailed guides.

## Next Steps

1. Customize app icon by replacing `assets/appicon.png` and regenerating
2. Update app metadata in `Dioxus.toml`
3. Configure code signing for production releases
4. Set up automatic changelog generation
5. Add release notes template
