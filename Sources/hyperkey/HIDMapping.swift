import Foundation

enum HIDMapping {
    /// Apply the CapsLock -> F18 mapping via hidutil.
    /// Operates at the HID driver level, preventing caps lock toggle behavior.
    /// Does not persist across reboots (the LaunchAgent re-applies it).
    /// Returns true on success, false on failure.
    @discardableResult
    static func applyCapsLockToF18() -> Bool {
        let src = Constants.hidCapsLock
        let dst = Constants.hidF18

        let json = """
        {"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":\(src),"HIDKeyboardModifierMappingDst":\(dst)}]}
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        process.arguments = ["property", "--set", json]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                fputs("hyperkey: warning: hidutil mapping failed (status \(process.terminationStatus))\n", stderr)
                return false
            }
            return true
        } catch {
            fputs("hyperkey: warning: could not run hidutil: \(error)\n", stderr)
            return false
        }
    }

    /// Remove the CapsLock -> F18 mapping (restore default behavior).
    static func clearMapping() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        process.arguments = ["property", "--set", #"{"UserKeyMapping":[]}"#]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Best effort on cleanup
        }
    }
}
