//
//  MainWindow.swift
//  gyat
//
//  Created by ku on 2020/01/10.
//  Copyright © 2020 ku KUMAGAI Kentaro. All rights reserved.
//

import AppKit


class MainWindow: NSWindow {
    @IBOutlet private var textField: NSTextField!


    @IBAction func didTapOK(_ sender: NSButton) {
        let token = textField.stringValue
        UserDefaults.standard.set(token, forKey: "GCPAccessKey")
        self.close()
    }
}

extension MainWindow:  NSWindowDelegate {
    func windowDidChangeOcclusionState(_ notification: Notification) {

        if let key = UserDefaults.standard.string(forKey: "GCPAccessKey") {
//            close()
            textField.stringValue = key
            let cv = CloudVision(accessKey: key)
            cv.run()
        } else {

        }
    }
}
