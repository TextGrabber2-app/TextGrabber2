//
//  App.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

@MainActor
final class App: NSObject, NSApplicationDelegate {
  // MARK: - Internal State
  private(set) var copyObserver: Task<Void, Never>?
  private(set) var currentResult: Recognizer.ResultData?
  private(set) var silentDetectCount = 0
  private(set) var contentProcessedTime: TimeInterval = 0

  // Internal setters for extensions
  func setCopyObserver(_ observer: Task<Void, Never>?) {
    copyObserver = observer
  }

  func setCurrentResult(_ result: Recognizer.ResultData?) {
    currentResult = result
  }

  func setSilentDetectCount(_ count: Int) {
    silentDetectCount = count
  }

  func setContentProcessedTime(_ time: TimeInterval) {
    contentProcessedTime = time
  }

  private var isMenuVisible = false {
    didSet {
      statusItem.button?.highlight(isMenuVisible)

      if isMenuVisible {
        unregisterKeyBindings()
      } else {
        registerKeyBindings()
      }
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

  func increaseUserClickCount() {
    userClickCount += 1
  }
}

// MARK: - Helper Types

extension App {
  class ResultItem: NSMenuItem { /* Just a sub-class to be identifiable */ }

  enum Keys {
    static let userClickCount = "general.user-click-count"
    static let observeChanges = "pasteboard.observe-changes"
    static let appVersionAction = "app.textgrabber2.app-version"
  }
}

// MARK: - Life Cycle

extension App {
  func applicationDidFinishLaunching(_ notification: Notification) {
    // LSUIElement = YES does not work reliably; keyboard events are sometimes not handled.
    NSApp.setActivationPolicy(.accessory)

    registerKeyBindings()
    updateServices()
    statusItem.isVisible = true

    // Observe pasteboard changes to detect silently
    if NSPasteboard.general.hasFullAccess && observeChangesItem.state == .on {
      updateObserver(isEnabled: true)
    }

    // Handle in-app keyboard events
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      let keyCode = event.keyCode
      let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

      // Cmd-Q (should be handled by menu action, just in case)
      if keyCode == 0x0C && flags == .command {
        NSApp.terminate(nil)
        return nil
      }

      // Cmd-W (mainly for windows like translate)
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
    updateServices()

    // Rely on this instead of mutating items in menuWillOpen
    isMenuVisible = true
    Task {
      await startDetection(userInitiated: true)
    }
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    guard KeyBindings.items.hasValue else {
      return
    }

    menu.enumerateDescendants { item in
      if let keyBinding = (KeyBindings.items.first { $0.actionName == item.title }) {
        item.setKeyBinding(with: keyBinding)
      }
    }
  }

  func menuDidClose(_ menu: NSMenu) {
    isMenuVisible = false
  }
}
