import Darwin
import Foundation
import AppKit  // For NSWorkspace and NSRunningApplication
import ApplicationServices  // For AXObserver

// Function to register an observer for active app changes
func registerActiveAppObserver() {
    NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didActivateApplicationNotification,
        object: nil,
        queue: .main
    ) { notification in
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            let appName = app.localizedName ?? "Unknown Application"
            let appProcessIdentifier = app.processIdentifier  // Capture this value before using it

            printJSON(withJSONObject: [
                "type": "NSWorkspace",
                "name": "didActivateApplicationNotification",
                "details": [
                    "name": appName,
                    "id": Int(appProcessIdentifier),
                ]
            ])

            // Autoregister this pid for AXObserver notifications
            if #available(macOS 10.15, *) {
                Task { @MainActor in
                    AccessibilityObserverManager.shared.setupAXObserver(for: appProcessIdentifier)
                }
            } else {
                DispatchQueue.main.async {
                    AccessibilityObserverManager.shared.setupAXObserver(for: appProcessIdentifier)
                }
            }
        }
    }
}

// Function to start a concurrent task for listening for PIDs from stdin
func startListeningForPIDs() {
    DispatchQueue.global().async {
        while let line = readLine(), let pid = pid_t(line.trimmingCharacters(in: .whitespacesAndNewlines)) {
            if #available(macOS 10.15, *) {
                Task { @MainActor in
                    AccessibilityObserverManager.shared.setupAXObserver(for: pid)
                }
            } else {
                DispatchQueue.main.async {
                    AccessibilityObserverManager.shared.setupAXObserver(for: pid)
                }
            }
        }
    }
}

// Keep the main run loop alive
func keepMainRunLoopAlive() {
    RunLoop.main.run()
}

// Main function to serve as entry point
printJSON(withJSONObject: [
    "type": "SystemLog",
    "message": "Starting Active Application Monitor...",
])
registerActiveAppObserver()  // Start listening for active app changes
startListeningForPIDs()      // Start listening for PIDs in a concurrent task
keepMainRunLoopAlive()
