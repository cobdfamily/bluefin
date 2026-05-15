// Accessibility -- thin TypeScript wrappers over
// macOS NSAccessibility. Process-trust check (a11y
// permission gate), attribute getters / setters on a
// UIElement, frontmost / system-app lookups, and the
// performAction surface. Camel-case helpers live here
// because AX attribute names round-trip through both
// representations.

export * from './GetIsProcessTrusted';
export * from './getAPIEnabled';
export * from './getAttributeForElementByName';
export * from './getAttributesForElement';
export * from './getAttributesForElementWithFilter';
export * from './getCamelCase';
export * from './getFrontmostApp';
export * from './getSystemApp';
export * from './getUpperCamelCase';
export * from './performActionForElement';
export * from './setFocusedUIElement';

