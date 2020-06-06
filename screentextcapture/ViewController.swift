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

    private var tokenStore = AccessTokenStore()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(fieldTextDidChange), name: NSNotification.Name(rawValue: "NSTextDidChangeNotification"), object: nil)

        tokenStore.perform(action: { result in
            switch result {
            case .success:
                NSRunningApplication.current.activate(options: .init(arrayLiteral: .activateAllWindows, .activateIgnoringOtherApps))
            case .failure(let error):
                // show alert
                print(error)
            }
        })
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
    }
    
    @IBAction private func toggleCheckbox(sender: NSButton) {
        Preferences().notifyWhenDone = (sender.state == .on)
    }

    @IBAction private func didTapHelp(sender: Any) {

        //        NSWorkspace.shared.open(url)
    }
}
