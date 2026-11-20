import Foundation
import Security
import Observation
import UserNotifications

/// Вход по коду + постоянная сессия (токен в Keychain).
/// ДЕМО: реальной отправки письма нет, принимается любой 8-значный код.
/// Когда появится сервер, заменить тело sendCode/verify на запросы к нему.
@MainActor @Observable
final class AuthManager {
    private(set) var isLoggedIn: Bool
    private let tokenKey = "auth_token"

    init() {
        isLoggedIn = Keychain.read("auth_token") != nil
    }

    func sendCode(to email: String) async {
        try? await Task.sleep(for: .milliseconds(600))
    }

    func verify(code: String, email: String) async -> Bool {
        try? await Task.sleep(for: .milliseconds(600))
        guard code.count == 8, code.allSatisfy(\.isNumber) else { return false }
        Keychain.save(UUID().uuidString, for: tokenKey)
        UserDefaults.standard.set(email, forKey: "userEmail")
        isLoggedIn = true
        return true
    }

    func signOut() {
        Keychain.delete(tokenKey)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        WidgetSync.clear()
        isLoggedIn = false
    }
}

enum Keychain {
    static func save(_ value: String, for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(add as CFDictionary, nil)
    }

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
