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

  func changes(pasteboard: NSPasteboard = .general, interval: Duration = .seconds(1.0)) -> AsyncStream<Void> {
    AsyncStream { continuation in
      var lastCount = pasteboard.changeCount
      let mainTask = Task { @MainActor in
        while !Task.isCancelled {
          try await Task.sleep(for: interval)
          let newCount = pasteboard.changeCount
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
