# tmp/

Pre-consolidation TypeScript code from the legacy
`bluefin` repo, preserved here for later salvage.
Each subfolder maps to a module from the old TS
implementation:

- `Accessibility_*.ts` -- legacy AX wrappers. Some
  motivate new protocol methods (`getAPIEnabled` ->
  `system.isAccessibilityEnabled`,
  `getAttributesForElement` -> `node.getAttributeNames`).
- `Elements/` -- ported to `@cobd/sandbucket`; the
  originals are kept here as the reference for the
  navigation contract.
- `Events/` -- the `onAny` wildcard pattern landed
  in `@cobd/sandcastle`; SeaBus itself is here for
  reference.
- `Security/` -- keychain read/write; planned as
  `security.getKeychainItem` /
  `security.setKeychainItem` protocol methods.
- `System/` -- battery / AppleScript runner;
  planned as `system.getBatteryStatus`,
  `system.runAppleScript`, etc.
- `UI/` -- legacy `UIManager` (renderer-side state
  machine). Will likely be rewritten when
  `@cobd/core` reaches that scope.

Nothing in `tmp/` is built, exported, or linked.
Bring files out as needed; delete the folder once
nothing remains useful.
