//
//  Services.swift
//  TextGrabber2
//
//  Created by cyan on 2024/4/4.
//

import AppKit

/**
 https://support.apple.com/guide/mac-help/mchlp1012/mac.

 Definition file is located at ~/Library/Containers/app.cyan.textgrabber2/Data/Documents/
 */
enum Services {
  struct Item: Decodable {
    let serviceName: String
    let displayName: String
  }

  static var fileURL: URL {
    URL.documentsDirectory.appending(
      path: Constants.fileName,
      directoryHint: .notDirectory
    )
  }

  static var items: [Item] {
    guard let data = try? Data(contentsOf: fileURL) else {
      Logger.log(.error, "Missing \(Constants.fileName)")
      return []
    }

    guard let items = try? JSONDecoder().decode([Item].self, from: data) else {
      Logger.log(.error, "Failed to decode the file")
      return []
    }

    return items
  }

  static func initialize() {
    guard !FileManager.default.fileExists(atPath: fileURL.path()) else {
      return Logger.log(.info, "\(Constants.fileName) was created before")
    }

    guard let sourceURL = Bundle.main.url(forResource: "Services/\(Localized.languageIdentifier)", withExtension: "json") else {
      return Logger.assertFail("Missing source file to copy from")
    }

    do {
      try FileManager.default.copyItem(at: sourceURL, to: fileURL)
    } catch {
      Logger.log(.error, "\(error)")
    }
  }
}

// MARK: - Private

private extension Services {
  enum Constants {
    static let fileName = "services.json"
  }
}
