//
//  App.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit
import QuickLookUI
import ServiceManagement

@MainActor
final class App: NSObject, NSApplicationDelegate {
  private var copyObserver: Task<Void, Never>?
  private var currentResult: Recognizer.ResultData?
  private var silentDetectCount = 0
  private var contentProcessedTime: TimeInterval = 0

  private var previewingFileURL: URL {
    .previewingDirectory.appendingPathComponent("TextGrabber2.png")
  }

  private var isMenuVisible = false {
    didSet {
      statusItem.button?.highlight(isMenuVisible)
    }
  }

  private var userClickCount: Int {
    get {
      UserDefaults.standard.integer(forKey: Keys.userClickCount)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Keys.userClickCount)
    }
  }

  private lazy var statusItem: NSStatusItem = {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.behavior = .terminationOnRemoval
    item.autosaveName = Bundle.main.bundleName

    item.button?.image = .with(symbolName: Icons.textViewFinder, pointSize: 15)
    item.button?.setAccessibilityLabel("TextGrabber2")

    return item
  }()

  private lazy var mainMenu: NSMenu = {
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

    return menu
  }()

  private let hintItem: NSMenuItem = {
    let item = NSMenuItem()
    if NSPasteboard.general.hasLimitedAccess {
      item.image = NSImage(systemSymbolName: Icons.handRaisedSlash, accessibilityDescription: nil)
    }

    return item
  }()

  private lazy var howToItem: NSMenuItem = {
    let item = NSMenuItem(title: NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHowToSetUp : Localized.menuTitleHowToCapture)
    item.addAction { [weak self] in
      let section = NSPasteboard.general.hasLimitedAccess ? "limited-access" : "capture-screen-on-mac"
      NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#\(section)")
      self?.increaseUserClickCount()
    }

    return item
  }()

  private lazy var copyAllQuickItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleCopyAll)
    item.addAction {
      NSPasteboard.general.string = self.currentResult?.lineBreaksJoined
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
    return item
  }()

  private lazy var translateItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleTranslate)
    item.addAction { [weak self] in
      Translator.showWindow(text: self?.currentResult?.spacesJoined ?? "")
    }

    return item
  }()

  private lazy var quickLookItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleQuickLook)
    item.addAction { [weak self] in
      self?.previewCopiedImage()
    }

    return item
  }()

  private let saveImageItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleSaveAsFile)
    item.addAction {
      NSPasteboard.general.saveImageAsFile()
    }

    return item
  }()

  private lazy var copyAllMenuItem: NSMenuItem = {
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

  private let clearContentsItem: NSMenuItem = {
    let item = NSMenuItem(title: Localized.menuTitleClearContents)
    item.addAction {
      NSPasteboard.general.clearContents()
    }

    return item
  }()

  private lazy var observeChangesItem: NSMenuItem = {
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

  private let contentFiltersItem: NSMenuItem = {
    let menu = NSMenu()
    menu.addItem(withTitle: Localized.menuTitleConfigure) {
      NSWorkspace.shared.open(ContentFilters.fileURL)
    }

    menu.addItem(withTitle: Localized.menuTitleDocumentation) {
      NSWorkspace.shared.safelyOpenURL(string: "\(Links.github)/wiki#content-filters")
    }

    let item = NSMenuItem(title: Localized.menuTitleContentFilters)
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

    item.setOn(SMAppService.mainApp.isEnabled)
    return item
  }()

  private let appVersionItem: NSMenuItem = {
    let item = NSMenuItem(title: "\(Localized.menuTitleVersion) \(Bundle.main.shortVersionString)")
    item.toolTip = Links.releases
    item.addAction(Keys.appVersionAction) {
      NSWorkspace.shared.safelyOpenURL(string: Links.releases)
    }

    return item
  }()

  func showAppUpdate(name: String, url: String) {
    appVersionItem.title = String(format: Localized.menuTitleNewVersionOut, name)
    appVersionItem.toolTip = url
    appVersionItem.addAction(Keys.appVersionAction) {
      NSWorkspace.shared.safelyOpenURL(string: url)
    }
  }
}

// MARK: - Life Cycle

extension App {
  func applicationDidFinishLaunching(_ notification: Notification) {
    Services.initialize()
    ContentFilters.initialize()
    statusItem.isVisible = true

    // Observe pasteboard changes to detect silently
    if NSPasteboard.general.hasFullAccess && observeChangesItem.state == .on {
      updateObserver(isEnabled: true)
    }

    // Handle quit action manually since we don't have a window anymore
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      let keyCode = event.keyCode
      let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

      // Cmd-Q
      if keyCode == 0x0C && flags == .command {
        NSApp.terminate(nil)
        return nil
      }

      // Cmd-W
      if keyCode == 0x0D && flags == .command {
        NSApp.keyWindow?.close()
        return nil
      }

      return event
    }

    // Observe clicks on the status item
    NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      guard event.window == self?.statusItem.button?.window else {
        // The click was outside the status window
        return event
      }

      guard !event.modifierFlags.contains(.command) else {
        // Holding the command key usually means the icon is being dragged
        return event
      }

      self?.statusItemClicked()
      return nil
    }

    // Observe clicks outside the app
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
      guard self?.isMenuVisible == true, let menu = self?.mainMenu else {
        return
      }

      // This is needed because menuDidClose isn't reliably called
      self?.menuDidClose(menu)
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

  func applicationWillTerminate(_ notification: Notification) {
    try? FileManager.default.removeItem(at: .previewingDirectory)
  }
}

