//
//  PreviewImageIntent.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/27.
//

import AppKit
import AppIntents

struct PreviewImageIntent: AppIntent {
  static let title: LocalizedStringResource = "Preview Copied Content"
  static let description = IntentDescription(
    "Previews copied content using TextGrabber2.",
    searchKeywords: ["TextGrabber2"],
  )

  func perform() async throws -> some IntentResult {
    Task { @MainActor in
      (NSApp.delegate as? App)?.previewCopiedContent()
    }

    return .result()
  }
}
