//
//  KeyChainManager.swift
//  Group
//
//  Created by CatSlave on 7/26/24.
//

import Foundation
import Security

protocol KeyChainService {
    func saveToken(_ token: Data)
    func getToken() -> TokenInfo?
    func deleteToken()
    func hasToken() -> Bool
}

class TokenKeyChain: KeyChainService {
    enum Key: String {
        case service = "com.Side.GroupManager"
        case account = "userToken"
    }
    
    private let service = "com.yourapp.tokens"
    
    private let account = "userTokens"

    func saveToken(_ tokens: Data) {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Key.service.rawValue,
            kSecAttrAccount as String: Key.account.rawValue,
            kSecValueData as String: tokens
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        #if DEBUG
        if status == errSecSuccess {
            print("Tokens saved successfully")
        } else {
            print("Tokens Failed to save tokens: \(status)")
        }
        #endif
    }
    
    func getToken() -> TokenInfo? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Key.service.rawValue,
            kSecAttrAccount as String: Key.account.rawValue,
            kSecReturnData as String: true  // 데이터 반환 요청
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let tokens = try? JSONDecoder().decode(TokenInfo.self, from: data) else {
            print("Tokens Failed to retrieve tokens: \(status)")
            return nil
        }
        
        print("Tokens retrieved successfully")
        return tokens
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Key.service.rawValue,
            kSecAttrAccount as String: Key.account.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            print("Tokens deleted successfully")
        } else {
            print("Tokens Failed to delete tokens: \(status)")
        }
    }

    func hasToken() -> Bool {
        return getToken() != nil
    }
}
