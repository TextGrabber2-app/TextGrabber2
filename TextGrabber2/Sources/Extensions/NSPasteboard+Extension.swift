//
//  NSPasteboard+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/21.
//

import AppKit

extension NSPasteboard {
  var isEmpty: Bool {
    pasteboardItems?.isEmpty ?? true
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

  var hasImageOnly: Bool {
    string == nil && image != nil
  }

  var hasLimitedAccess: Bool {
    guard #available(macOS 15.4, *) else {
      return false
    }

    return accessBehavior != .alwaysAllow
  }

  var hasFullAccess: Bool {
    !hasLimitedAccess
  }

  func getDataItems() -> [NSPasteboard.PasteboardType: Data] {
    (types ?? []).reduce(into: [NSPasteboard.PasteboardType: Data]()) { items, type in
      items[type] = data(forType: type)
    }
  }

  @discardableResult
  func setDataItems(_ items: [NSPasteboard.PasteboardType: Data]) -> Bool {
    var items = items
    legacyTypes.forEach {
      // Ensure legacy types are consistent to prevent the changes from being reverted
      items[.init($0.key)] = items[.init($0.value)]
    }

    var result = true
    declareTypes(Array(items.keys), owner: nil)

    for (type, data) in items {
      result = result && setData(data, forType: type)
    }

    return result
  }

  @MainActor
  func saveImageAsFile() {
    NSApp.bringToFront()

    let savePanel = NSSavePanel()
    savePanel.allowedContentTypes = [.png]
    savePanel.isExtensionHidden = false
    savePanel.titlebarAppearsTransparent = true

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

// MARK: - Private

private let legacyTypes = [
  "NSStringPboardType": "public.utf8-plain-text",
  "NSFilenamesPboardType": "public.file-url",
  "NeXT TIFF v4.0 pasteboard type": "public.tiff",
  "NeXT Rich Text Format v1.0 pasteboard type": "public.rtf",
  "NeXT RTFD pasteboard type": "com.apple.flat-rtfd",
  "Apple HTML pasteboard type": "public.html",
  "Apple Web Archive pasteboard type": "com.apple.webarchive",
  "Apple URL pasteboard type": "public.url",
  "Apple PDF pasteboard type": "com.adobe.pdf",
  "Apple PNG pasteboard type": "public.png",
  "NSColor pasteboard type": "com.apple.cocoa.pasteboard.color",
  "iOS rich content paste pasteboard type": "com.apple.uikit.attributedstring",
]
