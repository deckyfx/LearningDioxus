#!/bin/bash
# Install Dioxus CLI with specific version
# Usage: ./install-dx.sh [version]
# Example: ./install-dx.sh 0.7.0-rc.3

set -e

VERSION="${1:-0.7.0-rc.3}"

echo "Installing Dioxus CLI version: $VERSION"

# Install using cargo
cargo install dioxus-cli --version "$VERSION" --locked

# Verify installation
echo ""
echo "Installation complete!"
dx --version
