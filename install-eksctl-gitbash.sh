#!/bin/bash
# Install eksctl in Git Bash on Windows

set -e

echo "Installing eksctl for Windows..."

# Set platform for Windows
PLATFORM="windows_amd64"
EKSCTL_VERSION=$(curl -s https://api.github.com/repos/eksctl-io/eksctl/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

echo "Latest eksctl version: v${EKSCTL_VERSION}"

# Create temp directory
TEMP_DIR="/tmp/eksctl-install"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download eksctl
DOWNLOAD_URL="https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Windows_amd64.zip"
echo "Downloading from: $DOWNLOAD_URL"
curl -sL "$DOWNLOAD_URL" -o eksctl.zip

# Extract
echo "Extracting..."
unzip -q eksctl.zip

# Install to user bin directory (doesn't require admin)
INSTALL_DIR="$HOME/bin"
mkdir -p "$INSTALL_DIR"
mv eksctl.exe "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/eksctl.exe"

# Add to PATH in .bashrc if not already there
if ! grep -q "$INSTALL_DIR" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# eksctl" >> ~/.bashrc
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
    echo "Added $INSTALL_DIR to PATH in ~/.bashrc"
fi

# Cleanup
cd ~
rm -rf "$TEMP_DIR"

echo ""
echo "✓ eksctl installed successfully to: $INSTALL_DIR"
echo ""
echo "Please run: source ~/.bashrc"
echo "Or restart your Git Bash terminal"
echo ""
echo "Then verify with: eksctl version"
