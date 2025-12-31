//
//  GetClipboardTypesIntent.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/27.
//

import AppKit
import AppIntents

struct GetClipboardTypesIntent: AppIntent {
  static let title: LocalizedStringResource = "Get Clipboard Types"
  static let description = IntentDescription("Gets available content types from the clipboard.")

  func perform() async throws -> some ReturnsValue<[String]> {
    let types = NSPasteboard.general.types ?? []
    return .result(value: types.map(\.rawValue))
  }
}
