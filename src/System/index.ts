// System -- miscellaneous macOS probes that don't
// fit Accessibility / Elements. Battery (percentage,
// charging state, structured snapshot), frontmost-app
// pid, and a raw AppleScript runner. The AppleScript
// runner bypasses osascript -- it goes through
// NSAppleScript directly so prompts and entitlements
// are owned by the host process.

export * from './getBatteryPercentage';
export * from './getBatteryStatus';
export * from './getIdOfFrontmostApp';
export * from './getIsCharging';
export * from './runAppleScript';
