import Foundation

public enum StateMap {
    public struct Rule: Sendable {
        public var attribute: String
        public var expectedValue: JSONValue?
        public var state: CanonicalState

        public init(attribute: String, expectedValue: JSONValue? = nil, state: CanonicalState) {
            self.attribute = attribute
            self.expectedValue = expectedValue
            self.state = state
        }
    }

    public static let platformEntries: [CanonicalState: [String]] = [
        .focused: ["AXFocused"],
        .focusable: ["AXFocusable"],
        .selected: ["AXSelected"],
        .selectable: ["AXSelectable"],
        .expanded: ["AXExpanded=true"],
        .collapsed: ["AXExpanded=false"],
        .checked: ["AXValue=1"],
        .mixed: ["AXValue=mixed"],
        .pressed: ["AXPressed"],
        .disabled: ["AXEnabled=false"],
        .readonly: ["AXValue:readonly"],
        .required: ["AXRequired"],
        .busy: ["AXElementBusy"],
        .modal: ["AXModal"],
        .hidden: ["AXHidden"],
        .offscreen: ["AXOffscreen"],
        .multiline: ["AXNumberOfCharacters"],
        .multiselect: ["AXAllowsMultipleSelection"],
        .hasPopup: ["AXHasPopup"]
    ]

    public static func states(from attributes: [String: Any]) -> [CanonicalState] {
        var states = Set<CanonicalState>()
        if attributes["AXFocused"] as? Bool == true { states.insert(.focused) }
        if attributes["AXFocusable"] as? Bool == true { states.insert(.focusable) }
        if attributes["AXSelected"] as? Bool == true { states.insert(.selected) }
        if attributes["AXSelectable"] as? Bool == true { states.insert(.selectable) }
        if let expanded = attributes["AXExpanded"] as? Bool { states.insert(expanded ? .expanded : .collapsed) }
        if let value = attributes["AXValue"] {
            if let number = value as? NSNumber, number.boolValue { states.insert(.checked) }
            if String(describing: value).lowercased() == "mixed" { states.insert(.mixed) }
        }
        if attributes["AXPressed"] as? Bool == true { states.insert(.pressed) }
        if attributes["AXEnabled"] as? Bool == false { states.insert(.disabled) }
        if attributes["AXRequired"] as? Bool == true { states.insert(.required) }
        if attributes["AXElementBusy"] as? Bool == true { states.insert(.busy) }
        if attributes["AXModal"] as? Bool == true { states.insert(.modal) }
        if attributes["AXHidden"] as? Bool == true { states.insert(.hidden) }
        if attributes["AXOffscreen"] as? Bool == true { states.insert(.offscreen) }
        if attributes["AXNumberOfCharacters"] != nil { states.insert(.multiline) }
        if attributes["AXAllowsMultipleSelection"] as? Bool == true { states.insert(.multiselect) }
        if attributes["AXHasPopup"] as? Bool == true { states.insert(.hasPopup) }
        return states.sorted { $0.rawValue < $1.rawValue }
    }
}
