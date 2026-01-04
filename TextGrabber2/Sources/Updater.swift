//
//  Updater.swift
//  TextGrabber2
//
//  Created by cyan on 2024/12/3.
//

import AppKit

enum Updater {
  /**
   [GitHub Releases API](https://api.github.com/repos/TextGrabber2-app/TextGrabber2/releases/latest)
   */
  fileprivate struct Version: Decodable {
    let name: String
    let body: String
    let htmlUrl: String
  }

  private enum Constants {
    static let endpoint = "https://api.github.com/repos/TextGrabber2-app/TextGrabber2/releases/latest"
    static let decoder = {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      return decoder
    }()
  }

  static func checkForUpdates() async {
    guard !UserDefaults.standard.bool(forKey: App.Keys.disableUpdates) else {
      return Logger.log(.info, "App updates are disabled by the user")
    }

    guard let url = URL(string: Constants.endpoint) else {
      return Logger.assertFail("Failed to create the URL: \(Constants.endpoint)")
    }

    guard let (data, response) = try? await URLSession.shared.data(from: url) else {
      return Logger.log(.error, "Failed to reach out to the server")
    }

    guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 else {
      return Logger.log(.error, "Failed to get the update")
    }

    guard let version = try? Constants.decoder.decode(Version.self, from: data) else {
      return Logger.log(.error, "Failed to decode the data")
    }

    DispatchQueue.main.async {
      presentUpdate(newVersion: version)
    }
  }
}

// MARK: - Private

@MainActor
private extension Updater {
  static func presentUpdate(newVersion: Version) {
    guard newVersion.name != Bundle.main.shortVersionString else {
      return
    }

    (NSApp.delegate as? App)?.showAppUpdate(name: newVersion.name, url: newVersion.htmlUrl)
  }
}
