// @cobd/bluefin -- the macOS accessibility framework
// interface used by the Albacore cross-platform screen
// reader. Bundles seven subsystems behind a single
// barrel:
//
//   Accessibility -- AX* tree access (process trust,
//                    attribute / action APIs over
//                    NSAccessibility)
//   Elements      -- UIElement + UIApp wrappers --
//                    typed objects on top of the AX
//                    tree
//   Events        -- shared event bus (SeaBus); the
//                    'all' channel sees every emit
//   Security      -- macOS keychain set/get
//   System        -- battery + frontmost-app probes,
//                    AppleScript runner, snapshots
//   ScreenReader  -- output sink (TTS/beep)
//   UI            -- UIManager + load entry point used
//                    by Tuna's renderer

export * as Accessibility from './Accessibility/index';
export * as Elements from './Elements/index';
export * as Events from './Events/index';
export * as Security from './Security/index';
export * as System from "./System/index";
export * as ScreenReader from "./ScreenReader/index";
export * as UI from './UI/index';

