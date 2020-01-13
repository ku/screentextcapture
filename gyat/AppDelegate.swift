//
//  AppDelegate.swift
//  gyat
//
//  Created by ku KUMAGAI Kentaro on 2019/03/23.
//  Copyright © 2019 ku KUMAGAI Kentaro. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let window = window as? MainWindow else { return }
        window.delegate = window
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        NSApp.terminate(nil)
    }
}
