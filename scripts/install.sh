#!/bin/bash
set -euo pipefail

BINARY_NAME="hyperkey"
INSTALL_DIR="/usr/local/bin"
PLIST_NAME="com.feedthejim.hyperkey.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building hyperkey..."
cd "$PROJECT_DIR"
swift build -c release

BUILT_BINARY="$PROJECT_DIR/.build/release/$BINARY_NAME"
if [ ! -f "$BUILT_BINARY" ]; then
    echo "Error: build failed, binary not found at $BUILT_BINARY"
    exit 1
fi

echo "Installing binary to $INSTALL_DIR..."
sudo cp "$BUILT_BINARY" "$INSTALL_DIR/$BINARY_NAME"
sudo chmod 755 "$INSTALL_DIR/$BINARY_NAME"

echo "Installing LaunchAgent..."
mkdir -p "$LAUNCH_AGENTS_DIR"
cp "$PROJECT_DIR/$PLIST_NAME" "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# Unload if already loaded (ignore errors)
launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || true

echo "Loading LaunchAgent..."
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo ""
echo "hyperkey installed successfully!"
echo ""
echo "IMPORTANT: You must grant Accessibility permissions to /usr/local/bin/hyperkey"
echo "  System Settings > Privacy & Security > Accessibility"
echo "  If prompted, click 'Open System Settings' and enable hyperkey."
echo ""
echo "To check status:"
echo "  launchctl print gui/$(id -u)/com.feedthejim.hyperkey"
