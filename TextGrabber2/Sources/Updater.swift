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
    let currentVersion = Bundle.main.shortVersionString

    // Check if the new version was skipped
    guard !Preferences.Updater.skippedVersions.contains(newVersion.name) else {
      return
    }

    // Check if the version is different
    guard newVersion.name != currentVersion else {
      return
    }

    let alert = NSAlert()
    alert.messageText = String(format: Localized.Updater.newVersionAvailableTitle, newVersion.name)
    alert.markdownBody = newVersion.body
    alert.addButton(withTitle: Localized.Updater.learnMore)
    alert.addButton(withTitle: Localized.Updater.remindMeLater)
    alert.addButton(withTitle: Localized.Updater.skipThisVersion)

    switch alert.runModal() {
    case .alertFirstButtonReturn: // Learn More
      NSWorkspace.shared.safelyOpenURL(string: newVersion.htmlUrl)
    case .alertThirdButtonReturn: // Skip This Version
      Preferences.Updater.skippedVersions.insert(newVersion.name)
    default:
      break
    }
  }
}

// MARK: - Private

private extension Localized {
  enum Updater {
    static let newVersionAvailableTitle = String(localized: "TextGrabber2 %@ is available!", comment: "Title for new version available")
    static let learnMore = String(localized: "Learn More", comment: "Title for the \"Learn More\" button")
    static let remindMeLater = String(localized: "Remind Me Later", comment: "Title for the \"Remind Me Later\" button")
    static let skipThisVersion = String(localized: "Skip This Version", comment: "Title for the \"Skip This Version\" button")
  }
}

private extension Preferences {
  enum Updater {
    @Storage(key: "updater.skipped-versions", defaultValue: Set())
    static var skippedVersions: Set<String>
  }
}
