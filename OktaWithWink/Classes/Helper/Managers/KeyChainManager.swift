//
//  KeyChainManager.swift
//  WinkApp
//
//  Created by MacBook on 02/01/25.
//

import Foundation
import Security

class KeychainManager {
    
    static let shared = KeychainManager()
    
    private init() {}
    
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
    }
    
    // App Group Identifier (Replace with your app's App Group identifier)
    private let appGroupIdentifier = "group.Wink.native.SSO"
    
    // Keychain query key for shared access
    private func getSharedQuery(forKey key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: appGroupIdentifier  // Shared keychain access group
        ]
    }
    
    // Save data to Keychain with shared access
    func save(key: String, value: String) -> Bool {
        guard let valueData = value.data(using: .utf8) else {
            print("Failed to convert value to data.")
            return false
        }
        
        var query = getSharedQuery(forKey: key)
        query[kSecValueData as String] = valueData
        
        // Delete any existing items with the same key
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("Successfully saved \(key) to Keychain.")
            return true
        } else {
            print("Keychain save error: \(status)")
            return false
        }
    }
    
    // Retrieve data from Keychain with shared access
    func retrieve(key: String) -> String? {
        var query = getSharedQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue!
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data, let value = String(data: data, encoding: .utf8) {
                print("Successfully retrieved value from Keychain for key \(key): \(value)")
                return value
            } else {
                print("Failed to convert data to string.")
            }
        } else {
            print("Keychain retrieve error: \(status), Item not found for key: \(key)")
        }
        
        return nil
    }
    
    // Delete data from Keychain with shared access
    func delete(key: String) -> Bool {
        var query = getSharedQuery(forKey: key)
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("Successfully deleted \(key) from Keychain.")
            return true
        } else {
            print("Keychain delete error: \(status)")
            return false
        }
    }
    
    // Clear all Keychain data with shared access
    func clearAllKeychainData() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: appGroupIdentifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess
    }
    
    // Save Token with shared access
    func saveToken(_ token: String, forKey key: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.unknown(errSecParam)
        }
        
        var query = getSharedQuery(forKey: key)
        
        // Check if the item already exists
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // If item exists, update it
            let updateQuery: [String: Any] = [kSecValueData as String: data]
            status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
            
            guard status == errSecSuccess else {
                throw KeychainError.unknown(status)
            }
        } else if status == errSecItemNotFound {
            // If the item doesn't exist, add it
            query[kSecValueData as String] = data
            status = SecItemAdd(query as CFDictionary, nil)
            
            guard status == errSecSuccess else {
                throw KeychainError.unknown(status)
            }
        } else {
            throw KeychainError.unknown(status)
        }
    }
    
    // Get Token with shared access
    func getToken(forKey key: String) -> String? {
        var query = getSharedQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue!
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func checkAndAddValueIfKeyDoesNotExist(key: String, value: String) -> Bool {
        print("Checking if key exists for key: \(key)")
        
        if let existingValue = retrieve(key: key) {
            print("Key already exists with value: \(existingValue)")
            return false // No need to save if the key already exists
        }
        
        print("Key does not exist. Saving new value for key: \(key)")
        return save(key: key, value: value)
    }
    
    func clearToken(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // Save a Bool value to Keychain
    func saveBool(key: String, value: Bool){
        let valueData = Data([value ? 1 : 0])
        
        var query = getSharedQuery(forKey: key)
        query[kSecValueData as String] = valueData
        
        // Delete any existing items with the same key
        SecItemDelete(query as CFDictionary)
        
        _ = SecItemAdd(query as CFDictionary, nil)
        
    }
    
    // Retrieve a Bool value from Keychain
    func retrieveBool(key: String) -> Bool? {
        var query = getSharedQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue!
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data, let value = data.first {
            return value == 1
        }
        
        return nil
    }
}
