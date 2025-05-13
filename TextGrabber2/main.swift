//
//  main.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/20.
//

import AppKit

NSWindow.swizzleSetFrameDisplayAnimateOnce
NSMenu.swizzleIsUpdatedExcludingContentTypesOnce

let app = NSApplication.shared
let delegate = App()

app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
