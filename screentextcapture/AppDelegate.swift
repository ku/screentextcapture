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
    let annotator: Annotator = Annotator()
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        NSApp.self.hide(nil)

        NSUserNotificationCenter.default.delegate = self

        if let _ = KeyStore().get() {
            annotator.capture()
        } else {
            show()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


    @IBAction private func preferences(_ sender: Any) {
        exitTimer?.invalidate()
        show()
    }

    private func show() {
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
