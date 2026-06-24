import Carbon
import Foundation
import GlyphpadCore

final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var activeHotKeyID: UInt32 = 0
    private var nextHotKeyID: UInt32 = 1
    private let action: @Sendable () -> Void

    init(action: @escaping @Sendable () -> Void) {
        self.action = action
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func register(_ hotKey: LauncherHotKey) {
        guard installHandlerIfNeeded() else {
            return
        }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: nextHotKeyID)
        var newHotKeyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            UInt32(hotKey.keyCode),
            hotKey.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &newHotKeyRef
        )
        if registerStatus != noErr {
            NSLog("Failed to register Glyphpad global hot key: \(registerStatus) keyCode=\(hotKey.keyCode) modifiers=\(hotKey.carbonModifiers)")
            return
        }

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = newHotKeyRef
        activeHotKeyID = hotKeyID.id
        nextHotKeyID = nextHotKeyID == UInt32.max ? 1 : nextHotKeyID + 1
        if nextHotKeyID == activeHotKeyID {
            nextHotKeyID = nextHotKeyID == UInt32.max ? 1 : nextHotKeyID + 1
        }
    }

    private func installHandlerIfNeeded() -> Bool {
        if eventHandlerRef != nil {
            return true
        }

        let eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard let userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                guard result == noErr, hotKeyID.id == manager.activeHotKeyID else {
                    return noErr
                }

                manager.action()
                return noErr
            },
            1,
            [eventType],
            userData,
            &eventHandlerRef
        )
        guard installStatus == noErr else {
            NSLog("Failed to install Glyphpad hot key handler: \(installStatus)")
            return false
        }

        return true
    }

    private static let signature: OSType = {
        var result: OSType = 0
        for scalar in "GLYP".unicodeScalars {
            result = (result << 8) + OSType(scalar.value)
        }
        return result
    }()
}
