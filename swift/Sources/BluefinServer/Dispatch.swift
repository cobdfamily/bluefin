import AppKit
import ApplicationServices
import BluefinCore
import Foundation

struct JsonRpcDispatcher {
    let connection: ClientConnection

    func dispatch(text: String) async -> JsonRpcResponse? {
        guard let data = text.data(using: .utf8),
              let request = try? JSONDecoder().decode(JsonRpcRequest.self, from: data) else {
            return JsonRpcResponse(error: BluefinError.parseError.jsonRpcError, id: nil)
        }
        guard request.jsonrpc == "2.0" else {
            return JsonRpcResponse(error: BluefinError.invalidRequest.jsonRpcError, id: request.id)
        }
        guard request.id != nil else {
            return nil
        }

        do {
            let result = try await route(request)
            return JsonRpcResponse(result: result, id: request.id)
        } catch let error as BluefinError {
            return JsonRpcResponse(error: error.jsonRpcError, id: request.id)
        } catch {
            return JsonRpcResponse(error: BluefinError.internalError(String(describing: error)).jsonRpcError, id: request.id)
        }
    }

    private func route(_ request: JsonRpcRequest) async throws -> JSONValue {
        switch request.method {
        case "node.getActions":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            return .object(["actions": .array(try copyActionNames(element).map { .string($0) })])
        case "node.getAncestors":
            let params = try objectParams(request.params)
            var current = try await element(from: params)
            var ancestors: [JSONValue] = []
            while let parent = try? (AXBindings.copyAttributeValue(current, attribute: "AXParent") as! AXUIElement) {
                ancestors.append(.string(await connection.registry.handle(for: parent)))
                current = parent
            }
            return .object(["ancestors": .array(ancestors)])
        case "node.getAttribute":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let name = try string(params["name"])
            return .object(["value": try await AttributeReader(registry: connection.registry).attribute(name, of: element)])
        case "node.getAttributeNames":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            return .object(["names": .array(try AXBindings.copyAttributeNames(element).map { .string($0) })])
        case "node.getAttributes":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let names = try array(params["names"]).map { try string($0) }
            let reader = AttributeReader(registry: connection.registry)
            var attributes: [String: JSONValue] = [:]
            for name in names {
                attributes[name] = try await reader.attribute(name, of: element)
            }
            return .object(["attributes": .object(attributes)])
        case "node.getChildren":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let children = (try? AXBindings.copyAttributeValue(element, attribute: "AXChildren") as? [AXUIElement]) ?? []
            let offset = Int(number(params["offset"]) ?? 0)
            let limit = params["limit"].flatMap(number).map(Int.init) ?? children.count
            let slice = children.dropFirst(max(0, offset)).prefix(max(0, limit))
            let handles = await slice.asyncMap { await connection.registry.handle(for: $0) }
            return .object(["children": .array(handles.map { .string($0) }), "total": .number(Double(children.count))])
        case "node.getParent":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let parent = try? (AXBindings.copyAttributeValue(element, attribute: "AXParent") as! AXUIElement)
            if let parent {
                return .object(["handle": .string(await connection.registry.handle(for: parent))])
            }
            return .object(["handle": .null])
        case "node.getSibling":
            return try await sibling(request.params)
        case "node.invokeAction":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            try AXBindings.performAction(element, action: try string(params["action"]))
            return .object(["ok": .bool(true)])
        case "node.setAttribute":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let name = try string(params["name"])
            try AXBindings.setAttributeValue(
                element,
                attribute: name,
                value: try nativeValue(params["value"] ?? .null, attribute: name))
            return .object(["ok": .bool(true)])
        case "security.getKeychainItem":
            let params = try objectParams(request.params)
            let value = try KeychainBindings.getGenericPassword(
                service: try string(params["service"]),
                account: try string(params["account"]))
            return .object(["value": value.map(JSONValue.string) ?? .null])
        case "security.setKeychainItem":
            let params = try objectParams(request.params)
            try KeychainBindings.setGenericPassword(
                service: try string(params["service"]),
                account: try string(params["account"]),
                value: try string(params["value"]))
            return .object(["ok": .bool(true)])
        case "system.getBatteryStatus":
            let status = PowerBindings.batteryStatus()
            return .object([
                "percentage": status.percentage.map { .number($0) } ?? .null,
                "isCharging": .bool(status.isCharging),
                "isPresent": .bool(status.isPresent)
            ])
        case "system.isAccessibilityEnabled":
            return .object(["enabled": .bool(AXBindings.canQueryAccessibility(
                pid: ProcessInfo.processInfo.processIdentifier))])
        case "system.runAppleScript":
            let params = try objectParams(request.params)
            let outcome = AppleScriptBindings.run(source: try string(params["source"]))
            var result: [String: JSONValue] = [
                "result": .string(outcome.result),
                "isError": .bool(outcome.isError)
            ]
            if let message = outcome.errorMessage {
                result["errorMessage"] = .string(message)
            }
            return .object(result)
        case "tree.getFocused":
            // Query the frontmost app's focused element. Per-app
            // AX queries succeed where system-wide fails when this
            // binary inherits parent-process AX trust without its
            // own TCC entry. Falls back to the focused window if
            // the app itself reports no value (Safari, Chrome do
            // this -- focus lives on the window, not the app).
            guard let frontmost = NSWorkspace.shared.frontmostApplication else {
                return .object(["handle": .null])
            }
            let app = AXUIElementCreateApplication(frontmost.processIdentifier)
            if let focused = copyChildElement(app, kAXFocusedUIElementAttribute) {
                return .object(["handle": .string(await connection.registry.handle(for: focused))])
            }
            if let window = copyChildElement(app, kAXFocusedWindowAttribute),
               let focused = copyChildElement(window, kAXFocusedUIElementAttribute) {
                return .object(["handle": .string(await connection.registry.handle(for: focused))])
            }
            return .object(["handle": .null])
        case "tree.getRoot":
            // The "root" exposed to clients is the frontmost
            // application's AX element. AXUIElementCreateSystemWide
            // works in theory but in practice many parent processes
            // (eg. Terminal) inherit only per-application AX
            // permission, never system-wide. Bluetide takes the
            // same per-app approach for the same reason.
            guard let frontmost = NSWorkspace.shared.frontmostApplication else {
                return .object(["handle": .null])
            }
            let app = AXUIElementCreateApplication(frontmost.processIdentifier)
            return .object(["handle": .string(await connection.registry.handle(for: app))])
        case "subscribe":
            let params = try objectParams(request.params)
            let events = try array(params["events"]).map { try string($0) }
            return .object(["subscriptionId": .string(connection.subscribe(events: events))])
        case "unsubscribe":
            let params = try objectParams(request.params)
            try connection.unsubscribe(id: try string(params["subscriptionId"]))
            return .object(["ok": .bool(true)])
        case "snapshot":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let depth = Int(number(params["depth"]) ?? 1)
            let attributes = (try? array(params["attributes"]).map { try string($0) }) ?? ["AXTitle", "AXRole"]
            return .object(["node": try await snapshot(element: element, depth: depth, attributes: attributes)])
        default:
            throw BluefinError.methodNotFound
        }
    }

