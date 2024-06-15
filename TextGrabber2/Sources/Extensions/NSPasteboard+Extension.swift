//
//  NSPasteboard+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/21.
//

import AppKit

extension NSPasteboard {
  var isEmpty: Bool {
    pasteboardItems?.isEmpty ?? false
  }

  var string: String? {
    get {
      string(forType: .string)
    }
    set {
      guard let newValue else {
        return
      }

      declareTypes([.string], owner: nil)
      setString(newValue, forType: .string)
    }
  }

  var image: NSImage? {
    // Copied file
    if let data = data(forType: .fileURL),
       let string = String(data: data, encoding: .utf8),
       let url = URL(string: string) {
      return NSImage(contentsOf: url)
    }

    // Copied tiff or png
    if let data = data(forType: .tiff) ?? data(forType: .png) {
      return NSImage(data: data)
    }

    // Fallback
    return (readObjects(forClasses: [NSImage.self]) as? [NSImage])?.first
  }

  @MainActor
  func saveImageAsFile() {
    NSApp.activate()

    let savePanel = NSSavePanel()
    savePanel.allowedContentTypes = [.png]
    savePanel.isExtensionHidden = false

    guard let pngData = image?.pngData, savePanel.runModal() == .OK, let url = savePanel.url else {
      return
    }

    do {
      try pngData.write(to: url, options: .atomic)
    } catch {
      Logger.log(.error, "Failed to save the image")
    }
  }
}
