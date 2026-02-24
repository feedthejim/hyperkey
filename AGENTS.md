# Hyperkey Agent Guide

## Project Overview

Hyperkey is a macOS menu bar utility (~600 lines Swift) that turns CapsLock into a Hyper key (Cmd+Ctrl+Opt+Shift). It uses a dual-path architecture to handle both built-in and external keyboards.

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
| `Sources/hyperkey/HyperKeyApp.swift` | Entry point, menu bar UI, preferences, signal handlers |
| `Sources/hyperkey/EventTap.swift` | CGEventTap callback for built-in keyboard hyper mode |
| `Sources/hyperkey/KeyboardMonitor.swift` | IOKit HID seizure for external keyboards, CGEvent injection |
| `Sources/hyperkey/HIDKeyTable.swift` | HID usage ID to macOS virtual keycode mapping table |
| `Sources/hyperkey/HIDMapping.swift` | `hidutil` CapsLock to F18 remapping |
| `Sources/hyperkey/Constants.swift` | Shared state, keycodes, flags, app constants |
| `Sources/hyperkey/Accessibility.swift` | TCC permission check with polling |
| `Sources/hyperkey/UpdateChecker.swift` | GitHub release version check |

### Important patterns

- **C callback globals**: CGEventTap and IOKit HID callbacks are C function pointers that can't capture context. All shared state uses `nonisolated(unsafe)` file-scope variables.
- **Feedback loop prevention**: Events injected by the HID seizure path are tagged with a marker (`Constants.injectedEventMarker`) in CGEvent user data field 43. The CGEventTap callback checks for this marker and passes tagged events through without processing.
- **Device classification**: Built-in keyboards are identified by `kIOHIDBuiltInKey` property or "SPI"/"BuiltIn" transport type. Only external keyboards are seized.

## Build and Test

```bash
# Debug build
swift build

# Release build + install to /Applications
make install

# Run from debug build (will need accessibility permission)
.build/debug/hyperkey

# Uninstall
make uninstall
```

## Release Process

Releases are automated via GitHub Actions (`.github/workflows/release.yml`):

1. Tag a new version: `git tag v0.X.Y && git push origin v0.X.Y`
2. The workflow builds a universal binary (arm64 + x86_64), creates a signed app bundle, and publishes a GitHub release
3. Version is stamped from the git tag automatically

## Debugging

- Logs go to stderr. When running via LaunchAgent, check `/tmp/hyperkey.err.log`
- The app logs keyboard connect/disconnect events and seizure status
- To test external keyboard handling, watch for "seized external keyboard" in logs
- If keys double on external keyboard, it likely means multiple HID interfaces for the same device are being seized. Only the first successful seizure should register an input callback.
