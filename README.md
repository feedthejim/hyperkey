# Hyperkey

A tiny macOS menu bar utility that turns Caps Lock into a Hyper key (Cmd+Ctrl+Opt+Shift pressed simultaneously). Built as a lightweight, dependency-free alternative to Karabiner Elements.

## Why

Karabiner Elements uses a DriverKit virtual keyboard driver that [broke on macOS 26.4 beta](https://github.com/pqrs-org/Karabiner-Elements/issues/4402). Hyperkey takes a simpler approach:

1. `hidutil` remaps Caps Lock to F18 at the HID driver level (Apple's own tool, always works)
2. A `CGEventTap` intercepts F18 and injects all four modifier flags onto key combos
3. External keyboards are handled via IOKit HID seizure, since `CGEventTap` can't see their events on macOS 26+

No kernel extensions, no virtual keyboards, no external dependencies. Just Swift and Apple's built-in APIs.

## Features

- **Hyper key**: CapsLock + any key sends Cmd+Ctrl+Opt+Shift + that key
- **CapsLock alone to Escape**: Optional toggle, great for vim users
- **External keyboard support**: Works with USB and wireless keyboards via IOKit HID
- **Launch at Login**: One-click toggle from the menu bar
- **Auto-update check**: Notifies you when a new version is available on GitHub
- **Menu bar icon**: Minimal capslock glyph, no Dock icon

## Install

### Download (recommended)

1. Download `Hyperkey.zip` from the [latest release](https://github.com/feedthejim/hyperkey/releases/latest)
2. Unzip and move `Hyperkey.app` to `/Applications`
3. Open Hyperkey from Spotlight or Raycast
4. Grant Accessibility permissions when prompted (the app will wait and start automatically once granted)
5. Click the Caps Lock icon in the menu bar and enable **Launch at Login**

### Build from source

```bash
git clone https://github.com/feedthejim/hyperkey.git
cd hyperkey
make install    # builds, signs, and installs to /Applications
```

### Uninstall

```bash
make uninstall
# also remove from System Settings > Privacy & Security > Accessibility
```

Or manually: quit from the menu bar, delete `Hyperkey.app` from `/Applications`, and remove `~/Library/LaunchAgents/com.feedthejim.hyperkey.plist`.

## How it works

| Layer | What | How |
|-------|------|-----|
| HID | Caps Lock to F18 | `hidutil property --set` (prevents caps lock toggle) |
| Event | F18 to Hyper modifier | `CGEventTap` adds Cmd+Ctrl+Opt+Shift flags to key events |
| External keyboards | Seize and re-inject | IOKit HID seizure with CGEvent re-injection (macOS 26+ fix) |
| UI | Menu bar icon | `NSStatusItem` with settings and update notifications |

### Dual-path architecture

**Built-in keyboard**: `hidutil` remaps CapsLock to F18, and a `CGEventTap` intercepts F18 to apply hyper modifier flags.

**External keyboards**: On macOS 26+, `CGEventTap` no longer receives events from external keyboards. Hyperkey detects external keyboards via IOKit HID, seizes them for exclusive access, and re-injects all key events as CGEvents with hyper mode applied. This happens automatically with no configuration needed.

## Requirements

- macOS 13+
- Accessibility permissions

## License

MIT
