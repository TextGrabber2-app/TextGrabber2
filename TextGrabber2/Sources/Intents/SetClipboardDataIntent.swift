//
//  SetClipboardDataIntent.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/27.
//

import AppKit
import AppIntents

struct SetClipboardDataIntent: AppIntent {
  static let title: LocalizedStringResource = "Set Clipboard Data"
  static let description = IntentDescription("Sets data in the clipboard for a specific content type.")

  static var parameterSummary: some ParameterSummary {
    Summary("Set Clipboard Data for \(\.$type) with \(\.$file)")
  }

  @Parameter(title: "Content Type", default: "public.utf8-plain-text", inputOptions: .init(capitalizationType: .none, autocorrect: false, smartQuotes: false, smartDashes: false))
  var type: String

  @Parameter(title: "File")
  var file: IntentFile

  @MainActor
  func perform() async throws -> some IntentResult {
    let pasteboard = NSPasteboard.general
    let pboardType = NSPasteboard.PasteboardType(type)
    pasteboard.declareTypes([pboardType], owner: nil)

    guard pasteboard.setData(file.data, forType: pboardType) else {
      throw IntentError.setDataFailed(type: type)
    }

    return .result()
  }
}

// MARK: - Private

private enum IntentError: Error, CustomLocalizedStringResourceConvertible {
  case setDataFailed(type: String)

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .setDataFailed(let type): return "Cannot set data for type “\(type)”."
    }
  }
}
