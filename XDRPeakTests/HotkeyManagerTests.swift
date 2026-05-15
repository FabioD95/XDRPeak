// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import XCTest
@testable import XDRPeak

final class HotkeyManagerTests: XCTestCase {

    func test_unregisterWithoutRegister_doesNotCrash() {
        let mgr = HotkeyManager(onToggle: {}, onPanic: {})
        mgr.unregister()
    }

    func test_registerThenUnregister_doesNotCrash() {
        let mgr = HotkeyManager(onToggle: {}, onPanic: {})
        mgr.register()
        mgr.unregister()
    }

    func test_doubleUnregister_isIdempotent() {
        let mgr = HotkeyManager(onToggle: {}, onPanic: {})
        mgr.register()
        mgr.unregister()
        mgr.unregister()
    }

    func test_deinit_isClean() {
        // Wrap in an autoreleasepool so we can deterministically observe deinit
        // (which calls unregister() on its own). Just verifies no crash happens
        // when an instance is dropped without manual cleanup.
        autoreleasepool {
            let mgr = HotkeyManager(onToggle: {}, onPanic: {})
            mgr.register()
            _ = mgr
        }
    }
}
