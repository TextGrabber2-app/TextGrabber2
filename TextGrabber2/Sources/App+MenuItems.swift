//
//  App+MenuItems.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit
import ServiceManagement

// MARK: - Menu Items

extension App {
  var statusItem: NSStatusItem {
    if _statusItem == nil {
      let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
      item.behavior = .terminationOnRemoval
      item.autosaveName = Bundle.main.bundleName

      item.button?.image = .with(symbolName: Icons.textViewFinder, pointSize: 15)
      item.button?.setAccessibilityLabel("TextGrabber2")

      _statusItem = item
    }
    return _statusItem!
  }

  var mainMenu: NSMenu {
    if _mainMenu == nil {
      let menu = NSMenu()
      menu.delegate = self

      menu.addItem(hintItem)
      menu.addItem(howToItem)
      menu.addItem(.separator())
      menu.addItem(copyAllQuickItem)
      menu.addItem(.separator())
      menu.addItem(servicesItem)
      menu.addItem(clipboardItem)
      menu.addItem(.separator())
      menu.addItem(launchAtLoginItem)

      menu.addItem({
        let item = NSMenuItem(title: Localized.menuTitleGitHub)
        item.toolTip = Links.github
        item.addAction {
          NSWorkspace.shared.safelyOpenURL(string: Links.github)
        }

        return item
      }())

      menu.addItem(.separator())
      menu.addItem(appVersionItem)

      menu.addItem({
        let item = NSMenuItem(title: Localized.menuTitleQuitTextGrabber2, action: nil, keyEquivalent: "q")
        item.keyEquivalentModifierMask = .command
        item.addAction {
          NSApp.terminate(nil)
        }

        return item
      }())

      _mainMenu = menu
    }
    return _mainMenu!
  }

  var hintItem: NSMenuItem {
    if _hintItem == nil {
      let item = NSMenuItem()
      if NSPasteboard.general.hasLimitedAccess {
        item.image = NSImage(systemSymbolName: Icons.handRaisedSlash, accessibilityDescription: nil)
      }
      _hintItem = item
    }
    return _hintItem!
  }

  var howToItem: NSMenuItem {
    if _howToItem == nil {
      let item = NSMenuItem(title: NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHowToSetUp : Localized.menuTitleHowToCapture)
      item.addAction { [weak self] in
        let section = NSPasteboard.general.hasLimitedAccess ? "limited-access" : "capture-screen-on-mac"
        NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#\(section)")
        self?.increaseUserClickCount()
      }
      _howToItem = item
    }
    return _howToItem!
  }

  var copyAllQuickItem: NSMenuItem {
    if _copyAllQuickItem == nil {
      let item = NSMenuItem(title: Localized.menuTitleCopyAll)
      item.addAction {
        NSPasteboard.general.string = self.currentResult?.lineBreaksJoined
      }
      _copyAllQuickItem = item
    }
    return _copyAllQuickItem!
  }

  var servicesItem: NSMenuItem {
    if _servicesItem == nil {
      let menu = NSMenu()
      menu.addItem(.separator())

      menu.addItem(withTitle: Localized.menuTitleConfigure) {
        NSWorkspace.shared.open(Services.fileURL)
      }

      menu.addItem(withTitle: Localized.menuTitleDocumentation) {
        NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#connect-to-system-services")
      }

      let item = NSMenuItem(title: Localized.menuTitleServices)
      item.submenu = menu
      _servicesItem = item
    }
    return _servicesItem!
  }

  var clipboardItem: NSMenuItem {
    if _clipboardItem == nil {
      let menu = NSMenu()
      menu.autoenablesItems = false

      menu.addItem(translateItem)
      menu.addItem(quickLookItem)
      menu.addItem(saveImageItem)
      menu.addItem(.separator())
      menu.addItem(copyAllMenuItem)
      menu.addItem(clearContentsItem)

      if NSPasteboard.general.hasFullAccess {
        menu.addItem(.separator())
        menu.addItem(observeChangesItem)
        menu.addItem(contentFiltersItem)
      }

      let item = NSMenuItem(title: Localized.menuTitleClipboard)
      item.submenu = menu
      _clipboardItem = item
    }
    return _clipboardItem!
  }

