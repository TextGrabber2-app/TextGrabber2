//
//  App+Popover.swift
//  TextGrabber2
//
//  Created by cyan on 2026/1/30.
//

import AppKit

// MARK: - Popover Handling

extension App: NSPopoverDelegate {
  func overrideDelegate(of popover: NSPopover?) {
    originalDelegate = popover?.delegate
    popover?.delegate = self
  }

  func popoverShouldClose(_ popover: NSPopover) -> Bool {
    originalDelegate?.popoverShouldClose?(popover) ?? true
  }

  func popoverWillShow(_ notification: Notification) {
    originalDelegate?.popoverWillShow?(notification)
    statusItem.button?.highlight(true)
  }

  func popoverDidShow(_ notification: Notification) {
    originalDelegate?.popoverDidShow?(notification)
  }

  func popoverWillClose(_ notification: Notification) {
    originalDelegate?.popoverWillClose?(notification)
    statusItem.button?.highlight(false)
  }

  func popoverDidClose(_ notification: Notification) {
    originalDelegate?.popoverDidClose?(notification)
  }
}

@MainActor private weak var originalDelegate: (any NSPopoverDelegate)?
