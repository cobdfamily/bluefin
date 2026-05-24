import Darwin
import Foundation
import AppKit  // For NSWorkspace and NSRunningApplication
import ApplicationServices  // For AXObserver

func getIntFromUIElement( element: AXUIElement ) -> Int? {
        return Int(bitPattern: UInt(bitPattern: Unmanaged.passRetained(element).toOpaque()))
}
