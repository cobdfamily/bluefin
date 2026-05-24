# Changelog

All notable changes to bluefin-swift. Format
roughly follows [Keep a Changelog]
(https://keepachangelog.com); dates are ISO 8601
in UTC.

## [Unreleased]

### Added
- Protocol v0.1 draft (`PROTOCOL.md`). JSON-RPC
  over WebSocket; normalised role / state /
  action / attribute taxonomies; cache contract;
  error code table. The shared contract for
  every Tuna server (bluefin-swift on macOS,
  yellowfin on Linux, blackfin on Windows).
- Swift Package skeleton: `BluefinCore`
  library (protocol types + AX bindings +
  normalisation + node registry) + `BluefinServer`
  executable (WebSocket listener + JSON-RPC
  dispatch). Swift-tools-version 5.9, macOS 13+,
  zero third-party Swift dependencies.
- Scaffold docs: README, DEVELOPING (AX
  permission setup), GRATITUDE (Apple AX +
  Network.framework + sibling projects),
  COMMENTS (fleet-wide comment standard).
- Implementation is in progress in the
  initial-release branch / main; first tagged
  release will come once a real client can do
  the full lifecycle (welcome -> tree.getRoot
  -> node.getAttributes -> subscribe -> events
  -> unsubscribe) end-to-end against a live AX
  tree.
