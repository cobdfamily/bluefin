# Bluefin Protocol v0.1 (draft)

Wire contract shared by every Tuna accessibility
server (bluefin-swift / yellowfin / blackfin) and
every client (bluefin TypeScript, future SDKs).

## Goals

- Same protocol works locally
  (`ws://127.0.0.1:<port>`) and remotely
  (`wss://host/`).
- Clients see ONE normalised tree shape regardless
  of the underlying platform.
- Platform-specific information is preserved under
  `platformExtra.*` so power users can drill in.
- Cheap incremental updates: the platform pushes
  change events; clients invalidate cache and
  re-read.

## Transport

JSON-RPC 2.0 over WebSocket. Single bi-directional
channel:

- Client -> Server: `request` (with `id`) and
  `notification` (no `id`).
- Server -> Client: `response` (matches an `id`),
  `notification` (no `id`; used for change events).

UTF-8 JSON text frames. Binary frames reserved for
future expansion (eg. screenshot snapshots).

### Connection lifecycle

1. Client opens the WebSocket.
2. Server immediately pushes a
   `welcome` notification with capabilities +
   protocol version (see "welcome" below).
3. Client may call any RPC.
4. Either side may close. If the server closes,
   all handles minted on that connection are
   considered invalid for that client; a new
   connection rebuilds handles from `tree.getRoot`.

### Versioning

`welcome.protocol` carries `"0.1"`. Clients refuse
to proceed if the major.minor mismatches what they
were built against. Servers may support multiple
versions concurrently.

## Identity

### Node handles

A `NodeHandle` is an opaque string assigned by the
server. Clients MUST NOT parse or generate them.
Format suggestion (server-internal): `node:<uuid>`.

