//
//  LookUp.swift
//  TextGrabber2
//
//  Created by cyan on 2026/1/14.
//

import AppKit

@MainActor
enum LookUp {
  static func showPopover(text: String, sourceView: NSView) {
    guard let presenter = sharedPresenter as? NSObject else {
      return Logger.assertFail("Missing LUPresenter")
    }

    // Get the method invocation
    let selector = sel_getUid("animationControllerForTerm:relativeToRect:ofView:options:")
    let invocation = unsafeBitCast(presenter.method(for: selector), to: (@convention(c) (
      NSObject, Selector, NSAttributedString, CGRect, NSView?, NSDictionary
    ) -> NSObject).self)

    // Get the controller and show the popover
    let controller = invocation(presenter, selector, .init(string: text), .zero, sourceView, .init())
    let popover = controller.value(forKey: "popover") as? NSPopover

    (NSApp.delegate as? App)?.overrideDelegate(of: popover)
    controller.perform(sel_getUid("showPopover"))

    // Remove the text highlight effects
    for window in NSApp.windows where window.isOverlayWindow {
      window.close()
    }
  }

  // MARK: - Private

  private static let sharedPresenter = presenterClass?.value(forKey: "sharedPresenter")
}

// MARK: - Private

private extension LookUp {
  static var presenterClass: NSObject.Type? {
    Bundle.loadBundle(named: "LookUp")

    // LUPresenter
    let className = "LU" + "Presenter"
    return NSClassFromString(className) as? NSObject.Type
  }
}
