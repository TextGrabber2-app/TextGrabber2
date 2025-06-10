//
//  App.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit
import ServiceManagement

@MainActor
final class App: NSObject, NSApplicationDelegate {
  private var currentResult: Recognizer.ResultData?

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

  private let hintItem: NSMenuItem = {
    let item = NSMenuItem()
    if NSPasteboard.general.hasLimitedAccess {
      item.image = NSImage(systemSymbolName: Icons.handRaisedSlash, accessibilityDescription: nil)
    }

    return item
  }()

  private let howToItem: NSMenuItem = {
    let item = NSMenuItem(title: NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHowToSetUp : Localized.menuTitleHowToCapture)
    item.addAction {
      let section = NSPasteboard.general.hasLimitedAccess ? "limited-access" : "capture-screen-on-mac"
      NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#\(section)")
    }

    return item
  }()

  private lazy var servicesItem: NSMenuItem = {
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
    return item
  }()

  private lazy var clipboardItem: NSMenuItem = {
    let menu = NSMenu()
    menu.autoenablesItems = false
    menu.addItem(copyAllItem)
    menu.addItem(saveImageItem)

    menu.addItem(withTitle: Localized.menuTitleClearContents) {
      NSPasteboard.general.clearContents()
    }

    let item = NSMenuItem(title: Localized.menuTitleClipboard)
    item.submenu = menu
    return item
  }()

  private lazy var copyAllItem: NSMenuItem = {
    let menu = NSMenu()
    menu.addItem(withTitle: Localized.menuTitleJoinDirectly) {
      NSPasteboard.general.string = self.currentResult?.directlyJoined
    }

    menu.addItem(withTitle: Localized.menuTitleJoinWithLineBreaks) {
      NSPasteboard.general.string = self.currentResult?.lineBreaksJoined
    }

    menu.addItem(withTitle: Localized.menuTitleJoinWithSpaces) {
      NSPasteboard.general.string = self.currentResult?.spacesJoined
    }

    let item = NSMenuItem(title: Localized.menuTitleCopyAll)
    item.submenu = menu
    return item
  }()

  private let saveImageItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleSaveAsFile)
    item.addAction {
      NSPasteboard.general.saveImageAsFile()
    }

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

    item.setOn(SMAppService.mainApp.isEnabled)
    return item
  }()

  func statusItemInfo() -> (rect: CGRect, screen: NSScreen?)? {
    guard let button = statusItem.button, let window = button.window else {
      Logger.log(.error, "Missing button or window to provide positioning info")
      return nil
    }

    return (window.convertToScreen(button.frame), window.screen ?? .main)
  }
}

// MARK: - Life Cycle

extension App {
  func applicationDidFinishLaunching(_ notification: Notification) {
    Services.initialize()
    clearMenuItems()
    statusItem.isVisible = true

    // Handle quit action manually since we don't have a window anymore
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      // Cmd-Q
      if event.keyCode == 0x0C && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
        NSApp.terminate(nil)
        return nil
      }

      return event
    }
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
        
        if !NSPerformService(service.serviceName, .general) {
          NSAlert.runModal(message: String(format: Localized.failedToRun, service.displayName))
        }
      }

      servicesItem.submenu?.insertItem(item, at: 0)
    }
  }

  func menuDidClose(_ menu: NSMenu) {
    clearMenuItems()
  }
}

// MARK: - Private

private extension App {
  class ResultItem: NSMenuItem { /* Just a sub-class to be identifiable */ }
  class ServiceItem: NSMenuItem { /* Just a sub-class to be identifiable */ }

  func clearMenuItems() {
    hintItem.title = NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHintLimitedAccess : Localized.menuTitleHintCapture
    statusItem.menu?.removeItems { $0 is ResultItem }
  }

  func startDetection() {
    guard let menu = statusItem.menu else {
      return Logger.assertFail("Missing menu to proceed")
    }

    currentResult = nil
    copyAllItem.isEnabled = false
    saveImageItem.isEnabled = false

    guard let image = NSPasteboard.general.image?.cgImage else {
      return Logger.log(.info, "No image was copied")
    }

    if !NSPasteboard.general.hasLimitedAccess {
      hintItem.title = Localized.menuTitleHintRecognizing
    }

    Task {
      if let fastResult = await Recognizer.detect(image: image, level: .fast) {
        showResult(fastResult, in: menu)
      }

      if let accurateResult = await Recognizer.detect(image: image, level: .accurate) {
        showResult(accurateResult, in: menu)
      }
    }
  }

  func showResult(_ resultData: Recognizer.ResultData, in menu: NSMenu) {
    guard currentResult != resultData else {
      #if DEBUG
        Logger.log(.debug, "No change in result data")
      #endif
      return
    }

    currentResult = resultData
    copyAllItem.isEnabled = resultData.candidates.count > 1
    saveImageItem.isEnabled = true

    if NSPasteboard.general.hasLimitedAccess {
      hintItem.title = Localized.menuTitleHintLimitedAccess
    } else {
      hintItem.title = resultData.candidates.isEmpty ? Localized.menuTitleHintCapture : Localized.menuTitleHintCopy
    }

    let separator = NSMenuItem.separator()
    menu.insertItem(separator, at: menu.index(of: howToItem) + 1)
    menu.removeItems { $0 is ResultItem }

    for text in resultData.candidates.reversed() {
      let item = ResultItem(title: text.truncatedToFit(width: 320, font: .menuFont(ofSize: 0)))
      item.addAction { NSPasteboard.general.string = text }
      menu.insertItem(item, at: menu.index(of: separator) + 1)
    }
  }
}
