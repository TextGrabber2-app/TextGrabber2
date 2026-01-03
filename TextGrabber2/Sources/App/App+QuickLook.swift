//
//  App+QuickLook.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit
import QuickLookUI

// MARK: - QuickLook Previewing

extension App: @preconcurrency QLPreviewPanelDataSource {
  func numberOfPreviewItems(in panel: QLPreviewPanel?) -> Int {
    1
  }

  func previewPanel(_ panel: QLPreviewPanel?, previewItemAt index: Int) -> (any QLPreviewItem)? {
    previewingFileURL as? NSURL
  }

  func previewCopiedContent() {
    let pngData = NSPasteboard.general.image?.pngData
    let textData = NSPasteboard.general.string?.utf8Data

    let fileExtension = pngData == nil ? "txt" : "png"
    let fileName = "\(Localized.copiedContentName).\(fileExtension)"
    self.previewingFileURL = .previewingDirectory.appending(path: fileName, directoryHint: .notDirectory)

    guard let data = pngData ?? textData, let previewingFileURL else {
      return Logger.log(.info, "No content for preview")
    }

    NSApp.bringToFront()
    try? data.write(to: previewingFileURL)

    let previewPanel = QLPreviewPanel.shared()
    previewPanel?.dataSource = self
    previewPanel?.reloadData()
    previewPanel?.makeKeyAndOrderFront(nil)
  }
}
