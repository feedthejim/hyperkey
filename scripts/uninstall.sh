#!/bin/bash
set -euo pipefail

BINARY_NAME="hyperkey"
INSTALL_DIR="/usr/local/bin"
PLIST_NAME="com.feedthejim.hyperkey.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

echo "Stopping hyperkey..."
launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || true

# Clear the hidutil mapping
"$INSTALL_DIR/$BINARY_NAME" --uninstall 2>/dev/null || true

echo "Removing LaunchAgent..."
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo "Removing binary..."
sudo rm -f "$INSTALL_DIR/$BINARY_NAME"

echo ""
echo "hyperkey uninstalled. CapsLock restored to default."
echo "You may also want to remove it from:"
echo "  System Settings > Privacy & Security > Accessibility"
