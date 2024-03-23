//
//  NSWindow+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/21.
//

import AppKit

extension NSWindow {
  /**
   Hook the setFrame method to have a fixed width.
   */
  static let swizzleSetFrameDisplayAnimateOnce: () = {
    NSWindow.exchangeInstanceMethods(
      originalSelector: #selector(setFrame(_:display:animate:)),
      swizzledSelector: #selector(swizzled_setFrame(_:display:animate:))
    )
  }()

  @objc func swizzled_setFrame(_ originalRect: CGRect, display: Bool, animate: Bool) {
    // Only for the first popup menu window
    //
    // Private, but we're not on the Mac App Store, so who the hell cares.
    //
    // The worst case is that the width of all popup menu windows is fixed.
    guard NSApp.windows.first(where: { $0.className == "NSPopupMenuWindow" }) === self else {
      return swizzled_setFrame(originalRect, display: display, animate: animate)
    }

    var preferredRect = originalRect
    preferredRect.origin.x += preferredRect.size.width - Constants.preferredWidth
    preferredRect.size.width = Constants.preferredWidth

    swizzled_setFrame(preferredRect, display: display, animate: animate)
  }
}

// MARK: - Private

private extension NSWindow {
  enum Constants {
    static let preferredWidth: Double = 240
  }
}
