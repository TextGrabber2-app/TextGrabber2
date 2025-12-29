//
//  NSMenuItem+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

extension NSMenuItem {
  convenience init(title: String) {
    self.init(title: title, action: nil, keyEquivalent: "")
  }

  func setOn(_ on: Bool) {
    state = on ? .on : .off
  }

  func toggle() {
    state = state == .on ? .off : .on
  }

  @MainActor
  func performAction() {
    guard let action else {
      return
    }

    NSApp.sendAction(action, to: target, from: self)
  }
}
