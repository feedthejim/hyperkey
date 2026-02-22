import CoreGraphics

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

    /// LaunchAgent label
    static let bundleID = "com.feedthejim.hyperkey"
}
