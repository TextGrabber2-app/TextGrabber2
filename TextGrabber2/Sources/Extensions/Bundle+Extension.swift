//
//  Bundle+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.

import Foundation

extension Bundle {
  var bundleName: String? {
    infoDictionary?[kCFBundleNameKey as String] as? String
  }

  var shortVersionString: String {
    guard let version = infoDictionary?["CFBundleShortVersionString"] as? String else {
      Logger.assertFail("Missing CFBundleShortVersionString in bundle \(self)")
      return "1.0.0"
    }

    return version
  }
}
