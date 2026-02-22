import CoreGraphics
import Foundation

/// Mutable state for the event tap callback.
/// CGEventTapCallBack is a C function pointer, so it cannot capture context.
/// Global state is the standard pattern for CGEventTap in Swift.
nonisolated(unsafe) private var hyperActive = false
nonisolated(unsafe) private var hyperUsedAsModifier = false
nonisolated(unsafe) private var eventTapPort: CFMachPort?
nonisolated(unsafe) var escapeOnTap = false

enum EventTap {
    /// Create and start the CGEventTap. Call on the main thread.
    /// The tap runs via the main CFRunLoop (driven by NSApplication).
    static func start() {
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Constants.eventMask,
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            fputs("hyperkey: failed to create event tap. Check accessibility permissions.\n", stderr)
            exit(1)
        }

        eventTapPort = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        fputs("hyperkey: running (CapsLock -> Hyper)\n", stderr)
    }
}

/// The event tap callback.
///
/// Event flow:
///   1. hidutil remaps CapsLock (HID 0x39) to F18 (HID 0x6D) at driver level
///   2. macOS translates F18 to virtual keycode 79 (kVK_F18)
///   3. Our CGEventTap intercepts keyDown/keyUp for keycode 79
///   4. On F18 keyDown: set hyperActive, suppress the event
///   5. On any other keyDown/keyUp while hyperActive: add hyper modifier flags
///   6. On F18 keyUp: clear hyperActive, suppress the event
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // Re-enable tap if system disabled it (happens under heavy load)
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let port = eventTapPort {
            CGEvent.tapEnable(tap: port, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    // F18 keyDown: activate hyper mode
    if type == .keyDown && keyCode == Constants.f18KeyCode {
        if !hyperActive {
            // Only reset on initial press, not on key repeats
            hyperActive = true
            hyperUsedAsModifier = false
        }
        // Suppress the F18 event
        return nil
    }

    // F18 keyUp: deactivate hyper mode
    if type == .keyUp && keyCode == Constants.f18KeyCode {
        let wasUsed = hyperUsedAsModifier
        hyperActive = false
        hyperUsedAsModifier = false

        // Tap without combo: send Escape if enabled
        if !wasUsed && escapeOnTap {
            let src = CGEventSource(stateID: .hidSystemState)
            if let down = CGEvent(keyboardEventSource: src, virtualKey: Constants.escKeyCode, keyDown: true),
               let up = CGEvent(keyboardEventSource: src, virtualKey: Constants.escKeyCode, keyDown: false) {
                down.post(tap: .cghidEventTap)
                up.post(tap: .cghidEventTap)
            }
        }

        // Suppress the F18 keyUp
        return nil
    }

    // Any other key while hyper is active: add modifier flags
    if hyperActive && (type == .keyDown || type == .keyUp) {
        hyperUsedAsModifier = true
        event.flags = CGEventFlags(rawValue: event.flags.rawValue | Constants.hyperFlags.rawValue)
        return Unmanaged.passUnretained(event)
    }

    // flagsChanged events while hyper is active
    if hyperActive && type == .flagsChanged {
        hyperUsedAsModifier = true
        event.flags = CGEventFlags(rawValue: event.flags.rawValue | Constants.hyperFlags.rawValue)
        return Unmanaged.passUnretained(event)
    }

    // Everything else: pass through unmodified
    return Unmanaged.passUnretained(event)
}