  var translateItem: NSMenuItem {
    if _translateItem == nil {
      let item = NSMenuItem(title: Localized.menuTitleTranslate)
      item.addAction { [weak self] in
        Translator.showWindow(text: self?.currentResult?.spacesJoined ?? "")
      }
      _translateItem = item
    }
    return _translateItem!
  }

  var quickLookItem: NSMenuItem {
    if _quickLookItem == nil {
      let item = NSMenuItem(title: Localized.menuTitleQuickLook)
      item.addAction { [weak self] in
        self?.previewCopiedImage()
      }
      _quickLookItem = item
    }
    return _quickLookItem!
  }

  var saveImageItem: NSMenuItem {
    if _saveImageItem == nil {
      let item = NSMenuItem(title: Localized.menuTitleSaveAsFile)
      item.addAction {
        NSPasteboard.general.saveImageAsFile()
      }
      _saveImageItem = item
    }
    return _saveImageItem!
  }

  var copyAllMenuItem: NSMenuItem {
    if _copyAllMenuItem == nil {
      let menu = NSMenu()
      menu.addItem(withTitle: Localized.menuTitleJoinWithLineBreaks) {
        NSPasteboard.general.string = self.currentResult?.lineBreaksJoined
      }

      menu.addItem(withTitle: Localized.menuTitleJoinWithSpaces) {
        NSPasteboard.general.string = self.currentResult?.spacesJoined
      }

      menu.addItem(withTitle: Localized.menuTitleJoinDirectly) {
        NSPasteboard.general.string = self.currentResult?.directlyJoined
      }

      let item = NSMenuItem(title: Localized.menuTitleCopyAll)
      item.submenu = menu
      _copyAllMenuItem = item
    }
    return _copyAllMenuItem!
  }

  var clearContentsItem: NSMenuItem {
    if _clearContentsItem == nil {
      let item = NSMenuItem(title: Localized.menuTitleClearContents)
      item.addAction {
        NSPasteboard.general.clearContents()
      }
      _clearContentsItem = item
    }
    return _clearContentsItem!
  }

  var observeChangesItem: NSMenuItem {
    if _observeChangesItem == nil {
      let cacheKey = Keys.observeChanges
      UserDefaults.standard.register(defaults: [cacheKey: true])

      let item = NSMenuItem(title: Localized.menuTitleObserveChanges)
      item.addAction { [weak self, weak item] in
        let isOn = item?.state == .off
        UserDefaults.standard.set(isOn, forKey: cacheKey)

        item?.setOn(isOn)
        self?.updateObserver(isEnabled: isOn)
      }

      item.setOn(UserDefaults.standard.bool(forKey: cacheKey))
      _observeChangesItem = item
    }
    return _observeChangesItem!
  }

  var contentFiltersItem: NSMenuItem {
    if _contentFiltersItem == nil {
      let menu = NSMenu()
      menu.addItem(withTitle: Localized.menuTitleConfigure) {
        NSWorkspace.shared.open(ContentFilters.fileURL)
      }

      menu.addItem(withTitle: Localized.menuTitleDocumentation) {
        NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#content-filters")
      }

      let item = NSMenuItem(title: Localized.menuTitleContentFilters)
      item.submenu = menu
      _contentFiltersItem = item
    }
    return _contentFiltersItem!
  }

  var launchAtLoginItem: NSMenuItem {
    if _launchAtLoginItem == nil {
      let item = NSMenuItem(title: Localized.menuTitleLaunchAtLogin)
      item.addAction { [weak item] in
        do {
          try SMAppService.mainApp.toggle()
        } catch {
          Logger.log(.error, "\(error)")
        }

        item?.toggle()
      }

      item.setOn(SMAppService.mainApp.isEnabled)
      _launchAtLoginItem = item
    }
    return _launchAtLoginItem!
  }

  var appVersionItem: NSMenuItem {
    if _appVersionItem == nil {
      let item = NSMenuItem(title: Bundle.main.humanReadableVersion)
      item.toolTip = Links.releases
      item.addAction(Keys.appVersionAction) {
        NSWorkspace.shared.safelyOpenURL(string: Links.releases)
      }
      _appVersionItem = item
    }
    return _appVersionItem!
  }

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
