//
//  NSImage+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.

import AppKit

extension NSImage {
  var cgImage: CGImage? {
    var rect = CGRect(origin: .zero, size: size)
    return cgImage(forProposedRect: &rect, context: .current, hints: nil)
  }

  var pngData: Data? {
    guard let tiffData = tiffRepresentation else {
      Logger.log(.error, "Failed to get the tiff data")
      return nil
    }

    guard let bitmapRep = NSBitmapImageRep(data: tiffData) else {
      Logger.log(.error, "Failed to get the bitmap representation")
      return nil
    }

    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
      Logger.log(.error, "Failed to get the png data")
      return nil
    }

    return pngData
  }

  static func with(
    symbolName: String,
    pointSize: Double,
    weight: NSFont.Weight = .regular,
    accessibilityLabel: String? = nil
  ) -> NSImage {
    let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)

    guard let image = image?.withSymbolConfiguration(config) else {
      Logger.assertFail("Failed to create image with symbol \"\(symbolName)\"")
      return NSImage()
    }

    return image
  }
}
