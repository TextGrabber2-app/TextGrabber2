//
//  Preferences.swift
//  TextGrabber2
//
//  Created by cyan on 2025/6/10.
//

import Foundation

/**
 UserDefaults wrapper with handy getters and setters.
 */
enum Preferences {}

@MainActor
@propertyWrapper
struct Storage<T: Codable> {
  private let key: String
  private let defaultValue: T

  init(key: String, defaultValue: T) {
    self.key = key
    self.defaultValue = defaultValue
  }

  var wrappedValue: T {
    get {
      guard let data = UserDefaults.standard.object(forKey: key) as? Data else {
        return defaultValue
      }

      let value = try? Coders.decoder.decode(T.self, from: data)
      return value ?? defaultValue
    }
    set {
      let data = try? Coders.encoder.encode(newValue)
      UserDefaults.standard.set(data, forKey: key)
    }
  }
}

private enum Coders {
  static let encoder = JSONEncoder()
  static let decoder = JSONDecoder()
}
