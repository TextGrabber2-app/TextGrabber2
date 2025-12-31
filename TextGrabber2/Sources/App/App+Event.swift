//
//  App+Event.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

// MARK: - Event Monitoring

extension App {
  func addEventMonitors() {
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
  }
}
