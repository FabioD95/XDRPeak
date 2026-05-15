// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import Carbon.HIToolbox
import Cocoa

/// Registers global hotkeys via Carbon `RegisterEventHotKey`.
///
/// Two slots:
///   - ⌘⇧B   → toggle the brightness boost
///   - ⌘⇧⌥B  → panic restore
///
/// Carbon is used (vs `NSEvent.addGlobalMonitorForEvents`) because it does not
/// require Accessibility / Input Monitoring TCC permissions: the hotkeys work
/// out-of-the-box on first launch with no prompts.
final class HotkeyManager {

    private var handler: EventHandlerRef?
    private var toggleRef: EventHotKeyRef?
    private var panicRef: EventHotKeyRef?

    private let onToggle: () -> Void
    private let onPanic: () -> Void

    init(onToggle: @escaping () -> Void, onPanic: @escaping () -> Void) {
        self.onToggle = onToggle
        self.onPanic = onPanic
    }

    func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Pass self as the handler user data so the C callback can dispatch
        // back into the right instance.
        let context = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let event, let userData else { return noErr }
                var hotkeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )
                let mgr = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                switch hotkeyID.id {
                case 1: mgr.onToggle()
                case 2: mgr.onPanic()
                default: break
                }
                return noErr
            },
            1, &eventType, context, &handler
        )
        guard status == noErr else { return }

        let signature: OSType = 0x58445250 // "XDRP"

        RegisterEventHotKey(
            UInt32(kVK_ANSI_B),
            UInt32(cmdKey | shiftKey),
            EventHotKeyID(signature: signature, id: 1),
            GetApplicationEventTarget(),
            0,
            &toggleRef
        )

        RegisterEventHotKey(
            UInt32(kVK_ANSI_B),
            UInt32(cmdKey | shiftKey | optionKey),
            EventHotKeyID(signature: signature, id: 2),
            GetApplicationEventTarget(),
            0,
            &panicRef
        )
    }

    func unregister() {
        if let ref = toggleRef { UnregisterEventHotKey(ref); toggleRef = nil }
        if let ref = panicRef { UnregisterEventHotKey(ref); panicRef = nil }
        if let h = handler { RemoveEventHandler(h); handler = nil }
    }

    deinit { unregister() }
}
