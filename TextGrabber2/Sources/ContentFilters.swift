//
//  ContentFilters.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/24.
//

import AppKit

enum ContentFilters {
  static let fileURL: URL = {
    URL.documentsDirectory.appending(
      path: Constants.fileName,
      directoryHint: .notDirectory
    )
  }()

  static func initialize() {
    guard !FileManager.default.fileExists(atPath: fileURL.path()) else {
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
      for rule in rules where rule.type == $0.rawValue {
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
    let service: String

    func handle(pasteboard: NSPasteboard, type: NSPasteboard.PasteboardType) {
      let shouldHandle: Bool = {
        guard let match else {
          return true
        }

        guard let text = pasteboard.string(forType: type) else {
          return false
        }

        return text.matches(regex: match)
      }()

      if shouldHandle {
        let result = NSPerformService(service, pasteboard)
        Logger.log(.debug, "Result of running \(service): \(result)")
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
