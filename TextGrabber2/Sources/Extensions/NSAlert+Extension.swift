//
//  NSAlert+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/5/1.
//

import AppKit

extension NSAlert {
  static func runModal(message: String, style: Style = .critical) {
    NSApp.tryToActivate()

    let alert = Self()
    alert.alertStyle = style
    alert.messageText = message
    alert.runModal()
  }
}
