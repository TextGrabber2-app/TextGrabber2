//
//  ContentFilters.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/24.
//

import AppKit
import UniformTypeIdentifiers

enum ContentFilters {
  static var fileURL: URL {
    URL.documentsDirectory.appending(
      path: Constants.fileName,
      directoryHint: .notDirectory
    )
  }

  static var hasRules: Bool {
    rules.hasValue
  }

  static func initialize() {
    guard !FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
      return Logger.log(.info, "\(Constants.fileName) was created before")
    }

    do {
      try "[]\n".write(to: fileURL, atomically: true, encoding: .utf8)
    } catch {
      Logger.log(.error, "\(error)")
    }
  }

  @MainActor
  static func processRules(for pasteboard: NSPasteboard) {
    pasteboard.types?.forEach {
      for rule in rules where rule.canHandle(pboardType: $0) {
        rule.handle(pasteboard: pasteboard, type: $0)
      }
    }
  }
}

// MARK: - Private

private extension ContentFilters {
  struct Rule: Decodable, Hashable {
    let type: String
    let match: String?
    let sourceApp: String?
    let runService: String?
    let replaceWith: String?

    func canHandle(pboardType: NSPasteboard.PasteboardType) -> Bool {
      if type == pboardType.rawValue {
        return true
      }

      if let type1 = UTType(type), let type2 = UTType(pboardType.rawValue) {
        return type2.conforms(to: type1)
      }

      return false
    }

    @MainActor
    func handle(pasteboard: NSPasteboard, type: NSPasteboard.PasteboardType) {
      if let sourceApp, NSWorkspace.shared.frontmostApplication?.localizedName != sourceApp {
        return Logger.log(.debug, "The rule does not apply to the source application")
      }

      if let lastTime = contentProcessedTime[self], Date.timeIntervalSinceReferenceDate - lastTime < 2 {
        return Logger.log(.debug, "The rule was just applied, skipping to prevent dead loops")
      }

      let text = pasteboard.string(forType: type)
      let shouldHandle: Bool

      if let match {
        shouldHandle = text?.matches(regex: match) ?? false
      } else {
        shouldHandle = true
      }

      guard shouldHandle else {
        return Logger.log(.debug, "The rule does not apply to the text")
      }

      // "runService"
      if let service = runService {
        let result = NSPerformService(service, pasteboard)
        Logger.log(.debug, "Result of running \(service): \(result)")
      }

      // "replaceWith"
      if let replacement = replaceWith {
        let data = {
          if let match {
            return text?.replacingOccurrences(
              of: match,
              with: replacement,
              options: .regularExpression
            )
          }

          return replacement
        }()?.utf8Data

        pasteboard.insertItem(
          type: type,
          data: data?.isEmpty == true ? nil : data
        )
      }

      contentProcessedTime[self] = Date.timeIntervalSinceReferenceDate
    }
  }

  enum Constants {
    static let fileName = "content-filters.json"
  }

  static let rules: [Rule] = {
    guard let data = try? Data(contentsOf: fileURL) else {
      Logger.log(.error, "Missing \(Constants.fileName)")
      return []
    }

    guard let rules = try? JSONDecoder().decode([Rule].self, from: data) else {
      Logger.log(.error, "Failed to decode the file")
      return []
    }

    return rules
  }()

  @MainActor static var contentProcessedTime = [Rule: TimeInterval]()
}
