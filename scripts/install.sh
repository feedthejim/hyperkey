#!/bin/bash
set -euo pipefail

BINARY_NAME="hyperkey"
APP_NAME="Hyperkey.app"
APP_DIR="/Applications/$APP_NAME"
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

echo "Creating app bundle at $APP_DIR..."
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILT_BINARY" "$APP_DIR/Contents/MacOS/$BINARY_NAME"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

# Unload if already loaded (ignore errors)
launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || true

echo "Installing LaunchAgent..."
mkdir -p "$LAUNCH_AGENTS_DIR"

# Generate plist pointing to the app bundle binary
cat > "$LAUNCH_AGENTS_DIR/$PLIST_NAME" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.feedthejim.hyperkey</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_DIR/Contents/MacOS/$BINARY_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>/tmp/hyperkey.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/hyperkey.err.log</string>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
EOF

echo "Loading LaunchAgent..."
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo ""
echo "hyperkey installed successfully!"
echo ""
echo "IMPORTANT: Grant Accessibility permissions to Hyperkey"
echo "  System Settings > Privacy & Security > Accessibility"
echo ""
echo "To check status:"
echo "  launchctl print gui/$(id -u)/com.feedthejim.hyperkey"
