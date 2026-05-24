# Gratitude

bluefin-swift sits on Apple's accessibility
stack. The framework is small because those
foundations are deep. With gratitude to:

## Apple's accessibility team

The macOS Accessibility (AX) framework is what
this server reads from. Decades of patient
engineering on AXUIElement, AXObserver, and the
attribute / action vocabulary make a project like
this possible at all. Particular thanks for the
public C API surface in ApplicationServices.

## bluetide

The hybrid Node + Swift project that inspired the
ecosystem layout. bluefin-swift is a separate
process now, but the patterns for how Swift talks
to the AX tree come from there.

## taylor

The Swift bridge that the original (in-process)
bluefin TypeScript client used. The mapping of
AX names to JS-readable values learned a lot from
that codebase.

## The Bluefin protocol consumers (future)

yellowfin (Linux AT-SPI) and blackfin (Windows UIA)
will be built against the same PROTOCOL.md draft
that lives in this repo. The protocol is shaped by
what those platforms need to look identical to JS,
not just what AX needs. Thanks in advance to
whoever implements them.

## Albacore

The cross-platform screen reader that all this
exists to serve.
