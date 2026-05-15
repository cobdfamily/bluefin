// ScreenReader -- output sink for whatever the
// renderer wants the user to hear. setOutput accepts
// either a text string (forwarded to TTS) or the
// sentinel 'beep' (boundary / no-content marker).
// getSnapshot captures the active app's a11y state
// for offline replay / debugging.

export * from './getSnapshot';
export * from './setOutput';