    private func sibling(_ rawParams: JSONValue?) async throws -> JSONValue {
        let params = try objectParams(rawParams)
        let element = try await element(from: params)
        let direction = try string(params["direction"])
        guard let parent = try? (AXBindings.copyAttributeValue(element, attribute: "AXParent") as! AXUIElement),
              let children = try? AXBindings.copyAttributeValue(parent, attribute: "AXChildren") as? [AXUIElement] else {
            return .object(["handle": .null])
        }
        let currentHash = CFHash(element)
        guard let index = children.firstIndex(where: { CFHash($0) == currentHash }) else {
            return .object(["handle": .null])
        }
        let siblingIndex = direction == "next" ? index + 1 : index - 1
        guard children.indices.contains(siblingIndex) else {
            return .object(["handle": .null])
        }
        return .object(["handle": .string(await connection.registry.handle(for: children[siblingIndex]))])
    }

    private func snapshot(element: AXUIElement, depth: Int, attributes: [String]) async throws -> JSONValue {
        let handle = await connection.registry.handle(for: element)
        let reader = AttributeReader(registry: connection.registry)
        var values: [String: JSONValue] = [:]
        for attribute in attributes {
            values[attribute] = try await reader.attribute(attribute, of: element)
        }
        let stableId = try? AXBindings.copyAttributeValue(element, attribute: "AXIdentifier") as? String
        var children: [JSONValue] = []
        if depth > 0, let axChildren = try? AXBindings.copyAttributeValue(element, attribute: "AXChildren") as? [AXUIElement] {
            for child in axChildren {
                children.append(try await snapshot(element: child, depth: depth - 1, attributes: attributes))
            }
        }
        return .object([
            "handle": .string(handle),
            "stableId": stableId.map(JSONValue.string) ?? .null,
            "attributes": .object(values),
            "children": .array(children)
        ])
    }

    private func element(from params: [String: JSONValue]) async throws -> AXUIElement {
        try await connection.registry.element(for: string(params["handle"]))
    }
}

// Free helper -- AXUIElementCopyAttributeValue + cast to
// AXUIElement, returning nil on any failure or unexpected
// type. Used for navigating focus chains where missing
// links are routine, not errors.
private func copyChildElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
    var raw: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(element, attribute as CFString, &raw)
    guard err == .success, let value = raw else { return nil }
    return (value as! AXUIElement)
}

struct AttributeReader {
    let registry: NodeRegistry

