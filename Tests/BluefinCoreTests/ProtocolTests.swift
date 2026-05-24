import XCTest
@testable import BluefinCore

final class ProtocolTests: XCTestCase {
    func testJsonRpcRequestShapeRoundTrips() throws {
        let json = """
        {"jsonrpc":"2.0","id":1,"method":"node.getAttribute","params":{"handle":"node:abcd","name":"AXRole"}}
        """
        let request = try JSONDecoder().decode(JsonRpcRequest.self, from: Data(json.utf8))
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.method, "node.getAttribute")
        XCTAssertEqual(request.id, .number(1))
        XCTAssertEqual(request.params, .object(["handle": .string("node:abcd"), "name": .string("AXRole")]))

        let encoded = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(object["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(object["method"] as? String, "node.getAttribute")
        XCTAssertEqual((object["params"] as? [String: Any])?["name"] as? String, "AXRole")
    }

    func testJsonRpcResponseShapeRoundTrips() throws {
        let response = JsonRpcResponse(result: .object(["handle": .string("node:abcd")]), id: .number(7))
        let encoded = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(object["jsonrpc"] as? String, "2.0")
        XCTAssertEqual((object["result"] as? [String: Any])?["handle"] as? String, "node:abcd")
        XCTAssertEqual(object["id"] as? Double, 7)

        let decoded = try JSONDecoder().decode(JsonRpcResponse.self, from: encoded)
        XCTAssertEqual(decoded.result, .object(["handle": .string("node:abcd")]))
    }

    func testJsonRpcErrorShapeMatchesProtocolCodes() throws {
        let error = BluefinError.invalidHandle.jsonRpcError
        let response = JsonRpcResponse(error: error, id: .string("a"))
        let encoded = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let errorObject = try XCTUnwrap(object["error"] as? [String: Any])
        XCTAssertEqual(errorObject["code"] as? Int, -32004)
        XCTAssertEqual(errorObject["message"] as? String, "handle no longer valid")
    }

    func testWelcomeNotificationShapeRoundTrips() throws {
        let notification = JsonRpcNotification(method: "welcome", params: .object([
            "protocol": .string("0.1"),
            "server": .string("bluefin-swift"),
            "version": .string("0.1.0"),
            "capabilities": .object([
                "platforms": .array([.string("macOS")]),
                "writableAttributes": .bool(true),
                "transport": .string("stdio")
            ])
        ]))
        let encoded = try JSONEncoder().encode(notification)
        let decoded = try JSONDecoder().decode(JsonRpcNotification.self, from: encoded)
        XCTAssertEqual(decoded.method, "welcome")
        XCTAssertEqual(decoded.params, notification.params)
    }

    func testNodeSnapshotShapeRoundTrips() throws {
        let snapshot = NodeSnapshot(
            handle: "node:abcd",
            stableId: "window-app-Mail#main",
            attributes: ["AXTitle": .string("Compose"), "AXRole": .string("AXButton")],
            children: []
        )
        let encoded = try JSONEncoder().encode(snapshot)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(object["handle"] as? String, "node:abcd")
        XCTAssertEqual(object["stableId"] as? String, "window-app-Mail#main")
        XCTAssertEqual((object["attributes"] as? [String: Any])?["AXRole"] as? String, "AXButton")

        let decoded = try JSONDecoder().decode(NodeSnapshot.self, from: encoded)
        XCTAssertEqual(decoded, snapshot)
    }

    func testRectAndRangeFieldNames() throws {
        let rectData = try JSONEncoder().encode(Rect(x: 0, y: 1, width: 100, height: 32))
        let rect = try XCTUnwrap(JSONSerialization.jsonObject(with: rectData) as? [String: Any])
        XCTAssertEqual(Set(rect.keys), ["x", "y", "width", "height"])

        let rangeData = try JSONEncoder().encode(Range(start: 0, length: 3))
        let range = try XCTUnwrap(JSONSerialization.jsonObject(with: rangeData) as? [String: Any])
        XCTAssertEqual(Set(range.keys), ["start", "length"])
    }
}
