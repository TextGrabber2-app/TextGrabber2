//
//  App+KeyBindings.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

// MARK: - Key Bindings

extension App {
  func registerKeyBindings() {
    for item in KeyBindings.items {
      HotKeys.register(keyEquivalent: item.key, modifiers: item.modifiers) { [weak self] in
        let actionName = item.actionName
        let opensApp = actionName == "TextGrabber2" // Special handling

        if opensApp {
          self?.statusItemClicked()
        } else if let action = self?.mainMenu.firstActionNamed(actionName) {
          Task {
            await self?.startDetection()
            action.performAction()
          }
        } else {
          Logger.log(.error, "Invalid keybinding: \(item)")
        }
      }
    }
  }

  func unregisterKeyBindings() {
    HotKeys.unregisterAll()
  }
}
