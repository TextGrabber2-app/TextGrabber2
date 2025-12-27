//
//  PreviewIntent.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/27.
//

import AppKit
import AppIntents

struct PreviewIntent: AppIntent {
  static let title: LocalizedStringResource = "Preview Copied Image"
  static let description = IntentDescription(
    "Preview copied image using TextGrabber2.",
    searchKeywords: ["TextGrabber2"],
  )

  func perform() async throws -> some IntentResult {
    Task { @MainActor in
      (NSApp.delegate as? App)?.previewCopiedImage()
    }

    return .result()
  }
}
