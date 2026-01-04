//
//  Detector.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/21.
//

import Foundation

/**
 https://developer.apple.com/documentation/foundation/nsdatadetector
 */
enum Detector {
  static func matches(in text: String) -> [Recognizer.Candidate] {
    guard let detector = try? NSDataDetector(types: types) else {
      Logger.assertFail("Failed to create NSDataDetector")
      return []
    }

    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    let matches = detector.matches(in: text, range: range)

    return matches.compactMap { match in
      switch match.resultType {
      case .phoneNumber:
        if let text = match.phoneNumber {
          return .init(text: text, kind: .phoneNumber)
        }

        return nil
      case .link:
        if let text = match.url?.absoluteString {
          return .init(text: text, kind: .link)
        }

        return nil
      default:
        return nil
      }
    }
  }
}

// MARK: - Private

private extension Detector {
  static var types: NSTextCheckingTypes {
    NSTextCheckingResult.CheckingType.phoneNumber.rawValue | NSTextCheckingResult.CheckingType.link.rawValue
  }
}
