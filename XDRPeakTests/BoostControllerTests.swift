// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import XCTest
@testable import XDRPeak

final class BoostControllerTests: XCTestCase {

    func test_initialState_isOff() {
        let boost = BoostController()
        XCTAssertEqual(boost.state, .off)
        XCTAssertFalse(boost.isOn)
    }

    func test_panic_fromOff_endsInOff() {
        let boost = BoostController()
        boost.panic()
        XCTAssertEqual(boost.state, .off)
        XCTAssertFalse(boost.isOn)
    }

    func test_disable_fromOff_endsInOff() {
        let boost = BoostController()
        boost.disable()
        XCTAssertEqual(boost.state, .off)
    }

    func test_panic_isAlwaysSafe() {
        // panic() must be callable repeatedly without crashing, regardless of
        // current state. Three consecutive calls should leave us in .off.
        let boost = BoostController()
        boost.panic()
        boost.panic()
        boost.panic()
        XCTAssertEqual(boost.state, .off)
    }

    func test_stateChangeCallback_firesWhenStateAssigned() {
        // didSet triggers on every assignment, even when the value is unchanged.
        // panic() always assigns state = .off → callback must fire.
        let boost = BoostController()
        var observed: [BoostController.State] = []
        boost.onStateChange = { observed.append($0) }
        boost.panic()
        XCTAssertEqual(observed.last, .off)
        XCTAssertFalse(observed.isEmpty)
    }

    func test_toggleOnSDRDisplay_eventuallySettlesOff() {
        // On a non-XDR display (CI runner, SDR monitor), enable() may briefly
        // enter .engaging but never gains headroom, and the poll loop aborts
        // back to .off. Either way, calling panic() after must settle in .off.
        let boost = BoostController()
        boost.toggle() // attempt enable
        boost.panic()  // always-safe reset
        XCTAssertEqual(boost.state, .off)
        XCTAssertFalse(boost.isOn)
    }
}
