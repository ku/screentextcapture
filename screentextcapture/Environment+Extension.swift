//
//  Environment+Extension.swift
//  screentextcapture
//
//  Created by ku on 2020/09/15.
//  Copyright © 2020 ku. All rights reserved.
//

extension Environment {
    enum Mode {
        case oauth
        case embedded
    }
    
    static var mode: Mode {
        if Environment.clientId.isEmpty {
            return .embedded
        } else {
            return .oauth
        }
    }
}