// MARK: - NSMenuDelegate

extension App: NSMenuDelegate {
  func statusItemClicked() {
    // Hide the user guide after the user becomes familiar
    if userClickCount > 3 && !NSPasteboard.general.hasLimitedAccess {
      howToItem.isHidden = true
    }

    // Update the services menu
    servicesItem.submenu?.removeItems { $0 is ServiceItem }
    for service in Services.items.reversed() {
      let serviceName = service.serviceName
      let displayName = service.displayName ?? serviceName
      let item = ServiceItem(title: displayName)
      item.addAction {
        NSPasteboard.general.string = self.currentResult?.spacesJoined

        if !NSPerformService(serviceName, .general) {
          NSAlert.runModal(message: String(format: Localized.failedToRun, displayName))
        }
      }

      servicesItem.submenu?.insertItem(item, at: 0)
    }

    // Rely on this instead of mutating items in menuWillOpen
    isMenuVisible = true
    startDetection(userInitiated: true)
  }

  func menuDidClose(_ menu: NSMenu) {
    isMenuVisible = false
  }
}

// MARK: - QLPreviewPanelDataSource

extension App: @preconcurrency QLPreviewPanelDataSource {
  func numberOfPreviewItems(in panel: QLPreviewPanel?) -> Int {
    1
  }

  func previewPanel(_ panel: QLPreviewPanel?, previewItemAt index: Int) -> (any QLPreviewItem)? {
    previewingFileURL as NSURL
  }

  func previewCopiedImage() {
    guard let pngData = NSPasteboard.general.image?.pngData else {
      return Logger.log(.info, "No image for preview")
    }

    NSApp.activate()
    try? pngData.write(to: self.previewingFileURL)

    let previewPanel = QLPreviewPanel.shared()
    previewPanel?.dataSource = self
    previewPanel?.reloadData()
    previewPanel?.makeKeyAndOrderFront(nil)
  }
}

// MARK: - Private

private extension App {
  class ResultItem: NSMenuItem { /* Just a sub-class to be identifiable */ }
  class ServiceItem: NSMenuItem { /* Just a sub-class to be identifiable */ }

  enum Keys {
    static let userClickCount = "general.user-click-count"
    static let observeChanges = "pasteboard.observe-changes"
    static let appVersionAction = "app.textgrabber2.app-version"
  }

