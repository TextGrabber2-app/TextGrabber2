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
    NSApp.bringToFront()
    contentVC?.setValue(NSAttributedString(string: text), forKey: "text")

    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentViewController = contentVC

    popover.show(
      relativeTo: sourceView.bounds,
      of: sourceView,
      preferredEdge: .maxY
    )
  }

  // MARK: - Private

  private static let contentVC = controllerClass?.init()
}

// MARK: - Private

private extension Translator {
  static var controllerClass: NSViewController.Type? {
    loadBundle()

    // LTUITranslationViewController
    let className = "LTUI" + "TranslationViewController"
    return NSClassFromString(className) as? NSViewController.Type
  }

  static func loadBundle() {
    // Joined as: /System/Library/PrivateFrameworks/TranslationUIServices.framework
    let path = [
      "",
      "System",
      "Library",
      "PrivateFrameworks",
      "TranslationUIServices.framework",
    ].joined(separator: "/")

    guard let bundle = Bundle(path: path) else {
      return Logger.assertFail("Missing TranslationUIServices")
    }

    guard !bundle.isLoaded else {
      return
    }

    bundle.load()
  }
}
