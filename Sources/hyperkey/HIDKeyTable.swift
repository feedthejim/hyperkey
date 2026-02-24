import CoreGraphics

/// Maps HID Keyboard/Keypad usage IDs (USB HID Usage Tables, page 0x07)
/// to macOS virtual keycodes (CGKeyCode / Carbon kVK_* values).
enum HIDKeyTable {
    /// Returns the macOS virtual keycode for a HID usage ID, or nil if unmapped.
    static func virtualKeyCode(forUsage usage: UInt32) -> UInt16? {
        return usageToKeyCode[usage]
    }

    /// Returns the CGEventFlags bit for a modifier usage ID, or nil.
    static func modifierFlag(forUsage usage: UInt32) -> CGEventFlags? {
        return modifierMapping[usage]
    }

    // MARK: - Letters (HID 0x04-0x1D)

    private static let usageToKeyCode: [UInt32: UInt16] = [
        0x04: 0x00, // a
        0x05: 0x0B, // b
        0x06: 0x08, // c
        0x07: 0x02, // d
        0x08: 0x0E, // e
        0x09: 0x03, // f
        0x0A: 0x05, // g
        0x0B: 0x04, // h
        0x0C: 0x22, // i
        0x0D: 0x26, // j
        0x0E: 0x28, // k
        0x0F: 0x25, // l
        0x10: 0x2E, // m
        0x11: 0x2D, // n
        0x12: 0x1F, // o
        0x13: 0x23, // p
        0x14: 0x0C, // q
        0x15: 0x0F, // r
        0x16: 0x01, // s
        0x17: 0x11, // t
        0x18: 0x20, // u
        0x19: 0x09, // v
        0x1A: 0x0D, // w
        0x1B: 0x07, // x
        0x1C: 0x10, // y
        0x1D: 0x06, // z

        // MARK: Numbers (HID 0x1E-0x27)
        0x1E: 0x12, // 1
        0x1F: 0x13, // 2
        0x20: 0x14, // 3
        0x21: 0x15, // 4
        0x22: 0x17, // 5
        0x23: 0x16, // 6
        0x24: 0x1A, // 7
        0x25: 0x1C, // 8
        0x26: 0x19, // 9
        0x27: 0x1D, // 0

        // MARK: Special keys
        0x28: 0x24, // Return
        0x29: 0x35, // Escape
        0x2A: 0x33, // Backspace
        0x2B: 0x30, // Tab
        0x2C: 0x31, // Space
        0x2D: 0x1B, // - (minus)
        0x2E: 0x18, // = (equal)
        0x2F: 0x21, // [ (left bracket)
        0x30: 0x1E, // ] (right bracket)
        0x31: 0x2A, // \ (backslash)
        0x32: 0x2A, // # (non-US, same as backslash on US)
        0x33: 0x29, // ; (semicolon)
        0x34: 0x27, // ' (quote)
        0x35: 0x32, // ` (grave accent)
        0x36: 0x2B, // , (comma)
        0x37: 0x2F, // . (period)
        0x38: 0x2C, // / (slash)
        0x64: 0x0A, // non-US \ (ISO key next to left shift)

        // MARK: Function keys (HID 0x3A-0x45)
        0x3A: 0x7A, // F1
        0x3B: 0x78, // F2
        0x3C: 0x63, // F3
        0x3D: 0x76, // F4
        0x3E: 0x60, // F5
        0x3F: 0x61, // F6
        0x40: 0x62, // F7
        0x41: 0x64, // F8
        0x42: 0x65, // F9
        0x43: 0x6D, // F10
        0x44: 0x67, // F11
        0x45: 0x6F, // F12
        0x68: 0x69, // F13
        0x69: 0x6B, // F14
        0x6A: 0x71, // F15
        0x6B: 0x6A, // F16
        0x6C: 0x40, // F17
        0x6D: 0x4F, // F18
        0x6E: 0x50, // F19

        // MARK: Navigation
        0x46: 0x69, // Print Screen (mapped to F13)
        0x47: 0x6B, // Scroll Lock (mapped to F14)
        0x48: 0x71, // Pause (mapped to F15)
        0x49: 0x72, // Insert (Help on Mac)
        0x4A: 0x73, // Home
        0x4B: 0x74, // Page Up
        0x4C: 0x75, // Delete Forward
        0x4D: 0x77, // End
        0x4E: 0x79, // Page Down
        0x4F: 0x7C, // Right Arrow
        0x50: 0x7B, // Left Arrow
        0x51: 0x7D, // Down Arrow
        0x52: 0x7E, // Up Arrow

        // MARK: Keypad
        0x53: 0x47, // Num Lock / Clear
        0x54: 0x4B, // Keypad /
        0x55: 0x43, // Keypad *
        0x56: 0x4E, // Keypad -
        0x57: 0x45, // Keypad +
        0x58: 0x4C, // Keypad Enter
        0x59: 0x53, // Keypad 1
        0x5A: 0x54, // Keypad 2
        0x5B: 0x55, // Keypad 3
        0x5C: 0x56, // Keypad 4
        0x5D: 0x57, // Keypad 5
        0x5E: 0x58, // Keypad 6
        0x5F: 0x59, // Keypad 7
        0x60: 0x5B, // Keypad 8
        0x61: 0x5C, // Keypad 9
        0x62: 0x52, // Keypad 0
        0x63: 0x41, // Keypad .
        0x67: 0x51, // Keypad =

        // MARK: Modifier keys (also in modifierMapping)
        0xE0: 0x3B, // Left Control
        0xE1: 0x38, // Left Shift
        0xE2: 0x3A, // Left Option
        0xE3: 0x37, // Left Command
        0xE4: 0x3E, // Right Control
        0xE5: 0x3C, // Right Shift
        0xE6: 0x3D, // Right Option
        0xE7: 0x36, // Right Command
    ]

    /// Maps modifier HID usages (0xE0-0xE7) to their CGEventFlags bits.
    private static let modifierMapping: [UInt32: CGEventFlags] = [
        0xE0: .maskControl,   // Left Control
        0xE1: .maskShift,     // Left Shift
        0xE2: .maskAlternate, // Left Option
        0xE3: .maskCommand,   // Left Command
        0xE4: .maskControl,   // Right Control
        0xE5: .maskShift,     // Right Shift
        0xE6: .maskAlternate, // Right Option
        0xE7: .maskCommand,   // Right Command
    ]
}
