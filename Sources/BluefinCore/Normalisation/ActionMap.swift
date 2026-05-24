import Foundation

public enum ActionMap {
    public static let axToCanonical: [String: CanonicalAction] = [
        "AXPress": .press,
        "AXConfirm": .invoke,
        "AXRaise": .focus,
        "AXSetValue": .setValue,
        "AXShowMenu": .showMenu,
        "AXCancel": .dismiss,
        "AXScrollToVisible": .scrollIntoView,
        "AXShowDefaultUI": .expand,
        "AXShowAlternateUI": .collapse,
        "AXIncrement": .increment,
        "AXDecrement": .decrement,
        "AXRelease": .release
    ]

    public static let canonicalToAX: [CanonicalAction: [String]] = [
        .invoke: ["AXPress", "AXConfirm"],
        .focus: ["AXRaise"],
        .setValue: ["AXSetValue"],
        .press: ["AXPress"],
        .release: ["AXRelease"],
        .showMenu: ["AXShowMenu"],
        .dismiss: ["AXCancel"],
        .scrollIntoView: ["AXScrollToVisible"],
        .expand: ["AXShowDefaultUI"],
        .collapse: ["AXShowAlternateUI"],
        .increment: ["AXIncrement"],
        .decrement: ["AXDecrement"]
    ]

    public static func canonicalAction(for axAction: String) -> CanonicalAction? {
        axToCanonical[axAction]
    }
}
