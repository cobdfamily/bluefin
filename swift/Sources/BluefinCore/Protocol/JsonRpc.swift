import Foundation

public struct JsonRpcRequest: Codable, Sendable {
    public var jsonrpc: String
    public var method: String
    public var params: JSONValue?
    public var id: JSONValue?

    public init(jsonrpc: String = "2.0", method: String, params: JSONValue? = nil, id: JSONValue? = nil) {
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = params
        self.id = id
    }
}

public struct JsonRpcResponse: Codable, Sendable {
    public var jsonrpc: String
    public var result: JSONValue?
    public var error: JsonRpcError?
    public var id: JSONValue?

    public init(jsonrpc: String = "2.0", result: JSONValue? = nil, error: JsonRpcError? = nil, id: JSONValue? = nil) {
        self.jsonrpc = jsonrpc
        self.result = result
        self.error = error
        self.id = id
    }
}

public struct JsonRpcError: Codable, Error, Sendable {
    public var code: Int
    public var message: String
    public var data: JSONValue?

    public init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

public struct JsonRpcNotification: Codable, Sendable {
    public var jsonrpc: String
    public var method: String
    public var params: JSONValue?

    public init(jsonrpc: String = "2.0", method: String, params: JSONValue? = nil) {
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = params
    }
}

public enum JSONValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let values):
            try container.encode(values)
        case .object(let value):
            try container.encode(value)
        }
    }
}
