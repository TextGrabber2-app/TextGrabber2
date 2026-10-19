//
//  Logger.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/21.
//

import Foundation
import os.log

enum Logger {
  static func log(_ level: OSLogType, _ message: @autoclosure @escaping () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
    let file = fileName(file)
    os_logger.log(level: level, "\(file):\(line), \(function) -> \(message())")
  }

  static func assertFail(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    assertionFailure(message(), file: file, line: line)
  }

  static func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    if !condition() {
      assertionFailure(message(), file: file, line: line)
    }
  }

  @inline(never)
  private static func fileName(_ file: StaticString) -> String {
    // Share filename formatting across specialized logging calls
    let file = "\(file)"
    return URL(string: file)?.lastPathComponent ?? file
  }
}

private let os_logger = os.Logger()
