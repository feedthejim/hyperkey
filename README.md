# Hyperkey

A tiny macOS menu bar utility that turns Caps Lock into a Hyper key (Cmd+Ctrl+Opt+Shift pressed simultaneously). Built as a lightweight, dependency-free alternative to Karabiner Elements.

## Why

Karabiner Elements uses a DriverKit virtual keyboard driver that [broke on macOS 26.4 beta](https://github.com/pqrs-org/Karabiner-Elements/issues/4402). Hyperkey takes a simpler approach that avoids the IOKit HID layer entirely:

1. `hidutil` remaps Caps Lock to F18 at the HID driver level (Apple's own tool, always works)
2. A `CGEventTap` intercepts F18 and injects all four modifier flags onto key combos

No kernel extensions, no virtual keyboards, no external dependencies. Just ~200 lines of Swift.

## Install

```bash
# Build
swift build -c release

# Copy to PATH
sudo cp .build/release/hyperkey /usr/local/bin/

# Run
hyperkey
```

On first launch, macOS will prompt for Accessibility permissions. Grant access in System Settings > Privacy & Security > Accessibility, then re-run.

Click the Caps Lock icon in the menu bar and enable **Launch at Login** to start automatically.

### Uninstall

```bash
hyperkey --uninstall   # clears the key mapping
sudo rm /usr/local/bin/hyperkey
# remove from System Settings > Privacy & Security > Accessibility
```

Or use the included scripts:

```bash
./scripts/install.sh    # build, install, load LaunchAgent
./scripts/uninstall.sh  # stop, remove everything
```

## How it works

| Layer | What | How |
|-------|------|-----|
| HID | Caps Lock → F18 | `hidutil property --set` (prevents caps lock toggle) |
| Event | F18 → Hyper modifier | `CGEventTap` adds Cmd+Ctrl+Opt+Shift flags to key events |
| UI | Menu bar icon | `NSStatusItem` with launch-at-login toggle |

The hidutil mapping doesn't persist across reboots. The LaunchAgent (or "Launch at Login") re-applies it on login.

## Requirements

- macOS 13+
- Swift 6.0+ toolchain
- Accessibility permissions

## License

MIT
