//
//  KeyBindings.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/29.
//

import AppKit

enum KeyBindings {
  struct Item: Decodable {
    let key: String
    let modifiers: [String]
    let actionName: String
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

  static let items: [Item] = {
    guard let data = try? Data(contentsOf: fileURL) else {
      Logger.log(.error, "Missing \(Constants.fileName)")
      return []
    }

    guard let items = try? JSONDecoder().decode([Item].self, from: data) else {
      Logger.log(.error, "Failed to decode the file")
      return []
    }

    return items
  }()
}

// MARK: - Private

private extension KeyBindings {
  enum Constants {
    static let fileName = "key-bindings.json"
  }

  static let fileURL: URL = {
    URL.documentsDirectory.appending(
      path: Constants.fileName,
      directoryHint: .notDirectory
    )
  }()
}
