//
//  NSWindow+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2026/1/14.
//

import AppKit

extension NSWindow {
  var isPopoverWindow: Bool {
    className.contains("PopoverWindow")
  }

  func closePopover() {
    guard isPopoverWindow else {
      return
    }

    (value(forKey: "_popover") as? NSPopover)?.close()
  }
}
