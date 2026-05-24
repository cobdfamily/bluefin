import Darwin
import Foundation
import AppKit  // For NSWorkspace and NSRunningApplication
import ApplicationServices  // For AXObserver

@MainActor
class AccessibilityObserverManager {
    static var shared = AccessibilityObserverManager()

    var accessibilityNotifications: [String] = [
        "AXApplicationActivated",
        "AXApplicationDeactivated",
        "AXApplicationHidden",
        "AXApplicationShown",
        "AXWindowCreated",
        "AXWindowMoved",
        "AXWindowResized",
        "AXWindowMiniaturized",
        "AXWindowDeminiaturized",
        "AXUIElementDestroyed",
        "AXFocusedUIElementChanged",
        "AXTitleChanged",
        "AXValueChanged",
        "AXEnabledChanged",
        "AXSelectedChildrenChanged",
        "AXMenuOpened",
        "AXMenuClosed",
        "AXMenuItemSelected",
        "AXTextChanged",
        "AXSelectedTextChanged",
        "AXRowCountChanged",
        "AXRowCollapsed",
        "AXRowExpanded",
        "AXAnnouncementRequested",
        "AXLiveRegionChanged",
        "AXLayoutChanged",
        "AXMoved",
        "AXResized",
        "AXShown",
        "AXHidden"
    ]

    private var axObservers: [pid_t: AXObserver] = [:]
    
    func setupAXObserver(for pid: pid_t) {
        // Stop all other observers except the one being set up
        stopAllObserversExcept(for: pid)
        
        let appElement = AXUIElementCreateApplication(pid)
        var observer: AXObserver?

        let callback: AXObserverCallback = { observer, element, notification, refcon in
if !isHidden( element ) {
            let json: [String: Any?] = [
                "type": "AXObserver",
"name": notification as String,
"targetAppId": getPid( from: element ),
                "targetPath": getPathToUIElement( element),  // Assumes this helper function is defined elsewhere
"targetType": getAttributeForUIElement( element, withName: "AXRole" ) as! String,
            ]
            printJSON(withJSONObject: json)  // Assumes this helper function is defined elsewhere
}
        }

        let result = AXObserverCreate(pid, callback, &observer)
        if result == .success, let observer = observer {
            axObservers[pid] = observer  // Store the observer for later reference
            CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            
            // Register notifications
            for accessibilityNotification in self.accessibilityNotifications {
                AXObserverAddNotification(observer, appElement, accessibilityNotification as CFString, nil)
            }
            printJSON( withJSONObject: [
"type": "SystemLog",
"message": "AXObserver set up for PID: \(pid)",
] )
        } else {
            printJSON( withJSONObject: [
"type": "SystemError",
"message": "Failed to create AXObserver for PID \(pid): \(result.rawValue)",
] )
        }
    }
    
    // Method to stop all observers except the one for the specified PID
    private func stopAllObserversExcept(for pid: pid_t) {
        for (existingPid, observer) in axObservers where existingPid != pid {
            let appElement = AXUIElementCreateApplication(existingPid)
            for accessibilityNotification in accessibilityNotifications {
                AXObserverRemoveNotification(observer, appElement, accessibilityNotification as CFString)
            }
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            axObservers.removeValue(forKey: existingPid)
            printJSON( withJSONObject: [
"type": "SystemLog",
"message": "Stopped AXObserver for PID: \(existingPid)"
] )
        }
    }
}
