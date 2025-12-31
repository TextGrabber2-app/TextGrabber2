//
//  App+Detection.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

// MARK: - Text Detection

extension App {
  func startDetection(userInitiated: Bool = false) async {
    let newCount = NSPasteboard.general.changeCount
    if silentDetectCount == newCount {
      if userInitiated {
        Logger.log(.debug, "Presenting previously detected results")
        presentMainMenu()
      }

      return
    }

    currentResult = nil
    clearMenuItems()

    translateItem.isEnabled = false
    quickLookItem.isEnabled = false
    saveImageItem.isEnabled = false
    clearContentsItem.isEnabled = !NSPasteboard.general.isEmpty

    copyAllQuickItem.isHidden = true
    copyAllMenuItem.isEnabled = false

    let image = NSPasteboard.general.image?.cgImage
    let text = NSPasteboard.general.string

    if let result = await Recognizer.detect(image: image, level: .accurate) {
      updateResult(result, textCopied: text, in: mainMenu)
    } else {
      Logger.log(.error, "Failed to detect text from image")
    }

    if userInitiated {
      Logger.log(.debug, "Presenting newly detected results")
      presentMainMenu()
    } else {
      Logger.log(.debug, "Silently detected and cached")
      silentDetectCount = newCount
    }
  }

  func updateResult(_ imageResult: Recognizer.ResultData, textCopied: String?, in menu: NSMenu) {
    // Combine recognized items and copied text
    let allItems = imageResult.candidates + [textCopied].compactMap { $0 }
    let resultData = type(of: imageResult).init(candidates: allItems)

    guard currentResult != resultData else {
      #if DEBUG
        Logger.log(.debug, "No change in result data")
      #endif
      return
    }

    currentResult = resultData
    translateItem.isEnabled = resultData.candidates.hasValue
    quickLookItem.isEnabled = imageResult.candidates.hasValue
    saveImageItem.isEnabled = imageResult.candidates.hasValue

    copyAllQuickItem.isHidden = resultData.candidates.count < 2
    copyAllMenuItem.isEnabled = resultData.candidates.hasValue

    if NSPasteboard.general.hasLimitedAccess {
      hintItem.title = Localized.menuTitleHintLimitedAccess
    } else {
      hintItem.title = resultData.candidates.isEmpty ? Localized.menuTitleHintCapture : Localized.menuTitleHintCopy
    }

    let separator = NSMenuItem.separator()
    menu.insertItem(separator, at: menu.index(of: howToItem) + 1)

    for text in resultData.candidates.reversed() {
      let item = ResultItem(title: text.singleLine.truncatedToFit(width: 320, font: .menuFont(ofSize: 0)))
      menu.insertItem(item, at: menu.index(of: separator) + 1)

      item.addAction { [weak self] in
        NSPasteboard.general.string = text
        self?.increaseUserClickCount()
      }

      if item.title != text {
        item.toolTip = text
      }
    }
  }

  func presentMainMenu() {
    let location: CGPoint = {
      if #available(macOS 26.0, *) {
        return CGPoint(x: -8, y: 0)
      }

      return CGPoint(x: -8, y: (statusItem.button?.frame.height ?? 0) + 4)
    }()

    mainMenu.appearance = NSApp.effectiveAppearance
    mainMenu.popUp(positioning: nil, at: location, in: statusItem.button)
  }
}
