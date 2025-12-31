//
//  App+MenuItems.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

// MARK: - Menu Items

extension App {
  func showAppUpdate(name: String, url: String) {
    appVersionItem.title = String(format: Localized.menuTitleNewVersionOut, name)
    appVersionItem.toolTip = url

    appVersionItem.addAction(Keys.appVersionAction) { [weak self] in
      NSWorkspace.shared.safelyOpenURL(string: url)
      self?.appVersionItem.title = Bundle.main.humanReadableVersion
    }
  }

  func clearMenuItems() {
    hintItem.title = NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHintLimitedAccess : Localized.menuTitleHintCapture
    mainMenu.removeItems { $0 is ResultItem }
  }
}
