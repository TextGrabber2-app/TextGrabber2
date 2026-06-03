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
        intent: ExtractTextIntent(),
        phrases: [
          "Extract text from copied image using \(.applicationName)",
        ],
        shortTitle: "Extract Text from Copied Image",
        systemImageName: "text.viewfinder"
      ),
      AppShortcut(
        intent: PreviewImageIntent(),
        phrases: [
          "Preview copied content using \(.applicationName)",
        ],
        shortTitle: "Preview Copied Content",
        systemImageName: "eye"
      ),
      AppShortcut(
        intent: GetClipboardTypesIntent(),
        phrases: [
          "Get clipboard types using \(.applicationName)",
        ],
        shortTitle: "Get Clipboard Types",
        systemImageName: "list.bullet.clipboard"
      ),
      AppShortcut(
        intent: GetClipboardDataIntent(),
        phrases: [
          "Get clipboard data using \(.applicationName)",
        ],
        shortTitle: "Get Clipboard Data",
        systemImageName: "list.clipboard"
      ),
      AppShortcut(
        intent: SetClipboardDataIntent(),
        phrases: [
          "Set clipboard data using \(.applicationName)",
        ],
        shortTitle: "Set Clipboard Data",
        systemImageName: "pencil.and.list.clipboard"
      ),
      AppShortcut(
        intent: PerformActionIntent(),
        phrases: [
          "Perform action using \(.applicationName)",
        ],
        shortTitle: "Perform TextGrabber2 Action",
        systemImageName: "play.circle"
      ),
    ]
  }
}
