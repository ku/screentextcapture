//
//  Preferenes.swift
//  screentextcapture
//
//  Created by ku on 2020/02/19.
//  Copyright © 2020 ku. All rights reserved.
//

import Foundation

class Preferences {

    var notifyWhenDone: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: #function)
        }
        get {
            return UserDefaults.standard.bool(forKey: #function)
        }

    }
}
