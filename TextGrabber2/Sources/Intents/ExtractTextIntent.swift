//
//  ExtractTextIntent.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/27.
//

import AppKit
import AppIntents

struct ExtractTextIntent: AppIntent {
  struct ResultEntity: AppEntity {
    struct DummyQuery: EntityQuery {
      func entities(for identifiers: [ResultEntity.ID]) async throws -> [ResultEntity] { [] }
      func suggestedEntities() async throws -> [ResultEntity] { [] }
    }

    static let defaultQuery = DummyQuery()
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Result" }

    var id: String { title }
    var title: String

    var displayRepresentation: DisplayRepresentation {
      DisplayRepresentation(title: "\(title)")
    }
  }

  static let title: LocalizedStringResource = "Extract Text from Copied Image"
  static let description = IntentDescription(
    "Extracts text from copied image using TextGrabber2.",
    searchKeywords: ["TextGrabber2"],
  )

  func perform() async throws -> some ReturnsValue<[ResultEntity]> {
    let image = NSPasteboard.general.image?.cgImage
    let result = await Recognizer.detect(image: image, level: .accurate)
    let candidates = result?.candidates ?? []

    return .result(value: candidates.map {
      ResultEntity(title: $0)
    })
  }
}
