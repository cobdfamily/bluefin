@preconcurrency import ApplicationServices
import Foundation

public actor NodeRegistry {
    private var elementsByHandle: [String: AXUIElement] = [:]
    private var handlesByElementID: [CFHashCode: String] = [:]

    public init() {}

    public func handle(for element: AXUIElement) -> String {
        let elementID = CFHash(element)
        if let handle = handlesByElementID[elementID] {
            return handle
        }
        let handle = "node:\(UUID().uuidString.lowercased())"
        elementsByHandle[handle] = element
        handlesByElementID[elementID] = handle
        return handle
    }

    public func element(for handle: String) throws -> AXUIElement {
        guard let element = elementsByHandle[handle] else {
            throw BluefinError.invalidHandle
        }
        return element
    }

    public func drop(handle: String) {
        guard let element = elementsByHandle.removeValue(forKey: handle) else {
            return
        }
        handlesByElementID.removeValue(forKey: CFHash(element))
    }

    public func dropAll() {
        elementsByHandle.removeAll()
        handlesByElementID.removeAll()
    }
}
