//
//  NSApplication+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/5/1.
//

import AppKit

extension NSApplication {
  func tryToActivate() {
    if #available(macOS 14.0, *) {
      activate()
    } else {
      activate(ignoringOtherApps: true)
    }
  }
}
