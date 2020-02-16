//
//  ScreenCapturePermissionManager.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import AVFoundation
import AppKit

class ScreenCapturePermissionManager {

    private var canRecordScreen : Bool {
      guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] else { return false }
      return windows.allSatisfy({ window in
          let windowName = window[kCGWindowName as String] as? String
          let isSharingEnabled = window[kCGWindowSharingState as String] as? Int
          return windowName != nil || isSharingEnabled == 1
      })
    }

    func verify() -> Bool {
        if canRecordScreen {
            return true
        }

        let session = AVCaptureSession()

        session.sessionPreset = AVCaptureSession.Preset.high

        let mainDisplay = CGMainDisplayID()

        guard let input = AVCaptureScreenInput(displayID: mainDisplay) else { return  false }
//        guard let frame = NSScreen.main?.frame else { return }
        input.cropRect = .zero
        input.minFrameDuration = CMTimeMake(value: 1, timescale: 10)
        let output = AVCaptureVideoDataOutput()

        guard session.canAddInput(input),
            session.canAddOutput(output) else { return false }
        session.addInput(input)
        session.addOutput(output)

        session.startRunning()

        return false
    }
}
