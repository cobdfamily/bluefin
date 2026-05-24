// Security -- macOS keychain helpers. get + set named
// items only; no enumeration or delete on purpose --
// Tuna doesn't need them and the smaller surface keeps
// the bluefin-keychain interaction safe + obvious.

export * from './getKeychainItem';
export * from './setKeychainItem';

