//
//  Translator.swift
//  TextGrabber2
//
//  Created by cyan on 2025/11/30.
//

import AppKit

@MainActor
enum Translator {
  static func showPopover(text: String, sourceView: NSView) {
    Logger.assert(contentVC != nil, "Missing contentVC")
    contentVC?.setValue(NSAttributedString(string: text), forKey: "text")

    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentViewController = contentVC

    (NSApp.delegate as? App)?.overrideDelegate(of: popover)
    popover.show(relativeTo: sourceView.bounds, of: sourceView, preferredEdge: .maxY)
  }

  // MARK: - Private

  private static let contentVC = controllerClass?.init()
}

// MARK: - Private

private extension Translator {
  static var controllerClass: NSViewController.Type? {
    Bundle.loadBundle(named: "TranslationUIServices")

    // LTUITranslationViewController
    let className = "LTUI" + "TranslationViewController"
    return NSClassFromString(className) as? NSViewController.Type
  }
}
