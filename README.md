# bluefin-swift

Experimental Swift server for the Tuna accessibility
ecosystem. Speaks the [Bluefin protocol](PROTOCOL.md)
over WebSocket; binds to the macOS Accessibility
(AX) APIs underneath.

Pairs with:

- `bluefin/` — TypeScript client. Sees a normalized
  async DOM-like tree.
- `yellowfin/` (future) — Linux server, same protocol.
- `blackfin/` (future) — Windows server, same protocol.

## What this does

- Bridges the macOS AX tree to a normalized
  cross-platform shape (canonical roles, states,
  actions, attributes).
- Listens for AX observer notifications and
  forwards them as protocol events.
- Exposes everything to clients via JSON-RPC over
  WebSocket. Same protocol whether the client is
  on the same machine or across the network.

## Status

Experimental. The protocol is firming up; expect
churn until v1.0.

## Build

```sh
swift build
```

Runs as a foreground process; binds to
`ws://127.0.0.1:<port>` by default. See `--help`
for flags.

## License

AGPL-3.0 — see `LICENSE`.
