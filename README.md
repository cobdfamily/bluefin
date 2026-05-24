# bluefin

Home of the macOS Bluefin AX server and the related
Swift bridges (taylor, bluetide) that make up the
darwin half of the Albacore cross-platform screen
reader. Consolidated from the previously separate
`bluefin` (TS), `bluefin-swift`, `taylor`, and
`bluetide` repositories; full git history of each
is preserved here via subtree merges.

## Layout

```
swift/      The bluefin AX server -- Swift Package
            with stdio JSON-RPC over the Bluefin
            protocol. This is the binary that
            @cobd/sandcastle spawns on macOS hosts.
            See swift/PROTOCOL.md for the wire
            contract.

taylor/     Swift <-> Node bridge (legacy). Kept
            for reference and for any helpers we
            decide to fold into the Bluefin
            protocol.

bluetide/   Per-app AXObserver pattern (legacy).
            Reference for the focus-change event
            stream the server now emits over the
            wire.

tmp/        Unported TypeScript from the original
            bluefin repo, parked for later salvage.
            See tmp/README.md for what lives where.
```

## Cross-repo

- Albacore monorepo: <https://github.com/cobdfamily/albacore>
- Sandcastle (the launcher that spawns this binary):
  <https://github.com/cobdfamily/albacore/tree/main/packages/sandcastle>

## Recently-added protocol methods

The following methods round out the protocol surface
inherited from the bluefin TS legacy and landed
during the consolidation:

- `system.isAccessibilityEnabled` -- runtime AX
  permission check.
- `node.getAttributeNames` -- enumerate the raw AX
  attribute names supported by an element.
- `security.getKeychainItem` /
  `security.setKeychainItem` -- macOS keychain
  read/write.
- `system.getBatteryStatus` -- battery percentage,
  charging state, and presence.
- `system.runAppleScript` -- NSAppleScript runner;
  errors surface in-band.

See `swift/PROTOCOL.md` for the full method shapes.
The TS originals that motivated each of these live
under `tmp/`.

## License

AGPL-3.0 -- see `LICENSE`.