A handle is valid until the server pushes a
`nodeRemoved` notification for it OR the connection
closes. Calls referencing an invalid handle return
JSON-RPC error code `-32004` ("handle no longer
valid").

### Stable identities

`Node.stableId` (optional) is a string that the
server can use to recognise the same logical node
across queries (eg. a window's title + an
accessibility identifier). Useful for tests and
recordings. May be `null` when the platform offers
no stable hint.

## Normalised data model

Everything that crosses the wire is normalised.
The server's job is to translate from native
AX / AT-SPI / UIA into these names BEFORE
sending. Platform-specific information that
doesn't fit goes under `platformExtra`.

### Canonical roles

A flat enum of strings. Servers map their native
role into one of these; if no good fit exists,
they send `"unknown"` and put the native role
under `platformExtra.role`.

```
application, window, dialog, document,
group, region, banner, contentinfo, navigation,
main, complementary, search, form,
heading, paragraph, link,
button, toggleButton, menuButton, splitButton,
checkbox, radioButton, switch,
textbox, searchbox, editor, password,
combobox, listbox, list, listitem,
tree, treeitem,
table, row, cell, columnHeader, rowHeader,
tab, tabPanel, tabList,
menu, menuItem, menuItemCheckbox, menuItemRadio,
toolbar, separator,
progress, slider, spinButton, scrollbar,
image, icon, figure,
tooltip, status, alert, log, marquee, timer,
unknown
```

### Canonical states

A node's `states` field is an array of strings
from this set. Absence means "not in this state".

```
focused, focusable,
selected, selectable,
expanded, collapsed,
checked, mixed,
pressed,
disabled, readonly, required,
busy, modal, hidden, offscreen,
multiline, multiselect,
hasPopup
```

### Canonical actions

A node's `actions` field is an array of strings the
client may pass to `node.invokeAction(handle, name)`.

```
invoke, focus, setValue,
press, release,
showMenu, dismiss,
scrollIntoView,
expand, collapse,
increment, decrement
```

### Canonical attributes

Read with `node.getAttribute(handle, name)` or
batched via `node.getAttributes(handle, names)`.

| name           | type     | notes                              |
| -------------- | -------- | ---------------------------------- |
| name           | string?  | accessible name (label)            |
| role           | string   | from canonical roles               |
| value          | string?  | current value (textbox, slider...) |
| description    | string?  | help / aria-describedby            |
| placeholder    | string?  | hint text                          |
| states         | string[] | from canonical states              |
| actions        | string[] | from canonical actions             |
| bounds         | Rect?    | `{x, y, width, height}`, screen coords  |
| level          | int?     | heading/treeitem nesting           |
| valueRange     | Range?   | `{min, max, step?}` for sliders    |
| selectedRange  | Range?   | text selection start/length        |
| childCount     | int      | children currently exposed         |
| platformExtra  | object   | pass-through native bag            |

`Rect`, `Range` are inline structs:

```json
{ "x": 0, "y": 0, "width": 100, "height": 32 }
{ "start": 0, "length": 3 }
```

## RPC method catalog

All methods are namespaced. Method names below
include the namespace.

### tree.getRoot

Returns the root node of every visible
application + the system itself.

  params: none
  result: { "handle": NodeHandle }

### tree.getFocused

Returns the handle of the currently-focused
accessible element, or `null`.

  params: none
  result: { "handle": NodeHandle | null }

### node.getAttribute

Read a single canonical attribute.

  params: { "handle": NodeHandle,
            "name": string }
  result: { "value": any | null }

### node.getAttributes

Batched read. The server SHOULD perform the
underlying native reads in parallel where
possible.

  params: { "handle": NodeHandle,
            "names": string[] }
  result: { "attributes":
              { [name: string]: any | null } }

### node.getChildren

  params: { "handle": NodeHandle,
            "offset"?: int,
            "limit"?:  int }
  result: { "children": NodeHandle[],
            "total":    int }

`offset`/`limit` paginate; default = all.

### node.getParent

  params: { "handle": NodeHandle }
  result: { "handle": NodeHandle | null }

### node.getAncestors

Convenience: parent chain up to the root.

  params: { "handle": NodeHandle }
  result: { "ancestors": NodeHandle[] }

### node.getSibling

  params: { "handle":    NodeHandle,
            "direction": "next" | "previous" }
  result: { "handle":    NodeHandle | null }

### node.invokeAction

  params: { "handle": NodeHandle,
            "action": string,
            "args"?:  any }
  result: { "ok": true }

Errors: `-32005` ("action not supported").

### node.setAttribute

For writable attributes (`value`,
`selectedRange`, ...). The set of writable
attributes per node is reported in the node's
`writableAttributes`.

  params: { "handle":    NodeHandle,
            "name":      string,
            "value":     any }
  result: { "ok": true }

### subscribe

Subscribe to event streams. Server holds the
subscription for the connection lifetime.

  params: { "events": string[],
            "scope"?: { "handle"?: NodeHandle,
                         "recursive"?: boolean } }
  result: { "subscriptionId": string }

If `scope` is omitted, the subscription is
global. If `handle` is set, events are filtered
to that subtree.

### unsubscribe

  params: { "subscriptionId": string }
  result: { "ok": true }

### snapshot

Bulk fetch a subtree with chosen attributes
in one round trip. The expensive walk happens
server-side; the client gets a fully populated
JSON tree back.

  params: { "handle":     NodeHandle,
            "depth"?:     int,        // default 1
            "attributes"?: string[] }  // default: name, role, states
  result: { "node": NodeSnapshot }

Where `NodeSnapshot`:

```json
{
  "handle":   "node:abcd",
  "stableId": "window-app-Mail#main",
  "attributes": { "name": "Compose", "role": "button",
                  "states": ["focusable"] },
  "children": [ NodeSnapshot, ... ]
}
```

## Notifications (server -> client)

All carry a `method` and `params`; no `id`.

### welcome

  params: { "protocol":     "0.1",
            "server":       "bluefin-swift" | ...,
            "version":      string,
            "capabilities": {
              "platforms":      string[],
              "writableAttributes": boolean,
              "supportsScreenshot": boolean
            } }

### nodeChanged

  params: { "handle":     NodeHandle,
            "attributes": { [name: string]: any | null } }

Only the attributes that actually changed are
sent. The client invalidates cached values for
those names.

### focusChanged

  params: { "handle": NodeHandle | null,
            "previous": NodeHandle | null }

### nodeAdded

  params: { "parent":   NodeHandle,
            "handle":   NodeHandle,
            "position": int }

### nodeRemoved

  params: { "handle": NodeHandle }

The client MUST drop the handle. Subsequent
calls with this handle return `-32004`.

### error

  params: { "code":    int,
            "message": string,
            "data"?:   any }

Out-of-band server errors (eg. AX permission
revoked). Not tied to a specific RPC.

## Error codes

| code   | meaning                              |
| ------ | ------------------------------------ |
| -32700 | Parse error (JSON-RPC standard)      |
| -32600 | Invalid Request                       |
| -32601 | Method not found                      |
| -32602 | Invalid params                        |
| -32603 | Internal error                        |
| -32001 | Permission denied (AX not granted)    |
| -32002 | Application not responding            |
| -32004 | Handle no longer valid (410-style)    |
| -32005 | Action not supported on this node     |
| -32006 | Attribute not writable                |
| -32007 | Subscription not found                |
| -32008 | Capability not supported (eg. screenshot on non-Mac) |

## Cache contract (clients)

Clients SHOULD cache attribute values keyed by
`(handle, attribute name)`. Invalidate on:

- Any matching `nodeChanged` for that handle +
  attribute.
- `nodeRemoved` for the handle (drop everything).
- Connection close (drop everything).

Servers SHOULD NOT cache for the client; servers
read the platform tree on every call. The
client-side cache is what saves round trips.

## Subscriptions: recommended defaults

A typical screen-reader client subscribes to:

- `focusChanged` (global)
- `nodeChanged`, `nodeAdded`, `nodeRemoved`
  scoped to the focused node's window subtree,
  re-subscribing each time focus crosses a
  window boundary.

## Out of scope (for v0.1)

- Streaming audio/braille.
- Hit-testing by screen coordinate
  (`tree.hitTest`). Likely v0.2.
- Cross-server federation (one client talking to
  bluefin + yellowfin simultaneously). Likely
  via a "fish" router.
- Authentication / TLS pinning. The server is
  expected to be bound to localhost or to be
  reached through a vetted tunnel for v0.1.
