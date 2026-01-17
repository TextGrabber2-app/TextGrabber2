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
  var copyObserver: Task<Void, Never>?
  var currentResult: Recognizer.ResultData?
  var previewingFileURL: URL?
  var silentDetectCount = 0

  lazy var statusItem: NSStatusItem = {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.behavior = .terminationOnRemoval
    item.autosaveName = Bundle.main.bundleName

    if let symbolName = UserDefaults.standard.string(forKey: Keys.statusBarIcon) {
      item.button?.image = .with(symbolName: symbolName)
    }

    if item.button?.image == nil {
      item.button?.image = .with(symbolName: Icons.textViewFinder)
    }

    Logger.assert(item.button?.image != nil, "Button image should not be nil")
    item.button?.setAccessibilityLabel("TextGrabber2")

    return item
  }()

  lazy var mainMenu: NSMenu = {
    let menu = NSMenu()
    menu.delegate = self
    menu.minimumWidth = 220

    menu.addItem(hintItem)
    menu.addItem(howToItem)
    menu.addItem(.separator())
    menu.addItem(copyAllQuickItem)
    menu.addItem(.separator())
    menu.addItem(servicesItem)
    menu.addItem(clipboardToolsItem)
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

    return menu
  }()

  lazy var hintItem: NSMenuItem = {
    let item = NSMenuItem()
    if NSPasteboard.general.hasLimitedAccess {
      item.image = NSImage(systemSymbolName: Icons.handRaisedSlash, accessibilityDescription: nil)
    }

    return item
  }()

  lazy var howToItem: NSMenuItem = {
    let item = NSMenuItem(title: NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHowToSetUp : Localized.menuTitleHowToUse)
    item.addAction { [weak self] in
      let section = NSPasteboard.general.hasLimitedAccess ? "limited-access" : "capture-screen-on-mac"
      NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#\(section)")
      self?.increaseUserClickCount()
    }

    return item
  }()

  lazy var copyAllQuickItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleCopyAll)
    item.addAction { [weak self] in
      NSPasteboard.general.string = self?.currentResult?.lineBreaksJoined
    }

    return item
  }()

  lazy var servicesItem: NSMenuItem = {
    let menu = NSMenu()
    menu.addItem(.separator())

    menu.addItem(withTitle: Localized.menuTitleSettings) {
      NSWorkspace.shared.open(Services.fileURL)
    }

    menu.addItem(withTitle: Localized.menuTitleUserManual) {
      NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#connect-to-system-services")
    }

    let item = NSMenuItem(title: Localized.menuTitleServices)
    item.submenu = menu
    return item
  }()

  lazy var clipboardToolsItem: NSMenuItem = {
    let menu = NSMenu()
    menu.autoenablesItems = false

    menu.addItem(translateItem)
    menu.addItem(quickLookItem)
    menu.addItem(saveAsFileItem)
    menu.addItem(.separator())
    menu.addItem(copyAllMenuItem)
    menu.addItem(clearContentsItem)

    if NSPasteboard.general.hasFullAccess {
      menu.addItem(.separator())
      menu.addItem(observeChangesItem)
      menu.addItem(contentFiltersItem)
    }

    let item = NSMenuItem(title: Localized.menuTitleClipboardTools)
    item.submenu = menu
    return item
  }()

  lazy var translateItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleTranslate)
    item.addAction { [weak self] in
      guard let sourceView = self?.statusItem.button else {
        return Logger.log(.error, "Missing status item button")
      }

      if let window = NSApp.popoverWindow {
        window.closePopover()
      } else {
        let text = self?.currentResult?.spacesJoined.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        NSApp.bringToFront()

        if text.isWord {
          LookUp.showPopover(text: text, sourceView: sourceView)
        } else {
          Translator.showPopover(text: text, sourceView: sourceView)
        }

        NSApp.popoverWindow?.makeKeyAndOrderFront(nil)
      }
    }

    return item
  }()

  lazy var quickLookItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleQuickLook)
    item.addAction { [weak self] in
      self?.previewCopiedContent()
    }

    return item
  }()

  lazy var saveAsFileItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleSaveAsFile)
    item.addAction {
      NSPasteboard.general.saveContentAsFile()
    }

    return item
  }()

  lazy var copyAllMenuItem: NSMenuItem = {
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
    return item
  }()

  lazy var clearContentsItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleClearContents)
    item.addAction {
      NSPasteboard.general.clearContents()
    }

    return item
  }()

  lazy var observeChangesItem: NSMenuItem = {
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
    return item
  }()

  lazy var contentFiltersItem: NSMenuItem = {
    let menu = NSMenu()
    menu.addItem(withTitle: Localized.menuTitleSettings) {
      NSWorkspace.shared.open(ContentFilters.fileURL)
    }

    menu.addItem(withTitle: Localized.menuTitleUserManual) {
      NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#content-filters")
    }

    let item = NSMenuItem(title: Localized.menuTitleContentFilters)
    item.submenu = menu
    return item
  }()

  lazy var launchAtLoginItem: NSMenuItem = {
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

  lazy var appVersionItem: NSMenuItem = {
    let item = NSMenuItem(title: Bundle.main.humanReadableVersion)
    item.toolTip = Links.releases
    item.addAction(Keys.appVersionAction) {
      NSWorkspace.shared.safelyOpenURL(string: Links.releases)
    }

    return item
  }()

  var isMenuVisible = false {
    didSet {
      guard isMenuVisible != oldValue else {
        return
      }

      if isMenuVisible {
        unregisterKeyBindings()
      } else {
        registerKeyBindings()
      }

      statusItem.button?.highlight(isMenuVisible)
    }
  }

  var userClickCount: Int {
    get {
      UserDefaults.standard.integer(forKey: Keys.userClickCount)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Keys.userClickCount)
    }
  }

  func increaseUserClickCount() {
    userClickCount += 1
  }
}

// MARK: - Helper Types

extension App {
  class ResultItem: NSMenuItem {
    /* Just a sub-class to be identifiable */
  }

  enum Keys {
    static let disableUpdates = "general.disable-updates"
    static let statusBarIcon = "general.status-bar-icon"
    static let userClickCount = "general.user-click-count"
    static let observeChanges = "pasteboard.observe-changes"
    static let observeInterval = "pasteboard.observe-interval"
    static let appVersionAction = "app.textgrabber2.app-version"
  }
}

// MARK: - Life Cycle

extension App {
  func applicationDidFinishLaunching(_ notification: Notification) {
    // LSUIElement = YES does not work reliably; keyboard events are sometimes not handled.
    NSApp.setActivationPolicy(.accessory)

    updateServices()
    statusItem.isVisible = true

    // Event handling
    addEventMonitors()
    registerKeyBindings()

    // Observe pasteboard changes to detect silently
    if NSPasteboard.general.hasFullAccess && observeChangesItem.state == .on {
      updateObserver(isEnabled: true)
    }

    let silentlyCheckUpdates: @Sendable () -> Void = {
      Task {
        await Updater.checkForUpdates()
      }
    }

    // Check for updates on launch with a delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: silentlyCheckUpdates)

    // Check for updates on a weekly basis, for users who never quit apps
    Timer.scheduledTimer(withTimeInterval: 7 * 24 * 60 * 60, repeats: true) { _ in
      silentlyCheckUpdates()
    }
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    // LSUIElement = YES does not work reliably; keyboard events are sometimes not handled.
    NSApp.setActivationPolicy(.accessory)
  }

  func applicationWillTerminate(_ notification: Notification) {
    try? FileManager.default.removeItem(at: .previewingDirectory)
  }
}
