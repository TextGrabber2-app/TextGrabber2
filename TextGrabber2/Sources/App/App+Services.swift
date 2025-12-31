//
//  App+Services.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

// MARK: - System Services

extension App {
  class ServiceItem: NSMenuItem {
    /* Just a sub-class to be identifiable */
  }

  func updateServices() {
    servicesItem.submenu?.removeItems {
      $0 is ServiceItem
    }

    for service in Services.items.reversed() {
      let serviceName = service.serviceName
      let displayName = service.displayName ?? serviceName
      let item = ServiceItem(title: displayName)
      item.addAction {
        NSPasteboard.general.string = self.currentResult?.spacesJoined

        if !NSPerformService(serviceName, .general) {
          NSAlert.runModal(message: String(format: Localized.failedToRun, displayName))
        }
      }

      servicesItem.submenu?.insertItem(item, at: 0)
    }
  }
}
