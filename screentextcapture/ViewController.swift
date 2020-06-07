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
    @IBOutlet private var signInWithGoogleButton: NSButton!

    @IBOutlet private var accountTypeOAuthButton: NSButton!
    @IBOutlet private var accountTypeAccessTokenButton: NSButton!

    private var tokenStore = AccessTokenStore()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(fieldTextDidChange), name: NSNotification.Name(rawValue: "NSTextDidChangeNotification"), object: nil)

        setupUI()

        tokenStore.perform(action: { result in
            switch result {
            case .success:
                


//                NSRunningApplication.current.activate(options: .init(arrayLiteral: .activateAllWindows, .activateIgnoringOtherApps))
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

    @IBAction private func didTapSignInWithGoogle(sender: Any) {


//        tokenStore.perform(action: <#T##(Result<AccessTokenStore.AccessToken, Error>) -> Void#>)
    }

    @IBAction private func didTapHelp(sender: Any) {
        guard let url = URL(string: "https://cloud.google.com/vision/docs/auth") else { return }
        NSWorkspace.shared.open(url)
    }

    @IBAction private func radioButtonDidTap(sender: NSButton) {
        if sender == accountTypeOAuthButton {
            updateRadioButtonStatus(accountType: .oAuth)
            tokenStore.accountType = .oAuth
        } else if sender == accountTypeAccessTokenButton {
            updateRadioButtonStatus(accountType: .rawToken)
            tokenStore.accountType = .rawToken
        }
    }

    private func setupUI() {
        let image = NSImage(imageLiteralResourceName: "btn_google_light_normal_ios")
        image.capInsets = .init(top: 4, left: 34, bottom: 4, right: 4)
        signInWithGoogleButton.image = image
        signInWithGoogleButton.imageScaling = .scaleAxesIndependently
        updateRadioButtonStatus(accountType: tokenStore.accountType)
    }

    private func updateRadioButtonStatus(accountType: AccessTokenStore.AccountType) {
        switch accountType {
        case .oAuth:
            accountTypeOAuthButton.state = .on
            accountTypeAccessTokenButton.state = .off
        case .rawToken:
            accountTypeOAuthButton.state = .off
            accountTypeAccessTokenButton.state = .on
        }
    }
}
