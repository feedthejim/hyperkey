#!/bin/bash
set -euo pipefail

APP_DIR="/Applications/Hyperkey.app"
PLIST="$HOME/Library/LaunchAgents/com.feedthejim.hyperkey.plist"

# Stop the LaunchAgent if running
launchctl bootout "gui/$(id -u)/com.feedthejim.hyperkey.plist" 2>/dev/null || true

# Clear hidutil mapping
"$APP_DIR/Contents/MacOS/hyperkey" --uninstall 2>/dev/null || true

# Clean up
rm -f "$PLIST"
rm -rf "$APP_DIR"

echo "hyperkey uninstalled. CapsLock restored to default."
