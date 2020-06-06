//
//  AppDelegate.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import Cocoa

enum ApplicationError: Error {
    case cancelled
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var annotator: Annotator?
    var accessTokenStore: AccessTokenStore?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        NSApp.self.hide(nil)

        NSUserNotificationCenter.default.delegate = self

        let accessTokenStore = AccessTokenStore()
        accessTokenStore.perform(action: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let token):
                let annotator = Annotator(accessToken: token)
                annotator.capture()
                strongSelf.annotator = annotator
            case .failure(let error):
                strongSelf.show(error: error)
            }
        })
        self.accessTokenStore = accessTokenStore
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction private func preferences(_ sender: Any) {
        exitTimer?.invalidate()
        show(error: nil)
    }

    private func show(error: Error?) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let mainWC = storyboard.instantiateController(withIdentifier: "MainWindowController") as? NSWindowController else {
            fatalError("Error getting main window controller")
        }
        mainWC.window?.makeKeyAndOrderFront(nil)
    }

    private var exitTimer: Timer?

    func startExitTimer() {
        exitTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { _ in
            NSApp.self?.terminate(nil)
        })
    }
}
extension AppDelegate: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}
