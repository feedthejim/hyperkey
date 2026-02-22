# Hyperkey

A tiny macOS menu bar utility that turns Caps Lock into a Hyper key (Cmd+Ctrl+Opt+Shift pressed simultaneously). Built as a lightweight, dependency-free alternative to Karabiner Elements.

## Why

Karabiner Elements uses a DriverKit virtual keyboard driver that [broke on macOS 26.4 beta](https://github.com/pqrs-org/Karabiner-Elements/issues/4402). Hyperkey takes a simpler approach that avoids the IOKit HID layer entirely:

1. `hidutil` remaps Caps Lock to F18 at the HID driver level (Apple's own tool, always works)
2. A `CGEventTap` intercepts F18 and injects all four modifier flags onto key combos

No kernel extensions, no virtual keyboards, no external dependencies. Just ~200 lines of Swift.

## Install

### Download (recommended)

1. Download `Hyperkey.zip` from the [latest release](https://github.com/feedthejim/hyperkey/releases/latest)
2. Unzip and move `Hyperkey.app` to `/Applications`
3. Open Hyperkey from Spotlight or Raycast
4. Grant Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility)
5. Click the Caps Lock icon in the menu bar and enable **Launch at Login**

### Build from source

```bash
git clone https://github.com/feedthejim/hyperkey.git
cd hyperkey
./scripts/install.sh
```

### Uninstall

```bash
./scripts/uninstall.sh
# also remove from System Settings > Privacy & Security > Accessibility
```

Or manually: quit from the menu bar, delete `Hyperkey.app` from `/Applications`, and remove `~/Library/LaunchAgents/com.feedthejim.hyperkey.plist`.

## How it works

| Layer | What | How |
|-------|------|-----|
| HID | Caps Lock → F18 | `hidutil property --set` (prevents caps lock toggle) |
| Event | F18 → Hyper modifier | `CGEventTap` adds Cmd+Ctrl+Opt+Shift flags to key events |
| UI | Menu bar icon | `NSStatusItem` with launch-at-login toggle |

The hidutil mapping doesn't persist across reboots. The LaunchAgent (or "Launch at Login") re-applies it on login.

## Requirements

- macOS 13+
- Accessibility permissions

## License

MIT
