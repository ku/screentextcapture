//
//  Annotator.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import AppKit

class Annotator {
    static let apiErrorNotificationId = "apiErrorNotificationId"

    let terminateOnCopy: Bool
    init(terminateOnCopy: Bool = true) {
        self.terminateOnCopy = terminateOnCopy
    }

    func capture() {
        ScreenCapture().capture { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let file):
                self.annotate(file: file)
            case .failure(let error):
                if let error = error as? ApplicationError,
                    error == .cancelled {
                    self.exit()
                } else {
                    self.notify(error: error, id: UUID().uuidString)
                }
            }
        }
    }
    private func annotate(file: URL) {
        guard let accessKey = KeyStore().get() else { return }
        CloudVision(accessKey: accessKey).annotate(file: file, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let text):
                self.copy(text)
                self.notify(text: "Captured successfully")
                if self.terminateOnCopy {
                    self.exit()
                }
            case .failure(let error):
                self.notify(error: error, id: Annotator.apiErrorNotificationId)
            }
        })
    }

    private func notify(error: Error, id: String) {
        let notification = NSUserNotification()
        notification.identifier = UUID().uuidString
        notification.title = "ScreenTextCapture"
        notification.informativeText = error.localizedDescription
        notification.soundName = "Sosumi"
        notification.hasActionButton = true
        notification.actionButtonTitle = "設定"
        notification.hasActionButton = true
        notification.otherButtonTitle = "Close"
        notification.actionButtonTitle = "Show"
        //        notification.contentImage = NSImage(contentsOfURL: NSURL(string: "https://placehold.it/300")!)
        NSUserNotificationCenter.default.deliver(notification)
    }

    private func notify(text: String, id: String = UUID().uuidString) {
        let notification = NSUserNotification()
        notification.identifier = id
        notification.title = "ScreenTextCapture"
        notification.informativeText = text
        notification.soundName = NSUserNotificationDefaultSoundName
//        notification.contentImage = NSImage(contentsOfURL: NSURL(string: "https://placehold.it/300")!)
        NSUserNotificationCenter.default.deliver(notification)
    }

    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(text, forType: NSPasteboard.PasteboardType.string)
    }

    private func exit() {
        DispatchQueue.main.async {
            NSApp.self?.terminate(nil)
        }
    }
}
