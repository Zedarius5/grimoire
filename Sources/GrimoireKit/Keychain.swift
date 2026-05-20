import Foundation
import Security

/// Thin wrapper over the macOS Keychain for storing the user's Simu password.
/// Keys are scoped by service + account so we can hold separate entries per
/// game account.
public enum Keychain {

    public static let service = "com.zedarius.Grimoire"

    public static func save(password: String, account: String) {
        guard let data = password.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary) // replace if present
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    public static func loadPassword(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let pwd  = String(data: data, encoding: .utf8) else {
            return nil
        }
        return pwd
    }

    public static func deletePassword(account: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
