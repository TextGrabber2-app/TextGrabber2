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

  func ensureImageVisibility() {
    guard #available(macOS 27.0, *) else {
      return
    }

  #if canImport(FoundationModels, _version: 2)
    preferredImageVisibility = .visible
  #else
    let selector = sel_getUid("setPreferredImageVisibility:")
    if responds(to: selector) {
      unsafeBitCast(
        method(for: selector),
        to: (@convention(c) (NSMenuItem, Selector, Int) -> Void).self
      )(self, selector, 1) // .visible
    } else {
      assertionFailure("Missing setPreferredImageVisibility:")
    }
  #endif
  }

  @MainActor
  func performAction() {
    guard let action else {
      return
    }

    NSApp.sendAction(action, to: target, from: self)
  }
}