  func clearMenuItems() {
    hintItem.title = NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHintLimitedAccess : Localized.menuTitleHintCapture
    mainMenu.removeItems { $0 is ResultItem }
  }

  func startDetection(userInitiated: Bool = false) {
    let newCount = NSPasteboard.general.changeCount
    if userInitiated && silentDetectCount == newCount {
      Logger.log(.debug, "Presenting previously detected results")
      return presentMainMenu()
    }

    currentResult = nil
    clearMenuItems()

    translateItem.isEnabled = false
    quickLookItem.isEnabled = false
    saveImageItem.isEnabled = false
    clearContentsItem.isEnabled = !NSPasteboard.general.isEmpty

    copyAllQuickItem.isHidden = true
    copyAllMenuItem.isEnabled = false

    let image = NSPasteboard.general.image?.cgImage
    let text = NSPasteboard.general.string

    Task {
      if let result = await Recognizer.detect(image: image, level: .accurate) {
        updateResult(result, textCopied: text, in: mainMenu)
      } else {
        Logger.log(.error, "Failed to detect text from image")
      }

      if userInitiated {
        Logger.log(.debug, "Presenting newly detected results")
        presentMainMenu()
      } else {
        Logger.log(.debug, "Silently detected and cached")
        silentDetectCount = newCount
      }
    }
  }

  func updateObserver(isEnabled: Bool) {
    copyObserver?.cancel()
    contentFiltersItem.isEnabled = isEnabled

    if isEnabled {
      let pasteboard = NSPasteboard.general
      let interval: Duration = .seconds(ContentFilters.hasRules ? 0.5 : 1.0)

      let handleChanges = { [weak self] in
        // Prevent infinite loops caused by pasteboard modifications
        if let self, Date.timeIntervalSinceReferenceDate - self.contentProcessedTime > 2 {
          ContentFilters.processRules(for: pasteboard)
          self.contentProcessedTime = Date.timeIntervalSinceReferenceDate
        }

        self?.startDetection()
      }

      copyObserver = Task { @MainActor in
        for await _ in CopyObserver.default.changes(pasteboard: pasteboard, interval: interval) {
          handleChanges()
        }
      }

      handleChanges()
    }
  }

  func updateResult(_ imageResult: Recognizer.ResultData, textCopied: String?, in menu: NSMenu) {
    // Combine recognized items and copied text
    let allItems = imageResult.candidates + [textCopied].compactMap { $0 }
    let resultData = type(of: imageResult).init(candidates: allItems)

    guard currentResult != resultData else {
      #if DEBUG
        Logger.log(.debug, "No change in result data")
      #endif
      return
    }

    currentResult = resultData
    translateItem.isEnabled = resultData.candidates.hasValue
    quickLookItem.isEnabled = imageResult.candidates.hasValue
    saveImageItem.isEnabled = imageResult.candidates.hasValue

    copyAllQuickItem.isHidden = resultData.candidates.count < 2
    copyAllMenuItem.isEnabled = resultData.candidates.hasValue

    if NSPasteboard.general.hasLimitedAccess {
      hintItem.title = Localized.menuTitleHintLimitedAccess
    } else {
      hintItem.title = resultData.candidates.isEmpty ? Localized.menuTitleHintCapture : Localized.menuTitleHintCopy
    }

    let separator = NSMenuItem.separator()
    menu.insertItem(separator, at: menu.index(of: howToItem) + 1)

    for text in resultData.candidates.reversed() {
      let item = ResultItem(title: text.singleLine.truncatedToFit(width: 320, font: .menuFont(ofSize: 0)))
      menu.insertItem(item, at: menu.index(of: separator) + 1)

      item.addAction { [weak self] in
        NSPasteboard.general.string = text
        self?.increaseUserClickCount()
      }

      if item.title != text {
        item.toolTip = text
      }
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

  func increaseUserClickCount() {
    userClickCount += 1
  }
}
