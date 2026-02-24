import ApplicationServices
import Foundation

enum Accessibility {
    /// Check if we have accessibility permissions.
    /// If not, prompt the user and poll using the run loop (keeps app responsive).
    static func ensureAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary

        if AXIsProcessTrustedWithOptions(options) {
            return
        }

        fputs("hyperkey: waiting for Accessibility permission...\n", stderr)

        // Poll using CFRunLoop instead of Thread.sleep so the app stays responsive
        // and macOS doesn't show "not responding" dialogs.
        while !AXIsProcessTrusted() {
            CFRunLoopRunInMode(.defaultMode, 1.0, false)
        }

        fputs("hyperkey: Accessibility permission granted.\n", stderr)
    }
}
