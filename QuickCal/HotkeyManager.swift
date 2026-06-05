import Carbon
import AppKit

final class HotkeyManager {
    var onActivate: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private static var registry: [UInt32: HotkeyManager] = [:]

    func register(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        unregister()
        HotkeyManager.registry[id] = self

        let hotKeyID = EventHotKeyID(signature: OSType(0x514B_4353), id: id)  // 'QKCS'
        let handlerUPP: EventHandlerUPP = { _, event, _ in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            HotkeyManager.registry[hkID.id]?.onActivate?()
            return noErr
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), handlerUPP, 1, &eventType,
                            nil, &eventHandler)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let ref = eventHandler { RemoveEventHandler(ref); eventHandler = nil }
    }

    deinit { unregister() }
}
