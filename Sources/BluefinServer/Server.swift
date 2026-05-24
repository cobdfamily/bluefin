import BluefinCore
import Foundation
import Network

final class BluefinServer {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "bluefin.server")

    init(port: UInt16 = 8765) throws {
        let websocket = NWProtocolWebSocket.Options()
        websocket.autoReplyPing = true
        let parameters = NWParameters(tls: nil, tcp: NWProtocolTCP.Options())
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!)
        parameters.defaultProtocolStack.applicationProtocols.insert(websocket, at: 0)
        listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
    }

    func start() {
        listener.newConnectionHandler = { connection in
            let client = ClientConnection(connection: connection)
            client.start()
        }
        listener.start(queue: queue)
    }
}

final class ClientConnection {
    let connection: NWConnection
    let registry = NodeRegistry()
    private let queue = DispatchQueue(label: "bluefin.connection")
    private var subscriptions: [String: Set<String>] = [:]

    init(connection: NWConnection) {
        self.connection = connection
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .ready = state {
                self.sendWelcome()
                self.receiveNext()
            }
        }
        connection.start(queue: queue)
    }

    func subscribe(events: [String]) -> String {
        let id = UUID().uuidString.lowercased()
        subscriptions[id] = Set(events)
        return id
    }

    func unsubscribe(id: String) throws {
        guard subscriptions.removeValue(forKey: id) != nil else {
            throw BluefinError.subscriptionNotFound
        }
    }

    private func sendWelcome() {
        let params: JSONValue = .object([
            "protocol": .string("0.1"),
            "server": .string("bluefin-swift"),
            "version": .string("0.1.0"),
            "capabilities": .object([
                "platforms": .array([.string("macOS")]),
                "writableAttributes": .bool(true),
                "supportsScreenshot": .bool(false)
            ])
        ])
        send(notification: JsonRpcNotification(method: "welcome", params: params))
    }

    private func receiveNext() {
        connection.receiveMessage { [weak self] content, _, isComplete, error in
            guard let self else { return }
            if error != nil || !isComplete {
                return
            }
            if let content, let text = String(data: content, encoding: .utf8) {
                self.handle(text: text)
            }
            self.receiveNext()
        }
    }

    private func handle(text: String) {
        Task {
            let response = await JsonRpcDispatcher(connection: self).dispatch(text: text)
            if let response {
                self.send(response: response)
            }
        }
    }

    func send(notification: JsonRpcNotification) {
        sendEncodable(notification)
    }

    func send(response: JsonRpcResponse) {
        sendEncodable(response)
    }

    private func sendEncodable<T: Encodable>(_ value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "json", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed { _ in })
    }
}

@main
enum Main {
    static func main() throws {
        let port = UInt16(ProcessInfo.processInfo.environment["BLUEFIN_PORT"] ?? "") ?? 8765
        let server = try BluefinServer(port: port)
        server.start()
        dispatchMain()
    }
}
