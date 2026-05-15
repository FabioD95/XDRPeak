// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import XCTest
@testable import XDRPeak

final class LUTWatchdogTests: XCTestCase {

    func test_startStop_doesNotCrash() {
        let watchdog = LUTWatchdog(interval: 0.05) {}
        watchdog.start()
        watchdog.stop()
    }

    func test_doubleStart_doesNotCrash() {
        // start() must replace any prior timer rather than leaking multiple.
        let watchdog = LUTWatchdog(interval: 1.0) {}
        watchdog.start()
        watchdog.start()
        watchdog.stop()
    }

    func test_stopWithoutStart_isIdempotent() {
        let watchdog = LUTWatchdog(interval: 1.0) {}
        watchdog.stop()
        watchdog.stop()
    }

    func test_tick_firesAfterInterval() {
        let tickFired = expectation(description: "watchdog tick fires")
        let watchdog = LUTWatchdog(interval: 0.05) {
            tickFired.fulfill()
        }
        watchdog.start()
        wait(for: [tickFired], timeout: 1.0)
        watchdog.stop()
    }
}
