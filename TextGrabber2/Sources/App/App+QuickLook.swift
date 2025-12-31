//
//  App+QuickLook.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit
import QuickLookUI

// MARK: - QLPreviewPanelDataSource

extension App: @preconcurrency QLPreviewPanelDataSource {
  private var previewingFileURL: URL {
    .previewingDirectory.appendingPathComponent("TextGrabber2.png")
  }

  func numberOfPreviewItems(in panel: QLPreviewPanel?) -> Int {
    1
  }

  func previewPanel(_ panel: QLPreviewPanel?, previewItemAt index: Int) -> (any QLPreviewItem)? {
    previewingFileURL as NSURL
  }

  func previewCopiedImage() {
    guard let pngData = NSPasteboard.general.image?.pngData else {
      return Logger.log(.info, "No image for preview")
    }

    NSApp.bringToFront()
    try? pngData.write(to: self.previewingFileURL)

    let previewPanel = QLPreviewPanel.shared()
    previewPanel?.dataSource = self
    previewPanel?.reloadData()
    previewPanel?.makeKeyAndOrderFront(nil)
  }
}
