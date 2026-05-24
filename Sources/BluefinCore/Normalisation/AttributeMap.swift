import Foundation

public enum AttributeMap {
    public static let axToCanonical: [String: String] = [
        "AXTitle": "name",
        "AXDescription": "description",
        "AXHelp": "description",
        "AXPlaceholderValue": "placeholder",
        "AXValue": "value",
        "AXRole": "role",
        "AXFocused": "states",
        "AXSelected": "states",
        "AXEnabled": "states",
        "AXPosition": "bounds",
        "AXSize": "bounds",
        "AXDisclosureLevel": "level",
        "AXMinValue": "valueRange",
        "AXMaxValue": "valueRange",
        "AXSelectedTextRange": "selectedRange",
        "AXChildren": "childCount",
        "AXActions": "actions",
        "AXIdentifier": "platformExtra"
    ]

    public static let canonicalToAX: [String: [String]] = [
        "name": ["AXTitle", "AXDescription"],
        "role": ["AXRole"],
        "value": ["AXValue"],
        "description": ["AXHelp", "AXDescription"],
        "placeholder": ["AXPlaceholderValue"],
        "states": ["AXFocused", "AXSelected", "AXEnabled", "AXExpanded"],
        "actions": ["AXActions"],
        "bounds": ["AXPosition", "AXSize"],
        "level": ["AXDisclosureLevel"],
        "valueRange": ["AXMinValue", "AXMaxValue"],
        "selectedRange": ["AXSelectedTextRange"],
        "childCount": ["AXChildren"],
        "platformExtra": ["AXIdentifier", "AXRoleDescription", "AXSubrole"]
    ]
}
