import ApplicationServices

func getIntFromUIElement( element: AXUIElement ) -> Int? {
        return Int(bitPattern: UInt(bitPattern: Unmanaged.passRetained(element).toOpaque()))
}

func getUIElementFromInt(intPtr: Int) -> AXUIElement? {
    if let ptr = UnsafeRawPointer(bitPattern: UInt(bitPattern: intPtr)) {
        // Convert UnsafeRawPointer back to an AXUIElement
        return Unmanaged<AXUIElement>.fromOpaque(ptr).takeUnretainedValue()
    } else {
        return nil
    }
}
