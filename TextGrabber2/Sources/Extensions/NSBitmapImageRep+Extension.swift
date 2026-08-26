//
//  NSBitmapImageRep+Extension.swift
//  TextGrabber2
//
//  Created by cyan on 2026/8/26.
//

import AppKit

extension NSBitmapImageRep {
  var isRetina: Bool {
    Int(size.width * 2) == pixelsWide
  }
}
