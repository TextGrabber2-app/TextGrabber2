//
//  App.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit
import ServiceManagement

final class App: NSObject, NSApplicationDelegate {
  private var currentResult: Recognizer.ResultData?
  private var pasteboardObserver: Timer?
  private var pasteboardChangeCount = 0

  private lazy var statusItem: NSStatusItem = {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.behavior = .terminationOnRemoval
    item.autosaveName = Bundle.main.bundleName
    item.button?.image = .with(symbolName: Icons.textViewFinder, pointSize: 15)

    let menu = NSMenu()
    menu.delegate = self

    menu.addItem(hintItem)
    menu.addItem(howToItem)
    menu.addItem(.separator())
    menu.addItem(copyAllItem)
    menu.addItem(servicesItem)
    menu.addItem(clipboardItem)
    menu.addItem(.separator())
    menu.addItem(launchAtLoginItem)

    menu.addItem(withTitle: Localized.menuTitleGitHub) {
      NSWorkspace.shared.safelyOpenURL(string: Links.github)
    }

    menu.addItem(.separator())
    menu.addItem({
      let item = NSMenuItem(title: "\(Localized.menuTitleVersion) \(Bundle.main.shortVersionString)")
      item.isEnabled = false

      return item
    }())

    menu.addItem({
      let item = NSMenuItem(title: Localized.menuTitleQuitTextGrabber2, action: nil, keyEquivalent: "q")
      item.keyEquivalentModifierMask = .command
      item.addAction {
        NSApp.terminate(nil)
      }

      return item
    }())

    item.menu = menu
    return item
  }()

  private let hintItem = NSMenuItem()
  private let howToItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleHowTo)
    item.addAction {
      NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#capture-screen-on-mac")
    }

    return item
  }()

  private lazy var copyAllItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleCopyAll)
    let menu = NSMenu()

    menu.addItem(withTitle: Localized.menuTitleJoinWithLineBreaks) {
      NSPasteboard.general.string = self.currentResult?.lineBreaksJoined
    }

    menu.addItem(withTitle: Localized.menuTitleJoinWithSpaces) {
      NSPasteboard.general.string = self.currentResult?.spacesJoined
    }

    item.submenu = menu
    return item
  }()

  private let servicesItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleServices)
    let menu = NSMenu()
    menu.addItem(.separator())

    menu.addItem(withTitle: Localized.menuTitleConfigure) {
      NSWorkspace.shared.open(Services.fileURL)
    }

    menu.addItem(withTitle: Localized.menuTitleDocumentation) {
      NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#connect-to-system-services")
    }

    item.submenu = menu
    return item
  }()

  private let clipboardItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleClipboard)
    let menu = NSMenu()

    menu.addItem(withTitle: Localized.menuTitleSaveAsFile) {
      NSPasteboard.general.saveImageAsFile()
    }

    menu.addItem(withTitle: Localized.menuTitleClearContents) {
      NSPasteboard.general.clearContents()
    }

    item.submenu = menu
    return item
  }()

  private let launchAtLoginItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleLaunchAtLogin)
    item.addAction { [weak item] in
      do {
        try SMAppService.mainApp.toggle()
      } catch {
        Logger.log(.error, "\(error)")
      }

      item?.toggle()
    }

    return item
  }()
}

// MARK: - Life Cycle

extension App {
  func applicationDidFinishLaunching(_ notification: Notification) {
    Services.initialize()
    clearMenuItems()
    statusItem.isVisible = true
  }
}

// MARK: - NSMenuDelegate

extension App: NSMenuDelegate {
  func menuWillOpen(_ menu: NSMenu) {
    startDetection()
    
    // Update the services menu
    servicesItem.submenu?.removeItems { $0 is ServiceItem }
    for service in Services.items.reversed() {
      let item = ServiceItem(title: service.displayName)
      item.addAction {
        NSPasteboard.general.string = self.currentResult?.spacesJoined
        NSPerformService(service.serviceName, .general)
      }

      servicesItem.submenu?.insertItem(item, at: 0)
    }

    // For an edge case, we can capture the screen while the menu is shown.
    let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      guard let self, NSPasteboard.general.changeCount != self.pasteboardChangeCount else {
        return
      }

      DispatchQueue.main.async(execute: startDetection)
    }

    pasteboardObserver = timer
    RunLoop.current.add(timer, forMode: .common)
  }

  func menuDidClose(_ menu: NSMenu) {
    clearMenuItems()

    pasteboardObserver?.invalidate()
    pasteboardObserver = nil
  }
}

// MARK: - Private

private extension App {
  class ResultItem: NSMenuItem { /* Just a sub-class to be identifiable */ }
  class ServiceItem: NSMenuItem { /* Just a sub-class to be identifiable */ }

  func clearMenuItems() {
    hintItem.title = Localized.menuTitleHintCapture
    howToItem.isHidden = false
    copyAllItem.isHidden = true
    clipboardItem.isHidden = true
    statusItem.menu?.removeItems { $0 is ResultItem }
  }

  @MainActor func startDetection() {
    guard let menu = statusItem.menu else {
      return Logger.assertFail("Missing menu to proceed")
    }

    pasteboardChangeCount = NSPasteboard.general.changeCount

    guard let image = NSPasteboard.general.image?.cgImage else {
      return Logger.log(.info, "No image was copied")
    }

    hintItem.title = Localized.menuTitleHintRecognizing
    howToItem.isHidden = true

    Task {
      let resultData = await Recognizer.detect(image: image)
      currentResult = resultData

      hintItem.title = resultData.candidates.isEmpty ? Localized.menuTitleHintCapture : Localized.menuTitleHintCopy
      howToItem.isHidden = !resultData.candidates.isEmpty
      copyAllItem.isHidden = resultData.candidates.count < 2
      clipboardItem.isHidden = false

      let separator = NSMenuItem.separator()
      menu.insertItem(separator, at: menu.index(of: howToItem) + 1)
      menu.removeItems { $0 is ResultItem }

      for text in resultData.candidates.reversed() {
        let item = ResultItem(title: text)
        item.addAction { NSPasteboard.general.string = text }
        menu.insertItem(item, at: menu.index(of: separator) + 1)
      }
    }
  }
}
