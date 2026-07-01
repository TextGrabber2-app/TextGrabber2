//
//  App+Menu.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

// MARK: - Menu

extension App {
  func statusItemClicked() {
    // Hide the user guide after the user becomes familiar
    if userClickCount > 4 && !NSPasteboard.general.hasLimitedAccess {
      howToItem.isHidden = true
    }

    // Rely on this instead of mutating items in menuWillOpen
    isMenuVisible = true
    Task {
      await startDetection(userInitiated: true)
    }
  }

  func clearMenuItems() {
    hintItem.title = NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHintLimitedAccess : Localized.menuTitleHintCopyToGetStarted
    mainMenu.removeItems {
      $0 is ResultItem
    }
  }

  func presentMainMenu() {
    let location: CGPoint = {
      if #available(macOS 26.0, *) {
        return CGPoint(x: -8, y: 0)
      }

      return CGPoint(x: -8, y: (statusItem.button?.frame.height ?? 0) + 4)
    }()

    mainMenu.appearance = NSApp.effectiveAppearance
    mainMenu.popUp(positioning: nil, at: location, in: statusItem.button)
  }

  func showAppUpdate(name: String, url: String) {
    appVersionItem.title = String(format: Localized.menuTitleNewVersionOut, name)
    appVersionItem.toolTip = url

    appVersionItem.addAction(Keys.appVersionAction) { [weak self] in
      NSWorkspace.shared.safelyOpenURL(string: url)
      self?.appVersionItem.title = Bundle.main.humanReadableVersion
    }
  }
}

// MARK: - NSMenuDelegate

extension App: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    guard menu == mainMenu else {
      return
    }

    if KeyBindings.items.hasValue {
      menu.enumerateDescendants { item in
        if let keyBinding = (KeyBindings.items.first { $0.actionName == item.title }) {
          item.setKeyBinding(with: keyBinding)
        }
      }
    }

    if URL.clipboardInspectorURL.pathExtension == "app" {
      clipboardInspectorItem.title = Localized.menuTitleInspectClipboard
    } else {
      clipboardInspectorItem.title = Localized.menuTitleGetInspector
    }
  }

  func menuWillOpen(_ menu: NSMenu) {
    guard menu == servicesItem.submenu else {
      return
    }

    // Host the text so NSApp.servicesMenu can be populated
    servicesHost.activate(text: currentResult?.spacesJoined ?? "")
  }

  func menuDidClose(_ menu: NSMenu) {
    if menu == mainMenu {
      isMenuVisible = false
    }

    // Tear down on any menu close; menuDidClose isn't reliable for the submenu
    // (see the outside-click fallback in addEventMonitors), and this is a no-op
    // unless the host is active
    Task {
      if let updatedText = await servicesHost.scheduleTeardown() {
        NSPasteboard.general.string = updatedText
      }
    }
  }
}
