#!/bin/bash
set -euo pipefail

APP_DIR="/Applications/Hyperkey.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building hyperkey..."
cd "$PROJECT_DIR"
swift build -c release

BUILT_BINARY="$PROJECT_DIR/.build/release/hyperkey"
if [ ! -f "$BUILT_BINARY" ]; then
    echo "Error: build failed"
    exit 1
fi

echo "Installing to $APP_DIR..."
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILT_BINARY" "$APP_DIR/Contents/MacOS/hyperkey"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

echo ""
echo "Installed! Open Hyperkey from Spotlight/Raycast."
echo "Enable 'Launch at Login' from the menu bar icon."
