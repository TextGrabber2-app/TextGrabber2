//
//  PerformActionIntent.swift
//  TextGrabber2
//
//  Created by cyan on 2026/1/15.
//

import AppKit
import AppIntents

struct PerformActionIntent: AppIntent {
  static let title: LocalizedStringResource = "Perform TextGrabber2 Action"
  static let description = IntentDescription("Performs a TextGrabber2 action available in the menu.")

  static var parameterSummary: some ParameterSummary {
    Summary("Perform \(\.$actionName) in TextGrabber2")
  }

  @Parameter(title: "Action Name")
  var actionName: String

  @MainActor
  func perform() async throws -> some ReturnsValue<Bool> {
    guard let action = (NSApp.delegate as? App)?.mainMenu.firstActionNamed(actionName) else {
      return .result(value: false)
    }

    action.performAction()
    return .result(value: true)
  }
}
