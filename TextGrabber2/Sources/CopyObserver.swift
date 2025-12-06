//
//  CopyObserver.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/6.
//

import AppKit

@MainActor
final class CopyObserver {
  static let `default` = CopyObserver()

  func changes(interval: Duration = .seconds(1.0)) -> AsyncStream<Void> {
    AsyncStream { continuation in
      var lastCount = NSPasteboard.general.changeCount
      let mainTask = Task { @MainActor in
        while !Task.isCancelled {
          try await Task.sleep(for: interval)
          let newCount = NSPasteboard.general.changeCount
          if newCount != lastCount {
            lastCount = newCount
            continuation.yield()
          }
        }
      }

      continuation.onTermination = { _ in
        mainTask.cancel()
      }
    }
  }
}
