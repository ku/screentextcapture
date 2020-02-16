//
//  KeyStore.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import KeychainSwift

class KeyStore {
    let keyName = "GCPAccessKey"
    func get() -> String? {
        return KeychainSwift().get(keyName)
    }

    func set(text: String) {
        KeychainSwift().set(text, forKey: keyName)
    }
}
