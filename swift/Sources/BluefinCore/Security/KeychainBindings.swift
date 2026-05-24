import Foundation
import Security

public enum KeychainBindings {
    public static func getGenericPassword(service: String, account: String) throws -> String? {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw BluefinError.internalError("SecItemCopyMatching failed: \(status)")
        }
        guard let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw BluefinError.internalError("Keychain item value is not valid UTF-8")
        }
        return value
    }

    public static func setGenericPassword(service: String, account: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw BluefinError.invalidParams
        }

        let query = baseQuery(service: service, account: account)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let attributes = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw BluefinError.internalError("SecItemUpdate failed: \(updateStatus)")
            }
            return
        }
        guard status == errSecItemNotFound else {
            throw BluefinError.internalError("SecItemCopyMatching failed: \(status)")
        }

        var item = query
        item[kSecValueData as String] = data
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw BluefinError.internalError("SecItemAdd failed: \(addStatus)")
        }
    }

    private static func baseQuery(service: String, account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
