//
//  ConfigurationFile.swift
//  TextGrabber2
//
//  Created by cyan on 2026/8/27.
//

import Foundation

enum SchemaURLs {
  static let contentFilters = "https://raw.githubusercontent.com/TextGrabber2-app/schemas/main/content-filters.json"
  static let keyBindings = "https://raw.githubusercontent.com/TextGrabber2-app/schemas/main/key-bindings.json"
  static let services = "https://raw.githubusercontent.com/TextGrabber2-app/schemas/main/services.json"
}

struct ConfigurationFile<Item: Decodable>: Decodable {
  let items: [Item]

  init(from decoder: Decoder) throws {
    if let items = try? decoder.singleValueContainer().decode([Item].self) {
      self.items = items
      return
    }

    let container = try decoder.container(keyedBy: CodingKeys.self)
    items = try container.decode([Item].self, forKey: .items)
  }

  static func migrate(at fileURL: URL, schemaURL: String) throws {
    let data = try Data(contentsOf: fileURL)
    guard try JSONSerialization.jsonObject(with: data) is [Any],
          let json = String(data: data, encoding: .utf8) else {
      return
    }

    let items = json.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "\n", with: "\n  ")
    let migratedJSON = "{\n  \"$schema\": \"\(schemaURL)\",\n  \"items\": \(items)\n}\n"
    let migratedData = Data(migratedJSON.utf8)
    try migratedData.write(to: fileURL, options: .atomic)
  }

  private enum CodingKeys: String, CodingKey {
    case items
  }
}
