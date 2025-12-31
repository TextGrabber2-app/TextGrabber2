//
//  GetClipboardDataIntent.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/27.
//

import AppKit
import AppIntents
import UniformTypeIdentifiers

struct GetClipboardDataIntent: AppIntent {
  static let title: LocalizedStringResource = "Get Clipboard Data"
  static let description = IntentDescription("Gets data from the clipboard for a specific content type.")

  static var parameterSummary: some ParameterSummary {
    Summary("Get Clipboard Data for \(\.$type)")
  }

  @Parameter(title: "Content Type", default: "public.utf8-plain-text", inputOptions: .init(capitalizationType: .none, autocorrect: false, smartQuotes: false, smartDashes: false))
  var type: String

  @MainActor
  func perform() async throws -> some ReturnsValue<IntentFile?> {
    guard let fileData = NSPasteboard.general.data(forType: NSPasteboard.PasteboardType(type)) else {
      return .result(value: nil)
    }

    let fileExtension = UTType(type)?.preferredFilenameExtension ?? {
      if NSImage(data: fileData) != nil {
        return "png"
      }

      return "txt"
    }()

    let resultName = "\(String(localized: "Clipboard (TextGrabber2)")).\(fileExtension)"
    let resultFile = IntentFile(data: fileData, filename: resultName)

    return .result(value: resultFile)
  }
}
