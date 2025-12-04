//
//  String+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2025/5/14.
//

import AppKit

extension String {
  var singleLine: String {
    components(separatedBy: .newlines).joined(separator: " ")
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
