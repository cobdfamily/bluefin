import Foundation

public enum CanonicalRole: String, Codable, CaseIterable, Sendable {
    case application, window, dialog, document
    case group, region, banner, contentinfo, navigation
    case main, complementary, search, form
    case heading, paragraph, link
    case button, toggleButton, menuButton, splitButton
    case checkbox, radioButton, `switch`
    case textbox, searchbox, editor, password
    case combobox, listbox, list, listitem
    case tree, treeitem
    case table, row, cell, columnHeader, rowHeader
    case tab, tabPanel, tabList
    case menu, menuItem, menuItemCheckbox, menuItemRadio
    case toolbar, separator
    case progress, slider, spinButton, scrollbar
    case image, icon, figure
    case tooltip, status, alert, log, marquee, timer
    case unknown
}

public enum CanonicalState: String, Codable, CaseIterable, Sendable {
    case focused, focusable
    case selected, selectable
    case expanded, collapsed
    case checked, mixed
    case pressed
    case disabled, readonly, required
    case busy, modal, hidden, offscreen
    case multiline, multiselect
    case hasPopup
}

public enum CanonicalAction: String, Codable, CaseIterable, Sendable {
    case invoke, focus, setValue
    case press, release
    case showMenu, dismiss
    case scrollIntoView
    case expand, collapse
    case increment, decrement
}

public struct Rect: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct Range: Codable, Equatable, Sendable {
    public var start: Double
    public var length: Double
    public var step: Double?

    public init(start: Double, length: Double, step: Double? = nil) {
        self.start = start
        self.length = length
        self.step = step
    }
}

public struct NodeSnapshot: Codable, Equatable, Sendable {
    public var handle: String
    public var stableId: String?
    public var attributes: [String: JSONValue]
    public var children: [NodeSnapshot]

    public init(handle: String, stableId: String? = nil, attributes: [String: JSONValue], children: [NodeSnapshot]) {
        self.handle = handle
        self.stableId = stableId
        self.attributes = attributes
        self.children = children
    }
}

public enum BluefinError: Error, Equatable, Sendable {
    case parseError
    case invalidRequest
    case methodNotFound
    case invalidParams
    case internalError(String)
    case permissionDenied
    case applicationNotResponding
    case invalidHandle
    case actionNotSupported
    case attributeNotWritable
    case subscriptionNotFound
    case capabilityNotSupported

    public var jsonRpcError: JsonRpcError {
        switch self {
        case .parseError:
            return JsonRpcError(code: -32700, message: "Parse error")
        case .invalidRequest:
            return JsonRpcError(code: -32600, message: "Invalid Request")
        case .methodNotFound:
            return JsonRpcError(code: -32601, message: "Method not found")
        case .invalidParams:
            return JsonRpcError(code: -32602, message: "Invalid params")
        case .internalError(let message):
            return JsonRpcError(code: -32603, message: message)
        case .permissionDenied:
            return JsonRpcError(code: -32001, message: "Permission denied")
        case .applicationNotResponding:
            return JsonRpcError(code: -32002, message: "Application not responding")
        case .invalidHandle:
            return JsonRpcError(code: -32004, message: "handle no longer valid")
        case .actionNotSupported:
            return JsonRpcError(code: -32005, message: "action not supported")
        case .attributeNotWritable:
            return JsonRpcError(code: -32006, message: "Attribute not writable")
        case .subscriptionNotFound:
            return JsonRpcError(code: -32007, message: "Subscription not found")
        case .capabilityNotSupported:
            return JsonRpcError(code: -32008, message: "Capability not supported")
        }
    }
}
