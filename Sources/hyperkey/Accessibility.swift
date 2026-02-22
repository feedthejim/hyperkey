import ApplicationServices
import Foundation

enum Accessibility {
    /// Check if we have accessibility permissions.
    /// If not, prompt the user and exit with instructions.
    static func ensureAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary

        if !AXIsProcessTrustedWithOptions(options) {
            fputs("""
            hyperkey: Accessibility access required.

            macOS should have opened System Settings > Privacy & Security > Accessibility.
            Grant access to the hyperkey binary, then re-run.

            If the prompt did not appear, add it manually:
              System Settings > Privacy & Security > Accessibility
              Click '+' and add: \(CommandLine.arguments[0])

            """, stderr)
            exit(1)
        }
    }
}
