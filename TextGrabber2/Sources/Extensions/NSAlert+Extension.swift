//
//  NSAlert+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2024/5/1.
//

import AppKit

extension NSAlert {
  /**
   Drop-in replacement for `informativeText` with Markdown support.
   */
  var markdownBody: String? {
    get {
      objc_getAssociatedObject(self, &AssociatedObjects.markdownBody) as? String
    }
    set {
      objc_setAssociatedObject(
        self,
        &AssociatedObjects.markdownBody,
        newValue,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )

      updateAccessoryView(with: newValue ?? "")
    }
  }

  static func runModal(message: String, style: Style = .critical) {
    NSApp.activate()

    let alert = Self()
    alert.alertStyle = style
    alert.messageText = message
    alert.runModal()
  }
}

// MARK: - Private

private extension NSAlert {
  private enum AssociatedObjects {
    @MainActor static var markdownBody: UInt8 = 0
  }

  private enum Constants {
    static let fontSize: Double = 11
    static let contentWidth: Double = 220
    static let contentPadding: Double = 10
  }

  func updateAccessoryView(with markdown: String) {
    let textView = NSTextView()
    textView.font = .systemFont(ofSize: Constants.fontSize)
    textView.drawsBackground = false
    textView.isEditable = false

    if let data = markdown.data(using: .utf8), let string = try? NSAttributedString(markdown: data, options: .init(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
      textView.textStorage?.setAttributedString(string)
    } else {
      textView.string = markdown
    }

    textView.textStorage?.addAttribute(
      .foregroundColor,
      value: NSColor.labelColor,
      range: NSRange(location: 0, length: textView.attributedString().length)
    )

    let contentSize = CGSize(width: Constants.contentWidth, height: 0)
    textView.frame = CGRect(origin: CGPoint(x: Constants.contentPadding, y: 0), size: contentSize)
    textView.sizeToFit()

    let wrapper = NSView(frame: textView.frame.insetBy(dx: -Constants.contentPadding, dy: 0))
    wrapper.addSubview(textView)
    accessoryView = wrapper
    layout()
  }
}
