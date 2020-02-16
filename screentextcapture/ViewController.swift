//
//  ViewController.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet private var helpLabel: NSTextField!
    @IBOutlet private var textField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(fieldTextDidChange), name: NSNotification.Name(rawValue: "NSTextDidChangeNotification"), object: nil)
    }

    override func viewDidAppear() {

        guard ScreenCapturePermissionManager().verify() else { return }

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @objc private func fieldTextDidChange(notification: NSNotification) {
        let token = textField.stringValue
        KeyStore().set(text: token)
    }

}
