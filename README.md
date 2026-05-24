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

## Planned protocol additions

Documented but not yet implemented in `swift/`. Each
gets a method when its consumer lands:

- `system.isAccessibilityEnabled` -- runtime check
  for AX permission. Replaces the startup-only
  stderr log.
- `node.getAttributeNames` -- enumerate the raw AX
  attribute names supported by an element.
- `security.getKeychainItem` /
  `security.setKeychainItem` -- macOS keychain
  read/write.
- `system.getBatteryStatus` -- battery
  percentage + charging state.
- `system.runAppleScript` -- AppleScript runner
  without shelling out to `osascript`.

The TS originals for each of these live under `tmp/`.

## License

AGPL-3.0 -- see `LICENSE`.
