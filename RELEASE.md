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
   - `dxrc-linux` - Contains .AppImage portable app and .deb package
   - `dxrc-macos` - Contains .app portable bundle

If the tag was pushed, artifacts are automatically attached to the GitHub Release.

**All builds are portable** - users can download and run directly without installation!

## Package Formats

All builds are **portable** - no installation required, just download and run!

### Windows
- **EXE** (`dxrc-0.1.0-x86_64.exe`) - Portable standalone executable

### Linux
- **AppImage** (`dxrc-0.1.0-x86_64.AppImage`) - Universal portable Linux app
- **DEB** (`dxrc_0.1.0_amd64.deb`) - Debian/Ubuntu package (optional)

### macOS
- **APP** (`dxrc.app`) - Portable application bundle

## Workflow Triggers

The GitHub Actions workflow runs when:

1. **Tag pushed** (automatic release): `git push origin v*`
2. **Manual trigger**: Go to Actions → Release Desktop Apps → Run workflow

## Manual Workflow Dispatch

To manually trigger builds without creating a tag:

1. Go to GitHub repository
2. Click **Actions** tab
3. Select **Release Desktop Apps** workflow
4. Click **Run workflow** button
5. Choose branch and click **Run workflow**

This is useful for testing the build process without creating an official release.

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

After running `dx bundle --platform desktop --release` locally:

```
dxrc/
└── dist/
    └── bundle/
        ├── deb/          # Linux .deb packages
        ├── appimage/     # Linux .AppImage (portable)
        ├── nsis/         # Windows .exe executable (portable)
        └── macos/        # macOS .app bundle (portable)
```

## Dioxus CLI Version Management

This project uses **Dioxus CLI 0.7.0-rc.3** to ensure consistency across local and CI/CD builds.

### Install Locally

```bash
# Use the provided script
./install-dx.sh

# Or install specific version manually
cargo install dioxus-cli --version 0.7.0-rc.3 --locked
```

### Updating Dioxus CLI Version

When upgrading to a new Dioxus CLI version:

1. Update `install-dx.sh` default version (line 6)
2. Update `.github/workflows/release.yml` (line 61)
3. Test locally: `./install-dx.sh <new-version>`
4. Commit and test workflow

**Current version**: 0.7.0-rc.3

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
