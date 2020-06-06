//
//  KeyStore.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import Foundation
import KeychainSwift
import AppAuth

class KeyStore {
    enum Property: String {
        case authState
        case rawAccessToken
    }

    func getRawToken() -> String? {
        return KeychainSwift().get(Property.rawAccessToken.rawValue)
    }
    func saveRawToken(_ token: String) {
        KeychainSwift().set(token, forKey: Property.rawAccessToken.rawValue)
    }

    func getAuthState() -> OIDAuthState? {
        guard let data = KeychainSwift().getData(Property.authState.rawValue) else { return nil }

        do {
            let object = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
            guard let state = object as? OIDAuthState else { return nil }
            return state
        } catch {
            print(error)
            return nil
        }
    }

    func saveAuthState(_ state: OIDAuthState) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: true)
            KeychainSwift().set(data, forKey: Property.authState.rawValue)
        } catch {
            print(error)
        }
    }
}
