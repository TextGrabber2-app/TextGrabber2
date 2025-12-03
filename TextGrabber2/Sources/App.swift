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
  private var currentResult: Recognizer.ResultData?
  private var lastDetectionTime: TimeInterval = 0
  private var previewingFileURL: URL {
    .previewingDirectory.appendingPathComponent("TextGrabber2.png")
  }

  private lazy var statusItem: NSStatusItem = {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.behavior = .terminationOnRemoval
    item.autosaveName = Bundle.main.bundleName

    item.button?.image = .with(symbolName: Icons.textViewFinder, pointSize: 15)
    item.button?.setAccessibilityLabel("TextGrabber2")

    let menu = NSMenu()
    menu.delegate = self

    menu.addItem(hintItem)
    menu.addItem(howToItem)
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
    menu.addItem({
      let item = NSMenuItem(title: "\(Localized.menuTitleVersion) \(Bundle.main.shortVersionString)")
      item.toolTip = Links.releases
      item.addAction {
        NSWorkspace.shared.safelyOpenURL(string: Links.releases)
      }

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

    menu.addItem(translateItem)
    menu.addItem(quickLookItem)
    menu.addItem(saveImageItem)
    menu.addItem(.separator())
    menu.addItem(copyAllItem)

    menu.addItem(withTitle: Localized.menuTitleClearContents) {
      NSPasteboard.general.clearContents()
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

  private lazy var copyAllItem: NSMenuItem = {
    let menu = NSMenu()
    menu.addItem(withTitle: Localized.menuTitleJoinWithSpaces) {
      NSPasteboard.general.string = self.currentResult?.spacesJoined
    }

    menu.addItem(withTitle: Localized.menuTitleJoinWithLineBreaks) {
      NSPasteboard.general.string = self.currentResult?.lineBreaksJoined
    }

    menu.addItem(withTitle: Localized.menuTitleJoinDirectly) {
      NSPasteboard.general.string = self.currentResult?.directlyJoined
    }

    let item = NSMenuItem(title: Localized.menuTitleCopyAll)
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
}

// MARK: - Life Cycle

extension App {
  func applicationDidFinishLaunching(_ notification: Notification) {
    Services.initialize()
    clearMenuItems()
    statusItem.isVisible = true

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

    // Handle the case where menuWillOpen is not properly invoked
    NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      guard let button = self?.statusItem.button, let contentView = button.window?.contentView else {
        return event
      }

      if contentView.hitTest(button.convert(event.locationInWindow, from: nil)) != nil {
        if let menu = self?.statusItem.menu {
          self?.menuWillOpen(menu)
        }
      }

      return event
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
  func menuWillOpen(_ menu: NSMenu) {
    // Delay the detection to work around an internal race condition in macOS Tahoe
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.startDetection()
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
  }

  func menuDidClose(_ menu: NSMenu) {
    clearMenuItems()
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

  func clearMenuItems() {
    hintItem.title = NSPasteboard.general.hasLimitedAccess ? Localized.menuTitleHintLimitedAccess : Localized.menuTitleHintCapture
    statusItem.menu?.removeItems { $0 is ResultItem }
  }

  func startDetection(retryCount: Int = 0) {
    guard let menu = statusItem.menu else {
      return Logger.assertFail("Missing menu to proceed")
    }

    guard Date.timeIntervalSinceReferenceDate - lastDetectionTime > 0.5 else {
      return Logger.log(.info, "Just detected, skipping")
    }

    lastDetectionTime = Date.timeIntervalSinceReferenceDate
    currentResult = nil
    translateItem.isEnabled = false
    quickLookItem.isEnabled = false
    saveImageItem.isEnabled = false
    copyAllItem.isEnabled = false

    let retryDetectionLater = {
      guard retryCount < 3 else {
        return
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.lastDetectionTime = 0
        self.startDetection(retryCount: retryCount + 1)
      }
    }

    let image = NSPasteboard.general.image?.cgImage
    let text = NSPasteboard.general.string

    guard image != nil || text != nil else {
      Logger.log(.info, "No image or text copied")
      return retryDetectionLater()
    }

    Task {
      let fastResult = await Recognizer.detect(image: image, level: .fast)
      if let fastResult {
        showResult(fastResult, textCopied: text, in: menu)
      }

      let accurateResult = await Recognizer.detect(image: image, level: .accurate)
      if let accurateResult {
        showResult(accurateResult, textCopied: text, in: menu)
      }

      // Both failed, retrying...
      if fastResult == nil && accurateResult == nil {
        retryDetectionLater()
      }
    }
  }

  func showResult(_ imageResult: Recognizer.ResultData, textCopied: String?, in menu: NSMenu) {
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
    copyAllItem.isEnabled = resultData.candidates.hasValue

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

      if item.title != text {
        item.toolTip = text
      }
    }
  }
}
