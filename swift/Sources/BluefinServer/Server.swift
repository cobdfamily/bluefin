import BluefinCore
import Foundation

actor StdoutWriter {
    private let encoder = JSONEncoder()
    private let output = FileHandle.standardOutput

    func write<T: Encodable>(_ value: T) {
        guard var data = try? encoder.encode(value) else { return }
        data.append(0x0a)
        output.write(data)
    }
}

final class BluefinServer {
    let client: ClientConnection

    init() {
        self.client = ClientConnection(writer: StdoutWriter())
    }

    func start() {
        // One Task owns the lifetime: welcome first, then a
        // serial loop of (read line / await dispatch / write).
        // Awaiting each dispatch inline means stdin EOF never
        // strands an in-flight response, and writes can't
        // interleave from concurrent dispatches.
        Task { [client] in
            await client.sendWelcome()
            for await line in stdinLines() {
                await client.handle(text: line)
            }
            exit(0)
        }
    }
}

final class ClientConnection: @unchecked Sendable {
    let registry = NodeRegistry()
    private let writer: StdoutWriter
    private let subscriptionsLock = NSLock()
    private var subscriptions: [String: Set<String>] = [:]

    init(writer: StdoutWriter) {
        self.writer = writer
    }

    func handle(text: String) async {
        let response = await JsonRpcDispatcher(connection: self).dispatch(text: text)
        if let response {
            await send(response: response)
        }
    }

    func subscribe(events: [String]) -> String {
        let id = UUID().uuidString.lowercased()
        subscriptionsLock.lock()
        subscriptions[id] = Set(events)
        subscriptionsLock.unlock()
        return id
    }

    func unsubscribe(id: String) throws {
        subscriptionsLock.lock()
        let removed = subscriptions.removeValue(forKey: id) != nil
        subscriptionsLock.unlock()
        guard removed else {
            throw BluefinError.subscriptionNotFound
        }
    }

    func sendWelcome() async {
        let params: JSONValue = .object([
            "protocol": .string("0.1"),
            "server": .string("bluefin-swift"),
            "version": .string("0.1.0"),
            "capabilities": .object([
                "platforms": .array([.string("macOS")]),
                "writableAttributes": .bool(true),
                "transport": .string("stdio")
            ])
        ])
        await send(notification: JsonRpcNotification(method: "welcome", params: params))
    }

    func send(notification: JsonRpcNotification) async {
        await writer.write(notification)
    }

    func send(response: JsonRpcResponse) async {
        await writer.write(response)
    }
}

// Async sequence of LF-delimited UTF-8 lines from
// stdin. Yields on a background thread (availableData
// blocks) but the consumer awaits on the Task that
// owns the loop, so the dispatch is structured.
private func stdinLines() -> AsyncStream<String> {
    AsyncStream { continuation in
        let thread = Thread {
            var buffer = Data()
            while true {
                let chunk = FileHandle.standardInput.availableData
                if chunk.isEmpty {
                    if !buffer.isEmpty,
                       let line = String(data: buffer, encoding: .utf8) {
                        continuation.yield(line)
                    }
                    continuation.finish()
                    return
                }
                buffer.append(chunk)
                while let newline = buffer.firstIndex(of: 0x0a) {
                    let lineData = buffer[..<newline]
                    buffer.removeSubrange(...newline)
                    guard !lineData.isEmpty else { continue }
                    if let line = String(data: lineData, encoding: .utf8) {
                        continuation.yield(line)
                    }
                }
            }
        }
        thread.start()
    }
}

@main
enum Main {
    static func main() {
        // Pre-flight: announce whether we have the macOS
        // Accessibility permission. Without it every AX
        // call silently returns nothing, the server looks
        // healthy, and the operator wastes time chasing a
        // "why are the trees empty" red herring. Setting
        // BLUEFIN_PROMPT_AX=1 makes macOS open the
        // permission prompt on first run; default is a
        // pure check, no side effect, so the server can
        // run headless in CI without UI popping up.
        let prompt = ProcessInfo.processInfo.environment["BLUEFIN_PROMPT_AX"] == "1"
        // Surface the macOS prompt if requested -- but the
        // return value is unreliable. AXIsProcessTrustedWith-
        // Options often inherits trust from the parent
        // process (eg. Terminal) and reports true even when
        // real AX calls return kAXErrorAPIDisabled. The real
        // check is canQueryAccessibility, which makes an
        // actual per-app call against this process and
        // inspects the error code.
        _ = AXBindings.isProcessTrusted(prompt: prompt)
        let trusted = AXBindings.canQueryAccessibility(
            pid: ProcessInfo.processInfo.processIdentifier)
        if trusted {
            FileHandle.standardError.write(Data(
                "bluefin-server: Accessibility permission GRANTED. AX tree is queryable.\n".utf8))
        } else {
            FileHandle.standardError.write(Data("""
                bluefin-server: WARNING -- Accessibility permission NOT GRANTED.
                bluefin-server:   AX calls will silently return empty results.
                bluefin-server:   Grant via: System Settings -> Privacy & Security
                bluefin-server:              -> Accessibility -> add the binary at:
                bluefin-server:              \(Bundle.main.bundleURL.path)
                bluefin-server:   Or relaunch with BLUEFIN_PROMPT_AX=1 to surface the
                bluefin-server:   macOS permission prompt.
                bluefin-server:   See DEVELOPING.md for details.

                """.utf8))
        }
        let server = BluefinServer()
        server.start()
        FileHandle.standardError.write(Data(
            "bluefin-server: listening on stdio JSON-RPC\n".utf8))
        dispatchMain()
    }
}
