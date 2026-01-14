//
//  NSApplication+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/29.
//

import AppKit

extension NSApplication {
  var popoverWindow: NSWindow? {
    windows.first(where: \.isPopoverWindow)
  }

  func bringToFront() {
    activate(ignoringOtherApps: true)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      guard !self.isActive else {
        return
      }

      // ignoringOtherApps is no longer reliable, use this as a fallback
      if let bundleIdentifier = Bundle.main.bundleIdentifier {
        NSWorkspace.shared.openApplication(with: bundleIdentifier)
      }
    }
  }
}

// MARK: - Private

private extension NSWorkspace {
  func openApplication(with bundleIdentifier: String) {
    guard let url = urlForApplication(withBundleIdentifier: bundleIdentifier) else {
      return
    }

    openApplication(at: url, configuration: .init())
  }
}
