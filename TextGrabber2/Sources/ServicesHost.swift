//
//  ServicesHost.swift
//  TextGrabber2
//
//  Created by cyan on 2026/7/1.
//

import AppKit

/**
 Off-screen key window that vends the current text to `NSApp.servicesMenu`,
 which a status-bar menu has no responder chain to populate otherwise.
 */
@MainActor
final class ServicesHost {
  private lazy var textView: NSTextView = {
    let view = NSTextView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    view.isHidden = true
    view.isRichText = false

    return view
  }()

  private lazy var window: NSWindow = {
    let window = ServicesPanel(
      contentRect: CGRect(x: -10000, y: -10000, width: 1, height: 1),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: true
    )

    window.contentView = textView
    window.isReleasedWhenClosed = false
    window.hidesOnDeactivate = false
    window.isExcludedFromWindowsMenu = true
    window.collectionBehavior = [.transient, .ignoresCycle]
    return window
  }()

  private var isActive = false
  private var teardownTask: Task<String?, Never>?
  private var previousText = ""

  func activate(text: String) {
    isActive = true
    teardownTask?.cancel()
    teardownTask = nil

    previousText = text
    textView.string = text
    textView.selectAll(nil)

    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(textView)
  }

  /// Tears down after a delay, cancellable so a clicked service can run first.
  func scheduleTeardown() async -> String? {
    guard isActive else {
      return nil
    }

    teardownTask?.cancel()
    teardownTask = Task { [weak self] () -> String? in
      try? await Task.sleep(for: .seconds(0.5))
      guard let self, !Task.isCancelled else {
        return nil
      }

      return deactivate()
    }

    return await teardownTask?.value
  }

  /// Returns text if a return-type service changed it, otherwise nil.
  private func deactivate() -> String? {
    guard isActive else {
      return nil
    }

    isActive = false
    teardownTask?.cancel()
    teardownTask = nil

    let currentText = textView.string
    window.orderOut(nil)

    return currentText != previousText ? currentText : nil
  }
}

// MARK: - Private

private final class ServicesPanel: NSPanel {
  override var canBecomeKey: Bool { true }
}
