import ApplicationServices
import Foundation

enum Accessibility {
    /// Check if we have accessibility permissions.
    /// If not, prompt the user and wait until they grant access.
    static func ensureAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary

        if AXIsProcessTrustedWithOptions(options) {
            return
        }

        fputs("hyperkey: waiting for Accessibility permission...\n", stderr)

        // Poll until the user grants permission instead of exiting.
        // This avoids requiring a manual restart after granting access.
        while !AXIsProcessTrusted() {
            Thread.sleep(forTimeInterval: 1)
        }

        fputs("hyperkey: Accessibility permission granted.\n", stderr)
    }
}
