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
  struct Rule: Decodable {
    let type: String
    let match: String?
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

    func handle(pasteboard: NSPasteboard, type: NSPasteboard.PasteboardType) {
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
      if let text, let match, let replacement = replaceWith {
        let data = text
          .replacingOccurrences(
            of: match,
            with: replacement,
            options: .regularExpression
          )
          .data(using: .utf8)

        pasteboard.insertItem(type: type, data: data)
      }
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
}
