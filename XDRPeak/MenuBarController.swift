// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import Cocoa

/// Owns the menu bar status item and its menu.
///
/// Subscribes to `BoostController.onStateChange` so the icon and the boost
/// item title stay in sync without any polling.
final class MenuBarController {

    private let boost: BoostController
    private let statusItem: NSStatusItem
    private let boostItem: NSMenuItem

    init(boost: BoostController) {
        self.boost = boost
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        let menu = NSMenu(title: "XDRPeak")

        boostItem = NSMenuItem(
            title: "Bright Boost: Off (⌘⇧B)",
            action: nil,
            keyEquivalent: "b"
        )
        boostItem.keyEquivalentModifierMask = [.command, .shift]
        boostItem.toolTip = "Toggle the brightness boost."
        menu.addItem(boostItem)

        menu.addItem(NSMenuItem.separator())

        let panicItem = NSMenuItem(
            title: "Panic: Restore gamma now (⌘⇧⌥B)",
            action: nil,
            keyEquivalent: "b"
        )
        panicItem.keyEquivalentModifierMask = [.command, .shift, .option]
        panicItem.toolTip = "Force an immediate restore of the original gamma table."
        menu.addItem(panicItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem(
                title: "Quit XDRPeak",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        statusItem.menu = menu
        statusItem.button?.image = NSImage(
            systemSymbolName: "sun.max",
            accessibilityDescription: "XDRPeak"
        )

        // Wire actions after init so we can reference self.
        boostItem.target = self
        boostItem.action = #selector(boostAction)
        panicItem.target = self
        panicItem.action = #selector(panicAction)

        boost.onStateChange = { [weak self] state in
            self?.refresh(for: state)
        }
    }

    private func refresh(for state: BoostController.State) {
        let on = (state == .boosting)
        boostItem.title = on ? "Bright Boost: On (⌘⇧B)" : "Bright Boost: Off (⌘⇧B)"
        statusItem.button?.image = NSImage(
            systemSymbolName: on ? "sun.max.fill" : "sun.max",
            accessibilityDescription: "XDRPeak"
        )
    }

    @objc private func boostAction() {
        boost.toggle()
    }

    @objc private func panicAction() {
        boost.panic()
    }
}
