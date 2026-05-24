# Changelog

All notable changes to bluefin-swift. Format
roughly follows [Keep a Changelog]
(https://keepachangelog.com); dates are ISO 8601
in UTC.

## [Unreleased]

### Added
- Protocol v0.1 draft (`PROTOCOL.md`). JSON-RPC
  over stdio; raw AX role / action / attribute /
  notification names; cache contract; error code
  table.
- Swift Package skeleton: `BluefinCore`
  library (protocol types + AX bindings + node
  registry) + `BluefinServer` executable (stdio
  JSON-RPC dispatch). Swift-tools-version 5.9,
  macOS 13+, zero third-party Swift dependencies.
- Scaffold docs: README, DEVELOPING (AX
  permission setup), GRATITUDE (Apple AX +
  sibling projects),
  COMMENTS (fleet-wide comment standard).
- Implementation is in progress in the
  initial-release branch / main; first tagged
  release will come once a real client can do
  the full lifecycle (welcome -> tree.getRoot
  -> node.getAttributes -> subscribe -> events
  -> unsubscribe) end-to-end against a live AX
  tree.
