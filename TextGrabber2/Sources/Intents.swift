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
        shortTitle: "\(ExtractTextIntent.title)",
        systemImageName: "text.viewfinder"
      ),
      AppShortcut(
        intent: PreviewImageIntent(),
        phrases: [
          "Preview copied image using \(.applicationName)",
        ],
        shortTitle: "\(PreviewImageIntent.title)",
        systemImageName: "eye"
      ),
      AppShortcut(
        intent: GetClipboardTypesIntent(),
        phrases: [
          "Get clipboard types using \(.applicationName)",
        ],
        shortTitle: "\(GetClipboardTypesIntent.title)",
        systemImageName: "list.bullet.clipboard"
      ),
      AppShortcut(
        intent: GetClipboardDataIntent(),
        phrases: [
          "Get clipboard data using \(.applicationName)",
        ],
        shortTitle: "\(GetClipboardDataIntent.title)",
        systemImageName: "list.clipboard"
      ),
      AppShortcut(
        intent: SetClipboardDataIntent(),
        phrases: [
          "Set clipboard data using \(.applicationName)",
        ],
        shortTitle: "\(SetClipboardDataIntent.title)",
        systemImageName: "pencil.and.list.clipboard"
      ),
    ]
  }
}
