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

  var hasLimitedAccess: Bool {
    guard #available(macOS 15.4, *) else {
      return false
    }

    return accessBehavior != .alwaysAllow
  }

  var hasFullAccess: Bool {
    !hasLimitedAccess
  }

  @discardableResult
  func insertItem(type: NSPasteboard.PasteboardType, data: Data?, clearOthers: Bool = false) -> Bool {
    var items = clearOthers ? [:] : getDataItems()
    items[type] = data

    return setDataItems(items, sourceType: type)
  }

  @MainActor
  func saveContentAsFile() {
    NSApp.bringToFront()

    let pngData = image?.pngData
    let textData = string?.utf8Data

    let savePanel = NSSavePanel()
    savePanel.allowedContentTypes = pngData == nil ? [.plainText] : [.png]
    savePanel.isExtensionHidden = false
    savePanel.titlebarAppearsTransparent = true

    guard let data = pngData ?? textData, savePanel.runModal() == .OK, let url = savePanel.url else {
      return
    }

    do {
      try data.write(to: url, options: .atomic)
    } catch {
      Logger.log(.error, "Failed to save the content")
    }
  }
}

// MARK: - Private

private extension NSPasteboard {
  func getDataItems() -> [NSPasteboard.PasteboardType: Data] {
    (types ?? []).reduce(into: [NSPasteboard.PasteboardType: Data]()) { items, type in
      items[type] = data(forType: type)
    }
  }

  @discardableResult
  func setDataItems(
    _ items: [NSPasteboard.PasteboardType: Data],
    sourceType: NSPasteboard.PasteboardType? = nil
  ) -> Bool {
    var items = items

    // Mirror types must be updated at the same time
    if let sourceType, let mirror = mirrorTypes[sourceType.rawValue] {
      items[.init(mirror)] = items[sourceType]
    }

    var result = true
    declareTypes(Array(items.keys), owner: nil)

    for (type, data) in items {
      result = result && setData(data, forType: type)
    }

    return result
  }
}

private let mirrorTypes = [
  "NSStringPboardType": "public.utf8-plain-text",
  "public.utf8-plain-text": "NSStringPboardType",

  "NSFilenamesPboardType": "public.file-url",
  "public.file-url": "NSFilenamesPboardType",

  "NeXT TIFF v4.0 pasteboard type": "public.tiff",
  "public.tiff": "NeXT TIFF v4.0 pasteboard type",

  "NeXT Rich Text Format v1.0 pasteboard type": "public.rtf",
  "public.rtf": "NeXT Rich Text Format v1.0 pasteboard type",

  "NeXT RTFD pasteboard type": "com.apple.flat-rtfd",
  "com.apple.flat-rtfd": "NeXT RTFD pasteboard type",

  "Apple HTML pasteboard type": "public.html",
  "public.html": "Apple HTML pasteboard type",

  "Apple Web Archive pasteboard type": "com.apple.webarchive",
  "com.apple.webarchive": "Apple Web Archive pasteboard type",

  "Apple URL pasteboard type": "public.url",
  "public.url": "Apple URL pasteboard type",

  "Apple PDF pasteboard type": "com.adobe.pdf",
  "com.adobe.pdf": "Apple PDF pasteboard type",

  "Apple PNG pasteboard type": "public.png",
  "public.png": "Apple PNG pasteboard type",

  "NSColor pasteboard type": "com.apple.cocoa.pasteboard.color",
  "com.apple.cocoa.pasteboard.color": "NSColor pasteboard type",

  "iOS rich content paste pasteboard type": "com.apple.uikit.attributedstring",
  "com.apple.uikit.attributedstring": "iOS rich content paste pasteboard type",
]
