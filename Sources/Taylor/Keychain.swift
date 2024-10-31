import Foundation
import Security

/// Saves an item to the macOS Keychain.
/// - Parameters:
///   - service: The name of the service (e.g., "MyApp").
///   - account: The account name (e.g., "user@example.com").
///   - password: The password or secret to save.
/// - Returns: A Bool indicating success or failure.
func setKeychainItem(service: String, account: String, password: String) -> Bool {
    // Convert the password to Data
    guard let passwordData = password.data(using: .utf8) else {
        print("Failed to convert password to Data")
        return false
    }

    // Define the keychain query
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecValueData as String: passwordData
    ]

    // Delete any existing item with the same service and account
    SecItemDelete(query as CFDictionary)

    // Add the new item to the keychain
    let status = SecItemAdd(query as CFDictionary, nil)

    // Check the result
    if status == errSecSuccess {
        print("Password saved successfully.")
        return true
    } else {
        print("Error saving password: \(status)")
        return false
    }
}

/// Retrieves an item from the macOS Keychain.
/// - Parameters:
///   - service: The name of the service (e.g., "MyApp").
///   - account: The account name (e.g., "user@example.com").
///   - password: An inout parameter to store the retrieved password if successful.
/// - Returns: A Bool indicating success or failure.
func getKeychainItem(service: String, account: String) -> String? {
    // Define the keychain query
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    // Variable to store the retrieved data
    var item: CFTypeRef?

    // Attempt to retrieve the item
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    // Check the result
    if status == errSecSuccess {
        if let data = item as? Data,
           let retrievedPassword = String(data: data, encoding: .utf8) {
            print("Password retrieved successfully.")
            return retrievedPassword
        } else {
            print("Failed to convert retrieved data to String.")
            return nil
        }
    } else {
        print("Error retrieving password: \(status)")
        return nil
    }
}