    func attribute(_ name: String, of element: AXUIElement) async throws -> JSONValue {
        var raw: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name as CFString, &raw)
        if error == .attributeUnsupported || error == .noValue {
            return .null
        }
        try AXBindings.throwIfNeeded(error)
        return await jsonValue(raw, registry: registry) ?? .null
    }
}

func copyActionNames(_ element: AXUIElement) throws -> [String] {
    var names: CFArray?
    let error = AXUIElementCopyActionNames(element, &names)
    try AXBindings.throwIfNeeded(error)
    return (names as? [String]) ?? []
}

func objectParams(_ value: JSONValue?) throws -> [String: JSONValue] {
    guard case .object(let object) = value else { throw BluefinError.invalidParams }
    return object
}

func string(_ value: JSONValue?) throws -> String {
    guard case .string(let string) = value else { throw BluefinError.invalidParams }
    return string
}

func array(_ value: JSONValue?) throws -> [JSONValue] {
    guard case .array(let array) = value else { throw BluefinError.invalidParams }
    return array
}

func number(_ value: JSONValue?) -> Double? {
    guard case .number(let number) = value else { return nil }
    return number
}

func nativeValue(_ value: JSONValue, attribute: String) throws -> Any {
    switch attribute {
    case "AXPosition":
        let object = try objectParams(value)
        var point = CGPoint(x: number(object["x"]) ?? 0, y: number(object["y"]) ?? 0)
        guard let wrapped = AXValueCreate(.cgPoint, &point) else {
            throw BluefinError.invalidParams
        }
        return wrapped
    case "AXSize":
        let object = try objectParams(value)
        var size = CGSize(width: number(object["width"]) ?? 0, height: number(object["height"]) ?? 0)
        guard let wrapped = AXValueCreate(.cgSize, &size) else {
            throw BluefinError.invalidParams
        }
        return wrapped
    case "AXSelectedTextRange":
        let object = try objectParams(value)
        var range = CFRange(
            location: Int(number(object["start"]) ?? 0),
            length: Int(number(object["length"]) ?? 0))
        guard let wrapped = AXValueCreate(.cfRange, &range) else {
            throw BluefinError.invalidParams
        }
        return wrapped
    default:
        return nativeValue(value)
    }
}

func nativeValue(_ value: JSONValue) -> Any {
    switch value {
    case .null:
        return NSNull()
    case .bool(let value):
        return value
    case .number(let value):
        return value
    case .string(let value):
        return value
    case .array(let values):
        return values.map(nativeValue)
    case .object(let object):
        return object.mapValues(nativeValue)
    }
}

func jsonValue(_ value: Any?, registry: NodeRegistry) async -> JSONValue? {
    guard let value else { return nil }
    if isAXUIElement(value) {
        return .string(await registry.handle(for: value as! AXUIElement))
    }
    if CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID() {
        return axValue(value as! AXValue)
    }
    if let value = value as? String { return .string(value) }
    if let value = value as? Bool { return .bool(value) }
    if let value = value as? NSNumber { return .number(value.doubleValue) }
    if let values = value as? [Any] {
        var converted: [JSONValue] = []
        for item in values {
            converted.append(await jsonValue(item, registry: registry) ?? .null)
        }
        return .array(converted)
    }
    if let object = value as? [String: Any] {
        var converted: [String: JSONValue] = [:]
        for (key, item) in object {
            converted[key] = await jsonValue(item, registry: registry) ?? .null
        }
        return .object(converted)
    }
    return .string(String(describing: value))
}

func axValue(_ value: AXValue) -> JSONValue {
    switch AXValueGetType(value) {
    case .cgPoint:
        var point = CGPoint.zero
        guard AXValueGetValue(value, .cgPoint, &point) else { return .null }
        return .object(["x": .number(point.x), "y": .number(point.y)])
    case .cgSize:
        var size = CGSize.zero
        guard AXValueGetValue(value, .cgSize, &size) else { return .null }
        return .object(["width": .number(size.width), "height": .number(size.height)])
    case .cfRange:
        var range = CFRange()
        guard AXValueGetValue(value, .cfRange, &range) else { return .null }
        return .object(["start": .number(Double(range.location)), "length": .number(Double(range.length))])
    case .cgRect:
        var rect = CGRect.zero
        guard AXValueGetValue(value, .cgRect, &rect) else { return .null }
        return .object([
            "x": .number(rect.origin.x),
            "y": .number(rect.origin.y),
            "width": .number(rect.size.width),
            "height": .number(rect.size.height)
        ])
    default:
        return .string(String(describing: value))
    }
}

func isAXUIElement(_ value: Any) -> Bool {
    CFGetTypeID(value as CFTypeRef) == AXUIElementGetTypeID()
}

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var values: [T] = []
        for element in self {
            values.append(await transform(element))
        }
        return values
    }
}
