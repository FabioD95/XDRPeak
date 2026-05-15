// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import Cocoa
import Darwin

/// Controls a single display's gamma transfer table.
///
/// On init, captures the current LUT so it can be restored later. `apply(factor:)`
/// multiplies each channel of the captured LUT by the requested factor; values
/// > 1.0 land in the EDR range and are rendered above 100-nit SDR — but only when
/// EDR mode is already engaged on the display, otherwise they saturate to white.
final class GammaController {

    private let displayId: CGDirectDisplayID
    private let tableSize: UInt32 = 256

    private var originalRed: [CGGammaValue]
    private var originalGreen: [CGGammaValue]
    private var originalBlue: [CGGammaValue]

    init(displayId: CGDirectDisplayID = CGMainDisplayID()) {
        self.displayId = displayId
        self.originalRed = [CGGammaValue](repeating: 0, count: Int(tableSize))
        self.originalGreen = [CGGammaValue](repeating: 0, count: Int(tableSize))
        self.originalBlue = [CGGammaValue](repeating: 0, count: Int(tableSize))
        captureCurrentTable()
    }

    /// Apply a brightness multiplier to the captured original LUT.
    /// Pass `1.0` to write the original table back without going through restore().
    func apply(factor: Float) {
        var r = originalRed
        var g = originalGreen
        var b = originalBlue
        for i in 0..<Int(tableSize) {
            r[i] = originalRed[i] * factor
            g[i] = originalGreen[i] * factor
            b[i] = originalBlue[i] * factor
        }
        CGSetDisplayTransferByTable(displayId, tableSize, &r, &g, &b)
    }

    /// Write the captured original LUT back to this specific display.
    /// Unlike `CGDisplayRestoreColorSyncSettings()` (global), this touches
    /// only the display this controller owns.
    func restoreOriginalTable() {
        CGSetDisplayTransferByTable(
            displayId, tableSize,
            &originalRed, &originalGreen, &originalBlue
        )
    }

    private func captureCurrentTable() {
        var sampleCount: UInt32 = 0
        let result = CGGetDisplayTransferByTable(
            displayId, tableSize,
            &originalRed, &originalGreen, &originalBlue,
            &sampleCount
        )
        guard result == .success else {
            // Identity ramp fallback so apply(factor:) still does something sensible.
            for i in 0..<Int(tableSize) {
                let value = Float(i) / Float(tableSize - 1)
                originalRed[i] = value
                originalGreen[i] = value
                originalBlue[i] = value
            }
            return
        }
    }

    // MARK: - Chip detection

    /// Detected chip brand string (e.g. "Apple M1 Pro").
    static let chipBrand: String = {
        var size = 0
        let name = "machdep.cpu.brand_string"
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "unknown" }
        var buf = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buf, &size, nil, 0) == 0 else { return "unknown" }
        return String(cString: buf)
    }()

    /// Per-chip safe gamma factor. M3+ have ~600-nit SDR and less EDR headroom,
    /// so they get a lower factor. M1/M2 (and older/unknown) use the BrightIntosh
    /// reference value of 1.59.
    static let defaultGammaFactor: Float = {
        let brand = chipBrand
        if brand.contains("Apple M3") || brand.contains("Apple M4") || brand.contains("Apple M5") {
            return 1.535
        }
        return 1.59
    }()
}
