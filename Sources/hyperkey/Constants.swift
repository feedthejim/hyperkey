import CoreGraphics

/// Shared mutable state for hyper mode. Accessed from both EventTap (CGEventTap callback)
/// and KeyboardMonitor (IOKit HID callback). Both are C function pointers that cannot
/// capture context, requiring global state. Both run on the main run loop so no
/// synchronization is needed.
nonisolated(unsafe) var hyperActive = false
nonisolated(unsafe) var hyperUsedAsModifier = false

enum Constants {
    /// Virtual keycode for F18 (0x4F)
    static let f18KeyCode: Int64 = 79

    /// HID usage ID for Caps Lock
    static let hidCapsLock: UInt64 = 0x700000039

    /// HID usage ID for F18
    static let hidF18: UInt64 = 0x70000006D

    /// Combined hyper modifier flags: Cmd + Ctrl + Opt + Shift
    static let hyperFlags = CGEventFlags(rawValue:
        CGEventFlags.maskCommand.rawValue |
        CGEventFlags.maskControl.rawValue |
        CGEventFlags.maskAlternate.rawValue |
        CGEventFlags.maskShift.rawValue
    )

    /// Event mask for key events we intercept
    static let eventMask: CGEventMask = (
        (1 << CGEventType.keyDown.rawValue) |
        (1 << CGEventType.keyUp.rawValue) |
        (1 << CGEventType.flagsChanged.rawValue)
    )

    /// Virtual keycode for CapsLock (fallback for keyboards where hidutil doesn't remap)
    static let capsLockKeyCode: Int64 = 57

    /// CapsLock modifier flag
    static let capsLockFlag = CGEventFlags.maskAlphaShift

    /// Virtual keycode for Escape
    static let escKeyCode: UInt16 = 0x35

    /// App version
    static let version = "0.2.0"

    /// GitHub repo for update checks
    static let githubRepo = "feedthejim/hyperkey"

    /// CGEvent user data field for tagging events injected by the HID seizure path
    static let injectedEventField = CGEventField(rawValue: 43)!
    /// Marker value to identify our injected events (prevents feedback loops)
    static let injectedEventMarker: Int64 = 0x48594B45 // "HYKE"

    /// LaunchAgent label
    static let bundleID = "com.feedthejim.hyperkey"
}
