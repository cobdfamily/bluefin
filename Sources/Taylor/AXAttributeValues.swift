import ApplicationServices

// Convert CFTypeRef to String
func getStringFromAXAttributeValue(_ attributeValue: CFTypeRef) -> String? {
    if CFGetTypeID(attributeValue) == CFStringGetTypeID() {
        return attributeValue as? String
    }
    return nil
}

// Convert CFTypeRef to CGRect
func getCGRectFromAXAttributeValue(_ attributeValue: CFTypeRef) -> CGRect? {
    if CFGetTypeID(attributeValue) == AXValueGetTypeID(),
       AXValueGetType(attributeValue as! AXValue) == .cgRect {
        var rect = CGRect.zero
        if AXValueGetValue(attributeValue as! AXValue, .cgRect, &rect) {
            return rect
        }
    }
    return nil
}

// Convert CFTypeRef to CGPoint
func getCGPointFromAXAttributeValue(_ attributeValue: CFTypeRef) -> CGPoint? {
    if CFGetTypeID(attributeValue) == AXValueGetTypeID(),
       AXValueGetType(attributeValue as! AXValue) == .cgPoint {
        var point = CGPoint.zero
        if AXValueGetValue(attributeValue as! AXValue, .cgPoint, &point) {
            return point
        }
    }
    return nil
}

// Convert CFTypeRef to CGSize
func getCGSizeFromAXAttributeValue(_ attributeValue: CFTypeRef) -> CGSize? {
    if CFGetTypeID(attributeValue) == AXValueGetTypeID(),
       AXValueGetType(attributeValue as! AXValue) == .cgSize {
        var size = CGSize.zero
        if AXValueGetValue(attributeValue as! AXValue, .cgSize, &size) {
            return size
        }
    }
    return nil
}

// Convert CFTypeRef to AXUIElement
func getAXUIElementFromAXAttributeValue(_ attributeValue: CFTypeRef) -> AXUIElement? {
    if CFGetTypeID(attributeValue) == AXUIElementGetTypeID() {
        return attributeValue as! AXUIElement
    }
    return nil
}

// Convert CFTypeRef to Array of AXUIElement
func getAXUIElementArrayFromAXAttributeValue(_ attributeValue: CFTypeRef) -> [AXUIElement]? {
    if CFGetTypeID(attributeValue) == CFArrayGetTypeID(),
       let array = attributeValue as? [AXUIElement] {
        return array
    }
    return nil
}

// Convert CFTypeRef to Boolean
func getBoolFromAXAttributeValue(_ attributeValue: CFTypeRef) -> Bool? {
    if CFGetTypeID(attributeValue) == CFBooleanGetTypeID() {
        return CFBooleanGetValue( ( attributeValue as! CFBoolean ) )
    }
    return nil
}

// Convert CFTypeRef to NSNumber
func getNSNumberFromAXAttributeValue(_ attributeValue: CFTypeRef) -> NSNumber? {
    if CFGetTypeID(attributeValue) == CFNumberGetTypeID() {
        return attributeValue as? NSNumber
    }
    return nil
}

// Convert CFTypeRef to NSRange
func getNSRangeFromAXAttributeValue(_ attributeValue: CFTypeRef) -> NSRange? {
    if CFGetTypeID(attributeValue) == AXValueGetTypeID(),
       AXValueGetType(attributeValue as! AXValue) == .cfRange {
        var range = CFRange(location: 0, length: 0)
        if AXValueGetValue(attributeValue as! AXValue, .cfRange, &range) {
            return NSRange(location: range.location, length: range.length)
        }
    }
    return nil
}

// Convert CFTypeRef to URL
func getURLFromAXAttributeValue(_ attributeValue: CFTypeRef) -> URL? {
    if CFGetTypeID(attributeValue) == CFURLGetTypeID() {
        return attributeValue as? URL
    }
    return nil
}

// Convert CFTypeRef to Array of String
func getStringArrayFromAXAttributeValue(_ attributeValue: CFTypeRef) -> [String]? {
    if CFGetTypeID(attributeValue) == CFArrayGetTypeID(),
       let array = attributeValue as? [String] {
        return array
    }
    return nil
}

// Convert CFTypeRef to UInt
func getUIntFromAXAttributeValue(_ attributeValue: CFTypeRef) -> UInt? {
    if CFGetTypeID(attributeValue) == CFNumberGetTypeID(),
       let number = attributeValue as? NSNumber {
        return number.uintValue
    }
    return nil
}

// Convert CFTypeRef to AXNotificationType (string-based notifications)
func getAXNotificationTypeFromAXAttributeValue(_ attributeValue: CFTypeRef) -> String? {
    if CFGetTypeID(attributeValue) == CFStringGetTypeID() {
        return attributeValue as? String
    }
    return nil
}

// Convert CFTypeRef to AXObserverType (AXObserver reference)
func getAXObserverTypeFromAXAttributeValue(_ attributeValue: CFTypeRef) -> AXObserver? {
    if CFGetTypeID(attributeValue) == AXObserverGetTypeID() {
        return attributeValue as! AXObserver
    }
    return nil
}
