// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import Cocoa

/// Thin lifecycle layer. Wires together the boost controller, menu bar UI,
/// and global hotkeys, and guarantees the original gamma LUT is restored
/// on app termination.
final class AppDelegate: NSObject, NSApplicationDelegate {

    let boost = BoostController()
    private var menuBar: MenuBarController?
    private var hotkeys: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController(boost: boost)
        hotkeys = HotkeyManager(
            onToggle: { [weak self] in self?.boost.toggle() },
            onPanic: { [weak self] in self?.boost.panic() }
        )
        hotkeys?.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // CRITICAL: must restore the LUT before exit. Leaving a boosted LUT
        // behind would burn the display brightness across logout/reboot until
        // someone manually runs `CGDisplayRestoreColorSyncSettings`.
        // See CLAUDE.md §6.
        boost.disable()
    }
}
