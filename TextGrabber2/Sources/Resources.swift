//
//  Resources.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import Foundation

/**
 To make localization work, always use `String(localized:comment:)` directly and add to this file.

 Besides, we use `string catalogs` to do the translation work:
 https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog
 */
enum Localized {
  static let languageIdentifier = String(localized: "en-US", comment: "Identifier used to locate localized resources")
  static let failedToRun = String(localized: "Failed to run \"%@\".", comment: "Error message when a system service failed")
  static let menuTitleHintCapture = String(localized: "Capture Screen to Detect", comment: "[Menu] Hint for capturing the screen")
  static let menuTitleHintCopy = String(localized: "Click to Copy", comment: "[Menu] Hint for copying text")
  static let menuTitleHintRecognizing = String(localized: "Recognizing...", comment: "[Menu] The recognition is ongoing")
  static let menuTitleHowTo = String(localized: "How to Capture?", comment: "[Menu] How to use the app")
  static let menuTitleCopyAll = String(localized: "Copy All", comment: "[Menu] Copy all text at once")
  static let menuTitleJoinDirectly = String(localized: "Join Directly", comment: "[Menu] Join all text directly")
  static let menuTitleJoinWithLineBreaks = String(localized: "Join with Line Breaks", comment: "[Menu] Join all text with line breaks and copy them")
  static let menuTitleJoinWithSpaces = String(localized: "Join with Spaces", comment: "[Menu] Join all text with spaces and copy them")
  static let menuTitleServices = String(localized: "Services", comment: "[Menu] System services menu")
  static let menuTitleConfigure = String(localized: "Configure", comment: "[Menu] Configure system services")
  static let menuTitleDocumentation = String(localized: "Documentation", comment: "[Menu] Open the wiki for system services")
  static let menuTitleClipboard = String(localized: "Clipboard", comment: "[Menu] Clipboard options")
  static let menuTitleSaveAsFile = String(localized: "Save as File", comment: "[Menu] Save the clipboard as file")
  static let menuTitleClearContents = String(localized: "Clear Contents", comment: "[Menu] Clear the clipboard")
  static let menuTitleGitHub = String(localized: "GitHub", comment: "[Menu] Open the TextGrabber2 repository on GitHub")
  static let menuTitleLaunchAtLogin = String(localized: "Launch at Login", comment: "[Menu] Automatically start the app at login")
  static let menuTitleVersion = String(localized: "Version", comment: "[Menu] Version number label")
  static let menuTitleQuitTextGrabber2 = String(localized: "Quit TextGrabber2", comment: "[Menu] Quit the app")
}

// Icon set used in the app: https://developer.apple.com/sf-symbols/
//
// Note: double check availability and deployment target before adding new icons
enum Icons {
  static let textViewFinder = "text.viewfinder"
}

enum Links {
  static let github = "https://github.com/TextGrabber2-app/TextGrabber2"
}
