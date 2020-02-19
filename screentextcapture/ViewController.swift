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
    @IBOutlet private var accessTokenTextField: NSTextField!
    @IBOutlet private var notifyWhenDoneButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let accessToken = KeyStore().get() {
            accessTokenTextField.stringValue = accessToken
        }

        NotificationCenter.default.addObserver(self, selector: #selector(fieldTextDidChange), name: NSNotification.Name(rawValue: "NSTextDidChangeNotification"), object: nil)
    }

    override func viewDidAppear() {
        guard ScreenCapturePermissionManager().verify() else { return }
    }

    override func viewDidDisappear() {
        NSApp.self?.terminate(nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }



    @objc private func fieldTextDidChange(notification: NSNotification) {
        let token = accessTokenTextField.stringValue
        KeyStore().set(text: token)
    }
    @IBAction private func toggleCheckbox(sender: NSButton) {
        Preferences().notifyWhenDone = (sender.state == .on)
    }

    @IBAction private func didTapHelp(sender: Any) {
        guard let url = URL(string: "https://cloud.google.com/vision/docs/auth") else { return }
        NSWorkspace.shared.open(url)
    }
}
