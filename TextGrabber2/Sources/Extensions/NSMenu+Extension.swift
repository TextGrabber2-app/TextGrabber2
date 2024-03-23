//
//  NSMenu+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.

import AppKit

extension NSMenu {
  @discardableResult
  func addItem(withTitle string: String, action selector: Selector? = nil) -> NSMenuItem {
    addItem(withTitle: string, action: selector, keyEquivalent: "")
  }

  @discardableResult
  func addItem(withTitle string: String, action: @escaping () -> Void) -> NSMenuItem {
    let item = addItem(withTitle: string, action: nil)
    item.addAction(action)
    return item
  }

  func removeItems(where: (NSMenuItem) -> Bool) {
    items.filter { `where`($0) }.forEach {
      removeItem($0)
    }
  }
}
