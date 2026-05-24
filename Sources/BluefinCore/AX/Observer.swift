@preconcurrency import ApplicationServices
import Foundation

// AXEvent.name intentionally carries the raw AX notification
// string. rawNotification is kept as a duplicate for source
// compatibility with existing callers during the transport
// refactor; both fields contain the same value.
public struct AXEvent {
    public var name: String
    public var element: AXUIElement
    public var rawNotification: String

    public init(name: String, element: AXUIElement, rawNotification: String) {
        self.name = name
        self.element = element
        self.rawNotification = rawNotification
    }
}

public final class AXEventObserver {
    public static let relevantNotifications: [String] = [
        "AXFocusedUIElementChanged",
        "AXFocusedWindowChanged",
        "AXValueChanged",
        "AXTitleChanged",
        "AXSelectedChildrenChanged",
        "AXSelectedRowsChanged",
        "AXSelectedTextChanged",
        "AXCreated",
        "AXUIElementDestroyed"
    ]

    private let observer: AXObserver
    private let continuation: AsyncStream<AXEvent>.Continuation

    public let events: AsyncStream<AXEvent>

    public init(processID: pid_t, element: AXUIElement) throws {
        var streamContinuation: AsyncStream<AXEvent>.Continuation!
        self.events = AsyncStream { continuation in
            streamContinuation = continuation
        }
        self.continuation = streamContinuation

        var createdObserver: AXObserver?
        let createError = AXObserverCreate(processID, { _, element, notification, context in
            guard let context else { return }
            let owner = Unmanaged<AXEventObserver>.fromOpaque(context).takeUnretainedValue()
            owner.receive(element: element, notification: notification as String)
        }, &createdObserver)
        try AXBindings.throwIfNeeded(createError)
        guard let createdObserver else {
            throw BluefinError.internalError("AXObserverCreate returned no observer")
        }
        self.observer = createdObserver

        let context = Unmanaged.passUnretained(self).toOpaque()
        for notification in Self.relevantNotifications {
            let error = AXObserverAddNotification(createdObserver, element, notification as CFString, context)
            if error != .notificationAlreadyRegistered {
                try AXBindings.throwIfNeeded(error)
            }
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(createdObserver), .defaultMode)
    }

    deinit {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        continuation.finish()
    }

    private func receive(element: AXUIElement, notification: String) {
        continuation.yield(AXEvent(name: notification, element: element, rawNotification: notification))
    }
}
