//
//  SMAppService+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.

import ServiceManagement

extension SMAppService {
  var isEnabled: Bool {
    status == .enabled
  }

  func toggle() throws {
    try (isEnabled ? unregister() : register())
  }
}
