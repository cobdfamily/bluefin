# Developing bluefin-swift

Notes for working on this server. The codebase
itself is small; what bites people is macOS's
accessibility-permission model.

## Build

```sh
swift build
```

Outputs land in `.build/`. The executable is
`.build/debug/bluefin-server`.

## Run

```sh
swift run bluefin-server
```

The server uses stdio. The parent process writes
LF-delimited JSON-RPC requests to stdin and reads
LF-delimited responses / notifications from
stdout. Logs go to stderr.

```sh
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tree.getRoot"}' | swift run bluefin-server
```

## Accessibility permission

The server reads from the system AX tree. macOS
demands explicit permission per binary; without
it, every AX call returns
`kAXErrorAPIDisabled` and the server can't see
any other app.

The first time you `swift run`, macOS prompts:

> "swift" would like to control this computer
> using accessibility features.

Allow it. The grant is keyed on the binary path,
so re-running `swift run` reuses the same grant.
If you `swift build -c release` and run the
release binary, that's a **different path** and
you'll be prompted again.

To inspect / revoke:

  System Settings -> Privacy & Security ->
  Accessibility -> swift (or bluefin-server)

If the prompt never appeared and AX calls fail
with -32001, run:

```sh
sudo tccutil reset Accessibility
swift run bluefin-server
```

This wipes the AX grant table; macOS will
re-prompt on the next call.

## Tests

```sh
swift test
```

Unit tests live under `Tests/BluefinCoreTests/`.
They cover JSON-RPC encoding and protocol wire
shapes pinned by `PROTOCOL.md`.

There are no integration tests in the Swift
suite -- AX calls require a logged-in user
session and a granted AX permission, which is
hostile to CI. Integration tests live in
bluefin (the TypeScript client) and are run
manually against a real desktop.

## Manual smoke test

Send one JSON-RPC request line on stdin:

```sh
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tree.getRoot"}' | swift run bluefin-server
```

You should see the `welcome` notification first
(server writes it on startup), then a JSON-RPC
response with `{ "handle": "node:..." }` on
stdout. Accessibility pre-flight messages appear
on stderr.

## Releasing

This is an experimental repo. There are no
publish workflows yet. When the protocol firms
up, this section gets a tagged-release path.

## Hacking on the protocol

`PROTOCOL.md` is the contract. If you need to
add a method or event:

1. Edit `PROTOCOL.md` first. Open a PR that's
   spec-only and ask for review.
2. Once the spec settles, implement in
   `Sources/`. The order is usually:
   protocol types -> AX bindings -> dispatch.
3. Add a test under `Tests/BluefinCoreTests/`
   that pins the encoding.
4. Update `bluefin/` (the TypeScript client)
   in a paired PR.

Yellowfin (Linux) and blackfin (Windows) will
need matching changes; flag them in the spec PR.
