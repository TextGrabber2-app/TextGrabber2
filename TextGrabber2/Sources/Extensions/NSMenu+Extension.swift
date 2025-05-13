//
//  NSMenu+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.

import AppKit

extension NSMenu {
  /**
   Hook this method to work around the **Populating a menu window that is already visible** crash.
   */
  static let swizzleIsUpdatedExcludingContentTypesOnce: () = {
    NSMenu.exchangeInstanceMethods(
      originalSelector: sel_getUid("_isUpdatedExcludingContentTypes:"),
      swizzledSelector: #selector(swizzled_isUpdatedExcludingContentTypes(_:))
    )
  }()

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

// MARK: - Private

private extension NSMenu {
  @objc func swizzled_isUpdatedExcludingContentTypes(_ contentTypes: Int) -> Bool {
    // The original implementation contains an invalid assertion that causes a crash.
    // Based on testing, it would return false anyway, so we simply return false to bypass the assertion.
    false
  }
}
