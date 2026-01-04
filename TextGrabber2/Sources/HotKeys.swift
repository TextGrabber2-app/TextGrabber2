//
//  HotKeys.swift
//  TextGrabber2
//
//  Created by cyan on 2025/12/28.
//

import Foundation
import Carbon.HIToolbox

@MainActor
enum HotKeys {
  static func register(keyEquivalent: String, modifiers: [String], handler: @escaping () -> Void) {
    guard let keyCode = keyCodes[keyEquivalent] else {
      return Logger.log(.error, "Failed to find keyCode for: \(keyEquivalent)")
    }

    register(keyCode: keyCode, modifiers: .init(stringValues: modifiers), handler: handler)
  }

  static func unregisterAll() {
    eventHotKeys.forEach {
      UnregisterEventHotKey($0.value)
    }

    eventHotKeys.removeAll()
    mappedHandlers.removeAll()
    hotKeyID = 0
  }
}

// MARK: - Private

private extension HotKeys {
  struct Modifiers: OptionSet {
    let rawValue: Int
    static let shift = Self(rawValue: shiftKey)
    static let control = Self(rawValue: controlKey)
    static let option = Self(rawValue: optionKey)
    static let command = Self(rawValue: cmdKey)

    init(rawValue: Int) {
      self.rawValue = rawValue
    }

    fileprivate init(stringValues: [String]) {
      let mapping = [
        "Shift": shiftKey,
        "Control": controlKey,
        "Option": optionKey,
        "Command": cmdKey,
      ]

      self.rawValue = ({
        var modifiers: Self = []
        stringValues.forEach {
          if let rawValue = mapping[$0] {
            modifiers.insert(Self(rawValue: rawValue))
          } else {
            Logger.log(.error, "Invalid modifier was found: \($0)")
          }
        }

        return modifiers.rawValue
      })()
    }
  }

  static func register(keyCode: UInt32, modifiers: Modifiers, handler: @escaping () -> Void) {
    let hotKeyString = hotKeyString(
      for: keyCode,
      modifiers: modifiers
    )

    if let usedHotKey = eventHotKeys[hotKeyString] {
      UnregisterEventHotKey(usedHotKey)
    }

    var eventHotKey: EventHotKeyRef?
    let registerError = RegisterEventHotKey(
      keyCode,
      UInt32(modifiers.rawValue),
      EventHotKeyID(signature: hotKeySignature, id: hotKeyID),
      GetEventDispatcherTarget(),
      0,
      &eventHotKey
    )

    if registerError != noErr {
      Logger.log(.error, "Failed to register hotKey: \(keyCode), \(modifiers)")
    }

    installEventHandler()
    eventHotKeys[hotKeyString] = eventHotKey
    mappedHandlers[hotKeyID] = handler
    hotKeyID += 1
  }

  static func installEventHandler() {
    guard eventHandler == nil, let target = GetEventDispatcherTarget() else {
      return
    }

    let eventTypes = [
      EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: UInt32(kEventHotKeyPressed)
      ),
    ]

    let installError = InstallEventHandler(
      target,
      { _, event, _ in handleEvent(event) },
      eventTypes.count,
      eventTypes,
      nil,
      &eventHandler
    )

    if installError != noErr {
      Logger.log(.error, "Failed to install event handler for hotKey")
    }
  }
}

@MainActor private var eventHotKeys = [String: EventHotKeyRef]()
@MainActor private var eventHandler: EventHandlerRef?
@MainActor private var hotKeyID = UInt32(0)
@MainActor private var mappedHandlers = [UInt32: () -> Void]()

@MainActor
private func hotKeyString(for code: UInt32, modifiers: HotKeys.Modifiers) -> String {
  "\(code)-\(modifiers)"
}

@MainActor
private func handleEvent(_ event: EventRef?) -> OSStatus {
  guard let event, Int(GetEventKind(event)) == kEventHotKeyPressed else {
    Logger.log(.error, "Event \(String(describing: event)) not handled")
    return OSStatus(eventNotHandledErr)
  }

  var eventHotKeyId = EventHotKeyID()
  let error = GetEventParameter(
    event,
    UInt32(kEventParamDirectObject),
    UInt32(typeEventHotKeyID),
    nil,
    MemoryLayout<EventHotKeyID>.size,
    nil,
    &eventHotKeyId
  )

  guard error == noErr, eventHotKeyId.signature == hotKeySignature else {
    Logger.log(.error, "Failed to validate the event")
    return error
  }

  guard let handler = mappedHandlers[eventHotKeyId.id] else {
    Logger.log(.error, "Failed to get the event handler")
    return OSStatus(eventNotHandledErr)
  }

  handler()
  return noErr
}

// OSType of "TGHK" (TextGrabber2 HotKey)
private let hotKeySignature: UInt32 = 1413957707
