//
//  App+Observer.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

// MARK: - Pasteboard Observing

extension App {
  func updateObserver(isEnabled: Bool) {
    copyObserver?.cancel()
    copyObserver = nil
    contentFiltersItem.isEnabled = isEnabled

    guard isEnabled else {
      return
    }

    let pasteboard = NSPasteboard.general
    let interval: Duration = .seconds(observeInterval)

    let handleChanges = { [weak self] in
      ContentFilters.processRules(for: pasteboard)

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

// MARK: - Private

private extension App {
  var observeInterval: Double {
    let userValue = UserDefaults.standard.double(forKey: Keys.observeInterval)
    if userValue > 0.1 {
      return userValue
    }

    return ContentFilters.hasRules ? 0.4 : 1.0
  }
}
