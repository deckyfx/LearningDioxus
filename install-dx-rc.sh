#!/usr/bin/env bash
set -eo pipefail

# Dioxus CLI Installer Script
# Downloads pre-built binaries from GitHub releases
# Usage:
#   ./install-dx-rc.sh              - Install latest release (including pre-releases)
#   ./install-dx-rc.sh --stable     - Install latest stable release only
#   ./install-dx-rc.sh v0.7.0-rc.3  - Install specific version

# Reset
Color_Off=''

# Regular Colors
Red=''
Green=''
Dim='' # White

# Bold
Bold_White=''
Bold_Green=''

if [ -t 1 ]; then
    # Reset
    Color_Off='\033[0m' # Text Reset

    # Regular Colors
    Red='\033[0;31m'   # Red
    Green='\033[0;32m' # Green
    Dim='\033[0;2m'    # White

    # Bold
    Bold_Green='\033[1;32m' # Bold Green
    Bold_White='\033[1m'    # Bold White
fi

error() {
    printf "${Red}error${Color_Off}: %s\n" "$@" >&2
    exit 1
}

info() {
    printf "${Dim}%s${Color_Off}\n" "$@"
}

info_bold() {
    printf "${Bold_White}%s${Color_Off}\n" "$@"
}

success() {
    printf "${Green}%s${Color_Off}\n" "$@"
}

command -v unzip >/dev/null ||
    error 'unzip is required to install dx'

command -v curl >/dev/null ||
    error 'curl is required to install dx'

if [ $# -gt 1 ]; then
    error 'Too many arguments, only 1 allowed. Use: ./install-dx-rc.sh [--stable|--update|version]'
fi

# Function to get latest release from GitHub
get_latest_release() {
    local stable_only=$1
    local api_url="https://api.github.com/repos/dioxuslabs/dioxus/releases"

    if [ "$stable_only" = "true" ]; then
        # Get latest stable release (non-pre-release)
        info "Fetching latest stable release..." >&2
        curl -s "$api_url/latest" | grep '"tag_name"' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/'
    else
        # Get latest release (including pre-releases/RC)
        info "Fetching latest release (including pre-releases)..." >&2
        curl -s "$api_url" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": "([^"]+)".*/\1/'
    fi
}

# Function to get currently installed version
get_current_version() {
    if command -v dx >/dev/null 2>&1; then
        dx --version 2>&1 | grep -oE 'dioxus [0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?' | awk '{print $2}'
    else
        echo "not_installed"
    fi
}

if [ "$OS" = "Windows_NT" ]; then
    target="x86_64-pc-windows-msvc"
else
    case $(uname -sm) in
    "Darwin x86_64") target="x86_64-apple-darwin" ;;
    "Darwin arm64") target="aarch64-apple-darwin" ;;
    "Linux aarch64") target="aarch64-unknown-linux-gnu" ;;
    *) target="x86_64-unknown-linux-gnu" ;;
    esac
fi

GITHUB=${GITHUB-"https://github.com"}
github_repo="$GITHUB/dioxuslabs/dioxus"

# Determine which version to install
current_version=$(get_current_version)
stable_only=false

if [ $# = 0 ] || [ "$1" = "--update" ]; then
    # Auto-detect latest release
    dx_version=$(get_latest_release "$stable_only")

    if [ -z "$dx_version" ]; then
        error "Failed to fetch latest release from GitHub API"
    fi

    # Check if update is needed
    if [ "$current_version" != "not_installed" ]; then
        info "Currently installed: v$current_version"
        if [ "$current_version" = "${dx_version#v}" ]; then
            success "Already up to date! (v$current_version)"
            exit 0
        else
            info_bold "Update available: $current_version → ${dx_version#v}"
        fi
    fi

    dx_uri=$github_repo/releases/download/$dx_version/dx-$target.zip
    info_bold "Installing Dioxus CLI $dx_version"
elif [ "$1" = "--stable" ]; then
    # Get latest stable only
    stable_only=true
    dx_version=$(get_latest_release "$stable_only")

    if [ -z "$dx_version" ]; then
        error "Failed to fetch latest stable release from GitHub API"
    fi

    dx_uri=$github_repo/releases/download/$dx_version/dx-$target.zip
    info_bold "Installing Dioxus CLI $dx_version (Stable)"
else
    # Specific version provided
    dx_version="$1"
    dx_uri=$github_repo/releases/download/$dx_version/dx-$target.zip
    info_bold "Installing Dioxus CLI $dx_version (Specific Version)"
fi

dx_install="${DX_INSTALL:-$HOME/.dx}"
bin_dir="$dx_install/bin"
exe="$bin_dir/dx"
cargo_bin_dir="$HOME/.cargo/bin"
cargo_bin_exe="$cargo_bin_dir/dx"

if [ ! -d "$bin_dir" ]; then
    mkdir -p "$bin_dir"
fi

info "Downloading from: $dx_uri"
curl --fail --location --progress-bar --output "$exe.zip" "$dx_uri"
unzip -d "$bin_dir" -o "$exe.zip"
chmod +x "$exe"

# Copy to cargo bin if it exists
if [ -d "$cargo_bin_dir" ]; then
    cp "$exe" "$cargo_bin_exe" || info "Note: Could not copy to $cargo_bin_dir"
fi
rm "$exe.zip"

echo
success "dx was installed successfully to:"
info "  $exe"
if [ -f "$cargo_bin_exe" ]; then
    info "  $cargo_bin_exe"
fi
echo

# Verify installation
if [ -f "$exe" ]; then
    version_output=$("$exe" --version 2>&1 || echo "unknown")
    success "Installed version: $version_output"
fi

echo
if command -v dx >/dev/null; then
    success "✓ dx is available in PATH"
    info_bold "Run 'dx --help' to get started"
else
    info "Add ~/.dx/bin to your PATH:"
    echo "  export PATH=\"\$HOME/.dx/bin:\$PATH\""
    echo
    info_bold "Then run 'dx --help' to get started"
fi
