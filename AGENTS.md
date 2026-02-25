# Hyperkey Agent Guide

## Project Overview

Hyperkey is a macOS menu bar utility (~900 lines Swift) that turns CapsLock into a Hyper key (Cmd+Ctrl+Opt+Shift). It uses a dual-path architecture to handle both built-in and external keyboards.

## Architecture

### Dual-path keyboard handling

**Built-in keyboards** use the CGEventTap path:
- `hidutil` remaps CapsLock to F18 at HID driver level
- `CGEventTap` intercepts F18 keyDown/keyUp and adds hyper modifier flags

**External keyboards** use the IOKit HID seizure path (macOS 26+ broke CGEventTap for external keyboards):
- `IOHIDManager` detects external keyboard devices
- Devices are seized via `IOHIDDeviceOpen` with `kIOHIDOptionsTypeSeizeDevice`
- All HID input is intercepted and re-injected as CGEvents
- CapsLock is handled as hyper, regular keys are passed through

Both paths share `hyperActive` and `hyperUsedAsModifier` global state (defined in `Constants.swift`). Both callbacks run on the main run loop, so no synchronization is needed.

### Key files

| File | Purpose |
|------|---------|
| `Sources/hyperkey/HyperKeyApp.swift` | Entry point, menu bar UI (NSMenuDelegate), preferences, LaunchAgent management |
| `Sources/hyperkey/EventTap.swift` | CGEventTap callback for built-in keyboard hyper mode |
| `Sources/hyperkey/KeyboardMonitor.swift` | IOKit HID seizure for external keyboards, CGEvent injection, device tracking |
| `Sources/hyperkey/HIDKeyTable.swift` | HID usage ID to macOS virtual keycode mapping table (~100 entries) |
| `Sources/hyperkey/HIDMapping.swift` | `hidutil` CapsLock to F18 remapping (returns Bool for success/failure) |
| `Sources/hyperkey/Constants.swift` | Shared hyper state, keycodes, flags, injection markers, app constants |
| `Sources/hyperkey/Accessibility.swift` | TCC permission check with CFRunLoop-based polling (non-blocking) |
| `Sources/hyperkey/UpdateChecker.swift` | GitHub release version check with 24h UserDefaults cache |

### Important patterns

- **C callback globals**: CGEventTap and IOKit HID callbacks are C function pointers that can't capture context. All shared state uses `nonisolated(unsafe)` file-scope variables. Closures that call static methods on enums also capture context and won't compile as C callbacks; use top-level private functions instead.
- **Feedback loop prevention**: Events injected by the HID seizure path are tagged with a marker (`Constants.injectedEventMarker` = 0x48594B45 "HYKE") in CGEvent user data field 43. The CGEventTap callback checks for this marker and passes tagged events through without processing. Without this, every key from an external keyboard would be processed twice.
- **Device classification**: Built-in keyboards are identified by `kIOHIDBuiltInKey` property or "SPI"/"BuiltIn" transport type. Only external keyboards are seized.
- **Double input prevention**: Only register `IOHIDDeviceRegisterInputValueCallback` AFTER a successful seizure. If seizure fails (e.g. duplicate HID interface for the same physical keyboard), skip the device entirely. Registering a callback on an un-seized device causes double input because events flow through both the callback AND the normal macOS input pipeline.
- **Accessibility polling**: Uses `CFRunLoopRunInMode` instead of `Thread.sleep` to keep the app responsive while waiting for accessibility permission. `Thread.sleep` on the main thread causes macOS to show "application not responding" dialogs.
- **LaunchAgent path**: Uses `Bundle.main.executableURL?.path` instead of `CommandLine.arguments[0]` so the LaunchAgent survives app relocation.

### Menu bar UI

The app uses `NSMenuDelegate` to refresh dynamic content on each menu open:
- **Keyboards submenu**: reads `KeyboardMonitor.connectedDevices` array to show connected keyboards with their status (Built-in/Seized)
- **Accessibility warning**: checks `AXIsProcessTrusted()` on every menu open; shows warning if revoked
- **Update available**: cached check (24h), with manual "Check for Updates" item
- **HID mapping warning**: shown if `hidutil` mapping failed at startup

## Build and Test

```bash
# Debug build
swift build

# Release build + install to /Applications (kills old instance, resets TCC, codesigns, launches)
make install

# Uninstall
make uninstall
```

`make install` does these steps:
1. `swift build -c release`
2. Kills any running hyperkey instance
3. `tccutil reset Accessibility com.feedthejim.hyperkey` (clears stale TCC entry from previous binary)
4. Creates app bundle with Info.plist and AppIcon.icns
5. `codesign -f -s - --identifier com.feedthejim.hyperkey` (ad-hoc sign with stable identifier)
6. Copies to `/Applications/Hyperkey.app`
7. Opens the app

### Why TCC reset is needed

Each rebuild produces a new binary with a different code hash (CDHash). macOS TCC tracks accessibility permissions by CDHash. Without the reset, the old stale TCC entry stays "on" but doesn't match the new binary, causing `AXIsProcessTrusted()` to return false even though the toggle appears enabled in System Settings.

## Release Process

Releases are automated via GitHub Actions (`.github/workflows/release.yml`):

1. Tag a new version: `git tag v0.X.Y && git push origin v0.X.Y`
2. The workflow builds a universal binary (arm64 + x86_64), stamps version from tag, creates a codesigned app bundle, and publishes a GitHub release with `Hyperkey.zip`
3. Version in `Constants.swift` and `Info.plist` is stamped from the git tag automatically

## Debugging

- Logs go to stderr. When running via LaunchAgent, check `/tmp/hyperkey.err.log`
- The app logs keyboard connect/disconnect events and seizure status
- To test external keyboard handling, watch for "seized external keyboard" in logs
- If keys double on external keyboard: only the first successful seizure per physical keyboard should have a callback registered. Check that seizure failures are skipped (not opened non-exclusively)
- If app appears frozen on first launch: ensure `Accessibility.ensureAccessibility()` uses `CFRunLoopRunInMode`, not `Thread.sleep`
- If accessibility permission doesn't work after toggling: the TCC entry is stale (CDHash mismatch). Run `tccutil reset Accessibility com.feedthejim.hyperkey` and re-grant
- IOKit HID seizure ONLY affects HID-class keyboard devices (usage page 0x07, usage 0x06). It does NOT affect USB audio, displays, or other non-HID USB devices

## Known Issues / Gotchas

- **macOS 26.4 beta**: `CGEventTap` (both `cgSessionEventTap` and `cghidEventTap`) does not receive any events from external USB keyboards. This is the reason for the IOKit HID seizure path. IOKit HID input value callbacks still work.
- **Multiple HID interfaces per keyboard**: USB keyboards often register 2+ HID interfaces (keyboard + consumer controls). Only the first successful seizure gets a callback. The others fail with `kIOReturnExclusiveAccess` (-536870207 / 0xE00002C1) and are safely skipped.
- **Ad-hoc code signing**: Without a Developer ID certificate, each build produces a different CDHash, requiring TCC re-grant. The `make install` target handles this with `tccutil reset`.
- **Consumer page events (media keys)**: The HID seizure only handles keyboard page (0x07) events. Consumer page (0x0C) events (volume, play/pause, brightness) from seized devices are NOT re-injected. If media keys on an external keyboard stop working, this is why. Would need separate handling for usage page 0x0C.
