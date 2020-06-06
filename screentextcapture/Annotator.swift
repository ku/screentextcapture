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
    
    private let accessToken: String
    private let terminateOnCopy: Bool
    init(accessToken: String, terminateOnCopy: Bool = true) {
        self.accessToken = accessToken
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
                    DispatchQueue.main.async {
                        guard let appDelegate = NSApp.self?.delegate as? AppDelegate else {
                            self.exit()
                            return
                        }
                        appDelegate.startExitTimer()
                    }
                } else {
                    self.notify(error: error, id: UUID().uuidString)
                }
            }
        }
    }
    private func annotate(file: URL) {
        CloudVision(accessToken: accessToken).annotate(file: file, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let text):
                self.extracted(text: text)
            case .failure(let error):
                self.notify(error: error, id: Annotator.apiErrorNotificationId)
            }
        })
    }

    private func extracted(text: String) {
        copy(text)
        if Preferences().notifyWhenDone {
            notify(text: text)
        }
        if terminateOnCopy {
            exit()
        }
    }

    private func notify(error: Error, id: String) {
        let notification = NSUserNotification()
        notification.identifier = UUID().uuidString
        notification.title = "ScreenTextCapture"
        notification.informativeText = error.localizedDescription
        notification.soundName = "Sosumi"
        notification.actionButtonTitle = "Preferences"
        notification.hasActionButton = true
        notification.otherButtonTitle = "Close"
        notification.actionButtonTitle = "Show"
        NSUserNotificationCenter.default.deliver(notification)
    }

    private func notify(text: String, id: String = UUID().uuidString) {
        let notification = NSUserNotification()
        notification.identifier = id
        notification.title = "ScreenTextCapture"
        notification.informativeText = text
        notification.soundName = NSUserNotificationDefaultSoundName
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
