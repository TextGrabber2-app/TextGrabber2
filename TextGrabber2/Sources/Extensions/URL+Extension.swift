//
//  URL+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2025/10/30.
//

import Foundation

extension URL {
  static var previewingDirectory: URL {
    let directory = temporaryDirectory.appendingPathComponent("QuickLook")
    let fileManager = FileManager.default

    if !fileManager.directoryExists(at: directory) {
      do {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)
      } catch {
        Logger.log(.error, "Failed to create previewing directory: \(error.localizedDescription)")
      }
    }

    return directory
  }
}

// MARK: - Private

private extension FileManager {
  func directoryExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let fileExists = fileExists(atPath: url.path, isDirectory: &isDirectory)
    return fileExists && isDirectory.boolValue
  }
}
