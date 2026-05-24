// Elements -- typed wrappers over the AX tree.
// UIElement is the node type (parent / firstChild /
// nextSibling / focus / aria-label + role compute);
// UIApp is the root for a single application's tree
// (commonly constructed as `new UIApp('active')` to
// attach to whatever currently owns focus).

export * from './UIElement';
export * from './UIApp';

