//
//  Intents.swift
//  TextGrabber2
//
//  Created by cyan on 2025/10/30.
//

import AppKit
import AppIntents

struct IntentProvider: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    return [
      AppShortcut(
        intent: ExtractIntent(),
        phrases: [
          "Extract text from copied image using \(.applicationName)",
        ],
        shortTitle: "\(ExtractIntent.title)",
        systemImageName: "text.viewfinder"
      ),
    ]
  }
}

struct ExtractIntent: AppIntent {
  static let title: LocalizedStringResource = "Extract Text from Copied Image"
  static let description = IntentDescription(
    "Extract text from copied image using TextGrabber2.",
    searchKeywords: ["TextGrabber2"],
  )

  func perform() async throws -> some ReturnsValue<[ResultEntity]> {
    let image = NSPasteboard.general.image?.cgImage
    let text = NSPasteboard.general.string

    let result = await Recognizer.detect(image: image, level: .accurate)
    let candidates = (result?.candidates ?? []) + [text].compactMap { $0 }

    if let first = candidates.first, !first.isEmpty {
      NSPasteboard.general.string = first
    }

    let entities = candidates.map {
      ResultEntity(title: $0, subtitle: nil)
    }

    if entities.count == 1 {
      return .result(value: entities)
    }

    return .result(value: entities + [
      ResultEntity(
        title: candidates.joined(separator: " "),
        subtitle: Localized.menuTitleJoinWithSpaces
      ),
      ResultEntity(
        title: candidates.joined(separator: "\n"),
        subtitle: Localized.menuTitleJoinWithLineBreaks
      ),
      ResultEntity(
        title: candidates.joined(),
        subtitle: Localized.menuTitleJoinDirectly
      ),
    ])
  }
}

struct ResultEntity: AppEntity {
  struct DummyQuery: EntityQuery {
    func entities(for identifiers: [ResultEntity.ID]) async throws -> [ResultEntity] { [] }
    func suggestedEntities() async throws -> [ResultEntity] { [] }
  }

  static let defaultQuery = DummyQuery()
  static var typeDisplayRepresentation: TypeDisplayRepresentation { "Result" }

  var id: String { title }
  var title: String
  var subtitle: String?

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(title)",
      subtitle: subtitle.map { "\($0)" }
    )
  }
}
