//
//  Translator.swift
//  TextGrabber2
//
//  Created by cyan on 2025/11/30.
//

import AppKit

@MainActor
enum Translator {
  static func showWindow(text: String) {
    NSApp.activate()
    contentVC?.setValue(NSAttributedString(string: text), forKey: "text")
    windowController.showWindow(nil)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
      windowController.window?.center()
    }
  }

  // MARK: - Private

  private static var contentVC = controllerClass?.init()
  private static var windowController = {
    let window = NSWindow(contentViewController: contentVC ?? NSViewController())
    window.styleMask = [.closable, .titled]
    window.title = ""
    window.isReleasedWhenClosed = false
    return NSWindowController(window: window)
  }()
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
