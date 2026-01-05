//
//  String+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2025/5/14.
//

import AppKit

extension String {
  /**
   Returns a single-line version of the string by replacing newlines with spaces.
   */
  var singleLine: String {
    components(separatedBy: .newlines).joined(separator: " ")
  }

  var utf8Data: Data? {
    data(using: .utf8)
  }

  /**
   Returns a truncated string that fits the desired drawing width, with specified font.
   */
  func truncatedToFit(width: Double, font: NSFont) -> String {
    // Early return if it already fits
    if self.width(using: font) <= width {
      return self
    }

    // Binary search to find truncation point
    var low = 0
    var high = count
    var truncated = self

    while low < high {
      let mid = (low + high) / 2
      let test = "\(prefix(mid))\(Constants.suffix)"
      if test.width(using: font) <= width {
        low = mid + 1
        truncated = test
      } else {
        high = mid
      }
    }

    return truncated
  }

  func matches(regex pattern: String, fallback: Bool = false) -> Bool {
    if let regex = try? Regex(pattern) {
      return firstMatch(of: regex) != nil
    }

    return fallback
  }
}

// MARK: - Private

private extension String {
  enum Constants {
    // Half-width space and horizontal ellipsis
    static let suffix = "\u{2009}\u{2026}"
  }

  func width(using font: NSFont) -> Double {
    NSAttributedString(
      string: self,
      attributes: [NSAttributedString.Key.font: font]
    ).size().width
  }
}
