import ApplicationServices
import Foundation

public enum AXBindings {
    public static func copyAttributeNames(_ element: AXUIElement) throws -> [String] {
        var names: CFArray?
        let error = AXUIElementCopyAttributeNames(element, &names)
        try throwIfNeeded(error)
        return (names as? [String]) ?? []
    }

    public static func copyAttributeValue(_ element: AXUIElement, attribute: String) throws -> Any? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        try throwIfNeeded(error)
        return value
    }

    public static func performAction(_ element: AXUIElement, action: String) throws {
        let error = AXUIElementPerformAction(element, action as CFString)
        try throwIfNeeded(error)
    }

    public static func setAttributeValue(_ element: AXUIElement, attribute: String, value: Any) throws {
        let error = AXUIElementSetAttributeValue(element, attribute as CFString, value as CFTypeRef)
        try throwIfNeeded(error)
    }

    public static func throwIfNeeded(_ error: AXError) throws {
        guard error != .success else { return }
        throw bluefinError(for: error)
    }

    public static func bluefinError(for error: AXError) -> BluefinError {
        switch error {
        case .success:
            return .internalError("Unexpected AX success error mapping")
        case .apiDisabled, .notImplemented:
            return .permissionDenied
        case .cannotComplete, .failure:
            return .applicationNotResponding
        case .invalidUIElement, .invalidUIElementObserver:
            return .invalidHandle
        case .actionUnsupported:
            return .actionNotSupported
        case .attributeUnsupported, .parameterizedAttributeUnsupported:
            return .invalidParams
        case .illegalArgument:
            return .invalidParams
        case .notificationUnsupported, .notificationAlreadyRegistered, .notificationNotRegistered:
            return .capabilityNotSupported
        case .noValue:
            return .invalidParams
        case .notEnoughPrecision:
            return .invalidParams
        @unknown default:
            return .internalError("AX error \(error.rawValue)")
        }
    }
}
