# Bluefin Protocol v0.1 (draft)

Wire contract for `bluefin-swift`, the macOS Tuna
accessibility server.

## Goals

- One local parent process talks to one server process.
- The server carries raw macOS AX names on the wire.
- Sandcastle owns cross-platform normalization.
- Cheap incremental updates: the platform pushes raw AX
  notifications; clients invalidate cache and re-read.

## Transport

JSON-RPC 2.0 over stdio. The parent process starts
`bluefin-server`, writes UTF-8 JSON-RPC requests to stdin,
one JSON object per LF-delimited line, and reads responses
and notifications from stdout, one JSON object per
LF-delimited line.

Logs and pre-flight diagnostics are written to stderr.
There is exactly one client: the parent process connected
to stdin/stdout. There is no port, socket, listener, client
registry, TLS, or authentication layer in `bluefin-swift`.

- Client -> Server: `request` with `id`; `notification`
  without `id` is accepted and ignored.
- Server -> Client: `response` matching an `id`;
  `notification` without `id`.

### Process lifecycle

1. Parent process starts `bluefin-server`.
2. Server runs Accessibility pre-flight and writes
   `GRANTED` or `WARNING` diagnostics to stderr.
3. Server immediately writes a `welcome` notification to
   stdout.
4. Client may call any RPC by writing one request line.
5. When stdin closes, the server exits and all handles are
   invalid.

### Versioning

`welcome.protocol` carries `"0.1"`. Clients refuse to
proceed if the major.minor mismatches what they were built
against.

## Identity

### Node handles

A `NodeHandle` is an opaque string assigned by the server.
Clients MUST NOT parse or generate it. Format suggestion
(server-internal): `node:<uuid>`.

A handle is valid until the server pushes an event indicating
the node was removed or until the process exits. Calls
referencing an invalid handle return JSON-RPC error code
`-32004` ("handle no longer valid").

### Stable identities

`Node.stableId` is optional. On macOS this is currently read
from `AXIdentifier` when present. It may be `null`.

## Raw AX Data Model

`bluefin-swift` does not normalize roles, states, actions,
attributes, or notifications. Names on the wire are raw macOS
AX strings such as `AXRole`, `AXTitle`, `AXChildren`,
`AXButton`, `AXPress`, and `AXFocusedUIElementChanged`.

`node.getAttribute`, `node.getAttributes`, and `snapshot`
return maps keyed by the requested raw AX attribute names.
Unsupported or missing attributes return `null` for that
attribute without failing the whole request.

AX value conversion:

```json
AXPosition -> { "x": 0, "y": 0 }
AXSize -> { "width": 100, "height": 32 }
AXSelectedTextRange -> { "start": 0, "length": 3 }
```

`AXUIElement` values are returned as `NodeHandle` strings.
Arrays of `AXUIElement` values are returned as arrays of
handles.

## RPC Method Catalog

All methods are namespaced. Method names below include the
namespace.

### tree.getRoot

Returns the root node for the frontmost application.

params: none
result: `{ "handle": NodeHandle | null }`

### tree.getFocused

Returns the handle of the currently focused accessible
element in the frontmost application, or `null`.

params: none
result: `{ "handle": NodeHandle | null }`

### node.getAttribute

Read one raw AX attribute.

```json
params: { "handle": "node:abcd", "name": "AXRole" }
result: { "value": "AXButton" }
```

### node.getAttributes

Batched raw AX attribute read.

```json
params: {
  "handle": "node:abcd",
  "names": ["AXTitle", "AXRole", "AXChildren"]
}
result: {
  "attributes": {
    "AXTitle": "Compose",
    "AXRole": "AXButton",
    "AXChildren": ["node:child"]
  }
}
```

### node.setAttribute

Set one raw AX attribute. For AXValue-backed attributes,
the server wraps JSON objects back into native AXValue
instances where needed.

```json
params: {
  "handle": "node:abcd",
  "name": "AXSelectedTextRange",
  "value": { "start": 0, "length": 3 }
}
result: { "ok": true }
```

### node.getActions

Returns raw AX action names from `AXUIElementCopyActionNames`.

```json
params: { "handle": "node:abcd" }
result: { "actions": ["AXPress", "AXShowMenu"] }
```

### node.invokeAction

Invokes one raw AX action name.

```json
params: { "handle": "node:abcd", "action": "AXPress" }
result: { "ok": true }
```

Errors: `-32005` ("action not supported").

### node.getChildren

```json
params: { "handle": "node:abcd", "offset": 0, "limit": 50 }
result: { "children": ["node:child"], "total": 1 }
```

`offset`/`limit` paginate; default is all children.

### node.getParent

```json
params: { "handle": "node:abcd" }
result: { "handle": "node:parent" }
```

### node.getAncestors

Convenience: parent chain up to the root.

```json
params: { "handle": "node:abcd" }
result: { "ancestors": ["node:parent", "node:root"] }
```

### node.getSibling

```json
params: { "handle": "node:abcd", "direction": "next" }
result: { "handle": "node:sibling" }
```

`direction` is `"next"` or `"previous"`.

### subscribe

Subscribe to raw AX notification names. Sandcastle filters
and normalizes downstream.

```json
params: { "events": ["AXFocusedUIElementChanged", "AXValueChanged"] }
result: { "subscriptionId": "..." }
```

### unsubscribe

```json
params: { "subscriptionId": "..." }
result: { "ok": true }
```

### snapshot

Bulk fetch a subtree with chosen raw AX attributes in one
round trip.

```json
params: {
  "handle": "node:abcd",
  "depth": 1,
  "attributes": ["AXTitle", "AXRole", "AXChildren"]
}
result: {
  "node": {
    "handle": "node:abcd",
    "stableId": "main-window",
    "attributes": {
      "AXTitle": "Compose",
      "AXRole": "AXButton",
      "AXChildren": ["node:child"]
    },
    "children": []
  }
}
```

## Notifications

All notifications carry a `method` and `params`; no `id`.

### welcome

```json
{
  "jsonrpc": "2.0",
  "method": "welcome",
  "params": {
    "protocol": "0.1",
    "server": "bluefin-swift",
    "version": "0.1.0",
    "capabilities": {
      "platforms": ["macOS"],
      "writableAttributes": true,
      "transport": "stdio"
    }
  }
}
```

### axEvent

Raw AX notifications are emitted with the raw notification
name in `name`.

```json
params: {
  "subscriptionId": "...",
  "name": "AXFocusedUIElementChanged",
  "handle": "node:abcd"
}
```

### error

```json
params: { "code": -32001, "message": "Permission denied", "data": null }
```

Out-of-band server errors are not tied to a specific RPC.

## Error Codes

| code   | meaning                           |
| ------ | --------------------------------- |
| -32700 | Parse error (JSON-RPC standard)   |
| -32600 | Invalid Request                   |
| -32601 | Method not found                  |
| -32602 | Invalid params                    |
| -32603 | Internal error                    |
| -32001 | Permission denied (AX not granted) |
| -32002 | Application not responding        |
| -32004 | Handle no longer valid            |
| -32005 | Action not supported on this node |
| -32006 | Attribute not writable            |
| -32007 | Subscription not found            |
| -32008 | Capability not supported          |

## Cache Contract

Clients SHOULD cache attribute values keyed by
`(handle, raw AX attribute name)`. Invalidate on matching
raw AX notifications, removal events, and process exit.

Servers SHOULD NOT cache for the client; servers read the
platform tree on every call.

## Out Of Scope

- Server-side normalization.
- Socket transport.
- Streaming audio/braille.
- Hit-testing by screen coordinate (`tree.hitTest`).
- Authentication / TLS pinning.
