import AppKit
import Foundation

@main
struct HyperKeyApp {
    static func main() {
        // Handle --uninstall flag
        if CommandLine.arguments.contains("--uninstall") {
            HIDMapping.clearMapping()
            fputs("hyperkey: CapsLock mapping cleared.\n", stderr)
            return
        }

        // Handle --version flag
        if CommandLine.arguments.contains("--version") {
            print("hyperkey \(Constants.version)")
            return
        }

        // 1. Check for already-running instance
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Constants.bundleID)
        if runningApps.count > 1 {
            fputs("hyperkey: already running.\n", stderr)
            return
        }
        // Also check by process name for non-bundle launches
        let selfPID = ProcessInfo.processInfo.processIdentifier
        let others = NSWorkspace.shared.runningApplications.filter {
            $0.localizedName == "hyperkey" && $0.processIdentifier != selfPID
        }
        if !others.isEmpty {
            fputs("hyperkey: already running.\n", stderr)
            return
        }

        // 2. Check accessibility permissions (prompts if needed, exits if denied)
        Accessibility.ensureAccessibility()

        // 2. Apply CapsLock -> F18 mapping via hidutil
        HIDMapping.applyCapsLockToF18()

        // 3. Monitor for keyboard connect/disconnect to re-apply mapping
        //    (fixes external keyboards plugged in after launch)
        KeyboardMonitor.start()

        // 4. Set up signal handlers for clean shutdown
        signal(SIGINT) { _ in
            HIDMapping.clearMapping()
            fputs("\nhyperkey: stopped, CapsLock mapping cleared.\n", stderr)
            exit(0)
        }
        signal(SIGTERM) { _ in
            HIDMapping.clearMapping()
            fputs("hyperkey: stopped, CapsLock mapping cleared.\n", stderr)
            exit(0)
        }

        // 5. Start the event tap (runs on the main run loop)
        EventTap.start()

        // 6. Set up NSApplication with menu bar item
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory) // Hide from Dock

        let delegate = AppDelegate()
        app.delegate = delegate

        app.run() // Blocks forever, drives the CFRunLoop
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var updateMenuItem: NSMenuItem!
    private var updateURL: String?

    private let escapeKey = "escapeOnTap"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Restore escape-on-tap preference
        let savedEscape = UserDefaults.standard.bool(forKey: escapeKey)
        escapeOnTap = savedEscape

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "capslock.fill",
                accessibilityDescription: "Hyperkey"
            )
        }

        let menu = NSMenu()

        let statusMenuItem = NSMenuItem(title: "Hyperkey v\(Constants.version)", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        updateMenuItem = NSMenuItem(title: "Update available", action: #selector(openUpdate(_:)), keyEquivalent: "")
        updateMenuItem.target = self
        updateMenuItem.isHidden = true
        menu.addItem(updateMenuItem)

        menu.addItem(NSMenuItem.separator())

        let escapeItem = NSMenuItem(
            title: "CapsLock alone → Escape",
            action: #selector(toggleEscape(_:)),
            keyEquivalent: ""
        )
        escapeItem.target = self
        escapeItem.state = savedEscape ? .on : .off
        menu.addItem(escapeItem)

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = isLaunchAgentLoaded() ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit Hyperkey",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        // Check for updates in the background
        Task {
            if let (version, url) = await UpdateChecker.check() {
                updateMenuItem.title = "Update available: v\(version)"
                updateMenuItem.isHidden = false
                updateURL = url
            }
        }
    }

    @objc private func toggleEscape(_ sender: NSMenuItem) {
        let newValue = sender.state != .on
        escapeOnTap = newValue
        sender.state = newValue ? .on : .off
        UserDefaults.standard.set(newValue, forKey: escapeKey)
    }

    @objc private func openUpdate(_ sender: NSMenuItem) {
        if let urlString = updateURL, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let plistName = "\(Constants.bundleID).plist"
        let launchAgentsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentsDir.appendingPathComponent(plistName)
        let uid = getuid()

        if sender.state == .on {
            // Unload
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            process.arguments = ["bootout", "gui/\(uid)/\(plistName)"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
            process.waitUntilExit()

            try? FileManager.default.removeItem(at: plistPath)
            sender.state = .off
        } else {
            // Install and load
            try? FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)

            let execPath = CommandLine.arguments[0]
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
              "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(Constants.bundleID)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(execPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <dict>
                    <key>SuccessfulExit</key>
                    <false/>
                    <key>Crashed</key>
                    <true/>
                </dict>
                <key>ProcessType</key>
                <string>Interactive</string>
                <key>StandardOutPath</key>
                <string>/tmp/hyperkey.out.log</string>
                <key>StandardErrorPath</key>
                <string>/tmp/hyperkey.err.log</string>
                <key>LimitLoadToSessionType</key>
                <string>Aqua</string>
            </dict>
            </plist>
            """

            try? plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            process.arguments = ["bootstrap", "gui/\(uid)", plistPath.path]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
            process.waitUntilExit()

            sender.state = .on
        }
    }

    @objc private func quitApp(_ sender: NSMenuItem) {
        HIDMapping.clearMapping()
        NSApplication.shared.terminate(nil)
    }

    private func isLaunchAgentLoaded() -> Bool {
        let plistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(Constants.bundleID).plist")
        return FileManager.default.fileExists(atPath: plistPath.path)
    }
}
