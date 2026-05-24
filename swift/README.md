# bluefin-swift

Experimental Swift server for the Tuna accessibility
ecosystem. Speaks the [Bluefin protocol](PROTOCOL.md)
over stdio JSON-RPC; binds to the macOS
Accessibility (AX) APIs underneath.

Pairs with:

- Sandcastle — TypeScript client layer. Owns
  normalization on top of raw AX names.
- `yellowfin/` (future) — Linux server, same protocol.
- `blackfin/` (future) — Windows server, same protocol.

## What this does

- Bridges the macOS AX tree to raw AX attributes,
  roles, actions, and notifications on the wire.
- Listens for AX observer notifications and
  forwards them as protocol events.
- Exposes everything to one parent process via
  LF-delimited JSON-RPC over stdin/stdout.

## Status

Experimental. The protocol is firming up; expect
churn until v1.0.

## Build

```sh
swift build
```

Runs as a foreground process; reads JSON-RPC
request lines from stdin and writes response /
notification lines to stdout.

## License

AGPL-3.0 — see `LICENSE`.
