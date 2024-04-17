//
//  Unchecked.swift
//  TextGrabber2
//
//  Created by cyan on 2024/4/17.
//

import AppKit
import os.log

extension NSMenuItem: @unchecked Sendable {}
extension os.Logger: @unchecked Sendable {}
