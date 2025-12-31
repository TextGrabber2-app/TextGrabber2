//
//  App+Observer.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

// MARK: - Pasteboard Observer

extension App {
  func updateObserver(isEnabled: Bool) {
    copyObserver?.cancel()
    copyObserver = nil
    contentFiltersItem.isEnabled = isEnabled

    guard isEnabled else {
      return
    }

    let pasteboard = NSPasteboard.general
    let interval: Duration = .seconds(ContentFilters.hasRules ? 0.5 : 1.0)

    let handleChanges = { [weak self] in
      // Prevent infinite loops caused by pasteboard modifications
      if let self, Date.timeIntervalSinceReferenceDate - self.contentProcessedTime > 2 {
        ContentFilters.processRules(for: pasteboard)
        self.contentProcessedTime = Date.timeIntervalSinceReferenceDate
      }

      Task {
        await self?.startDetection()
      }
    }

    copyObserver = Task { @MainActor in
      for await _ in CopyObserver.default.changes(pasteboard: pasteboard, interval: interval) {
        handleChanges()
      }
    }

    handleChanges()
  }
}
