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

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }

    @IBAction func didTapOK(_ sender: NSButton) {
        let token = textField.stringValue
        UserDefaults.standard.set(token, forKey: "GCPAccessKey")
        self.close()
    }


    var initialized: Bool = false
}

extension MainWindow:  NSWindowDelegate {
    func windowDidChangeOcclusionState(_ notification: Notification) {
        guard initialized == false else { return }

        if let key = UserDefaults.standard.string(forKey: "GCPAccessKey") {
//            close()
            textField.stringValue = key
            let cv = CloudVision(accessKey: key)
            cv.run { result in
                switch result {
                case .success(let text):
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = text
                        alert.beginSheetModal(for: self, completionHandler: nil)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        print(error)
                        print(error.localizedDescription)
                        let alert = NSAlert(error: error)
                        alert.beginSheetModal(for: self, completionHandler: nil)
                    }
                }

            }
        } else {

        }

        initialized = true
    }
}
