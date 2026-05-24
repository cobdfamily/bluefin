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
        case "node.getAttribute":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let name = try string(params["name"])
            return .object(["value": try await AttributeReader(registry: connection.registry).attribute(name, of: element)])
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
        case "node.getAncestors":
            let params = try objectParams(request.params)
            var current = try await element(from: params)
            var ancestors: [JSONValue] = []
            while let parent = try? (AXBindings.copyAttributeValue(current, attribute: "AXParent") as! AXUIElement) {
                ancestors.append(.string(await connection.registry.handle(for: parent)))
                current = parent
            }
            return .object(["ancestors": .array(ancestors)])
        case "node.getSibling":
            return try await sibling(request.params)
        case "node.invokeAction":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let action = try string(params["action"])
            guard let canonical = CanonicalAction(rawValue: action),
                  let axAction = ActionMap.canonicalToAX[canonical]?.first else {
                throw BluefinError.actionNotSupported
            }
            try AXBindings.performAction(element, action: axAction)
            return .object(["ok": .bool(true)])
        case "node.setAttribute":
            let params = try objectParams(request.params)
            let element = try await element(from: params)
            let name = try string(params["name"])
            guard let axName = AttributeMap.canonicalToAX[name]?.first, name == "value" || name == "selectedRange" else {
                throw BluefinError.attributeNotWritable
            }
            try AXBindings.setAttributeValue(element, attribute: axName, value: nativeValue(params["value"] ?? .null))
            return .object(["ok": .bool(true)])
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
            let attributes = (try? array(params["attributes"]).map { try string($0) }) ?? ["name", "role", "states"]
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
        switch name {
        case "name":
            return stringAttribute(element, ["AXTitle", "AXDescription"])
        case "role":
            let role = try? AXBindings.copyAttributeValue(element, attribute: "AXRole") as? String
            return .string(RoleMap.canonicalRole(for: role).rawValue)
        case "value":
            return jsonValue(try? AXBindings.copyAttributeValue(element, attribute: "AXValue")) ?? .null
        case "description":
            return stringAttribute(element, ["AXHelp", "AXDescription"])
        case "placeholder":
            return stringAttribute(element, ["AXPlaceholderValue"])
        case "states":
            return .array(readStates(element).map { .string($0.rawValue) })
        case "actions":
            var values: [JSONValue] = []
            if let names = try? AXUIElementCopyActionNamesCompat(element) {
                values = names.compactMap(ActionMap.canonicalAction).map { .string($0.rawValue) }
            }
            return .array(values)
        case "bounds":
            return bounds(element)
        case "level":
            return jsonValue(try? AXBindings.copyAttributeValue(element, attribute: "AXDisclosureLevel")) ?? .null
        case "valueRange":
            let min = jsonValue(try? AXBindings.copyAttributeValue(element, attribute: "AXMinValue")) ?? .null
            let max = jsonValue(try? AXBindings.copyAttributeValue(element, attribute: "AXMaxValue")) ?? .null
            return .object(["min": min, "max": max])
        case "selectedRange":
            return selectedRange(element)
        case "childCount":
            let children = (try? AXBindings.copyAttributeValue(element, attribute: "AXChildren") as? [AXUIElement]) ?? []
            return .number(Double(children.count))
        case "platformExtra":
            return platformExtra(element)
        default:
            throw BluefinError.invalidParams
        }
    }

    private func readStates(_ element: AXUIElement) -> [CanonicalState] {
        var attributes: [String: Any] = [:]
        for name in ["AXFocused", "AXFocusable", "AXSelected", "AXSelectable", "AXExpanded", "AXValue", "AXPressed", "AXEnabled", "AXRequired", "AXElementBusy", "AXModal", "AXHidden", "AXOffscreen", "AXNumberOfCharacters", "AXAllowsMultipleSelection", "AXHasPopup"] {
            if let value = try? AXBindings.copyAttributeValue(element, attribute: name) {
                attributes[name] = value
            }
        }
        return StateMap.states(from: attributes)
    }

    private func stringAttribute(_ element: AXUIElement, _ names: [String]) -> JSONValue {
        for name in names {
            if let value = try? AXBindings.copyAttributeValue(element, attribute: name) as? String, !value.isEmpty {
                return .string(value)
            }
        }
        return .null
    }

    private func bounds(_ element: AXUIElement) -> JSONValue {
        guard let positionValue = try? (AXBindings.copyAttributeValue(element, attribute: "AXPosition") as! AXValue),
              let sizeValue = try? (AXBindings.copyAttributeValue(element, attribute: "AXSize") as! AXValue) else {
            return .null
        }
        var point = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionValue, .cgPoint, &point)
        AXValueGetValue(sizeValue, .cgSize, &size)
        return .object([
            "x": .number(point.x),
            "y": .number(point.y),
            "width": .number(size.width),
            "height": .number(size.height)
        ])
    }

    private func selectedRange(_ element: AXUIElement) -> JSONValue {
        guard let rangeValue = try? (AXBindings.copyAttributeValue(element, attribute: "AXSelectedTextRange") as! AXValue) else {
            return .null
        }
        var range = CFRange()
        AXValueGetValue(rangeValue, .cfRange, &range)
        return .object(["start": .number(Double(range.location)), "length": .number(Double(range.length))])
    }

    private func platformExtra(_ element: AXUIElement) -> JSONValue {
        var object: [String: JSONValue] = [:]
        for name in ["AXRole", "AXSubrole", "AXRoleDescription", "AXIdentifier"] {
            if let value = jsonValue(try? AXBindings.copyAttributeValue(element, attribute: name)) {
                object[name] = value
            }
        }
        return .object(object)
    }
}

func AXUIElementCopyActionNamesCompat(_ element: AXUIElement) throws -> [String] {
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

func jsonValue(_ value: Any?) -> JSONValue? {
    guard let value else { return nil }
    if let value = value as? String { return .string(value) }
    if let value = value as? Bool { return .bool(value) }
    if let value = value as? NSNumber { return .number(value.doubleValue) }
    if let values = value as? [Any] { return .array(values.map { jsonValue($0) ?? .null }) }
    if let object = value as? [String: Any] { return .object(object.mapValues { jsonValue($0) ?? .null }) }
    return .string(String(describing: value))
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
