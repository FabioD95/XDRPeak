// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import XCTest
@testable import XDRPeak

final class GammaControllerTests: XCTestCase {

    func test_chipBrand_returnsNonEmptyString() {
        let brand = GammaController.chipBrand
        XCTAssertFalse(brand.isEmpty)
    }

    func test_defaultGammaFactor_isInExpectedRange() {
        let factor = GammaController.defaultGammaFactor
        XCTAssertGreaterThan(factor, 1.5)
        XCTAssertLessThan(factor, 1.6)
    }

    func test_defaultGammaFactor_matchesChipFamily() {
        let brand = GammaController.chipBrand
        let factor = GammaController.defaultGammaFactor
        if brand.contains("Apple M3") || brand.contains("Apple M4") || brand.contains("Apple M5") {
            XCTAssertEqual(factor, 1.535, accuracy: 0.001)
        } else {
            XCTAssertEqual(factor, 1.59, accuracy: 0.001)
        }
    }

    func test_applyAndRestore_doesNotCrash() {
        let controller = GammaController()
        controller.apply(factor: 1.0) // identity, visually a no-op
        controller.restoreOriginalTable()
        // Belt-and-suspenders cleanup so the test exit doesn't leave a touched LUT.
        CGDisplayRestoreColorSyncSettings()
    }
}
