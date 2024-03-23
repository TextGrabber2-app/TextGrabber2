//
//  NSWorkspace+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.

import AppKit

extension NSWorkspace {
  @discardableResult
  func safelyOpenURL(string: String) -> Bool {
    guard let url = URL(string: string) else {
      Logger.assertFail("Failed to create the URL: \(string)")
      return false
    }

    return open(url)
  }
}
