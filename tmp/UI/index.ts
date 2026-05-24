// UI -- bluefin's renderer-side glue. UI.load() is
// the boot call from Tuna's index.ts; getManager()
// returns the singleton UIManager that owns the
// active UIApp + dispatches AX events into the
// Events bus.

export * from './getManager';
export * from './load';

