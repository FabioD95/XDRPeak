// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import Foundation

/// Periodically re-applies the boosted LUT to counter silent resets by
/// Night Shift, True Tone, or other macOS color policies that do not fire
/// `didChangeScreenParametersNotification`.
final class LUTWatchdog {

    private var timer: Timer?
    private let interval: TimeInterval
    private let onTick: () -> Void

    init(interval: TimeInterval = 5.0, onTick: @escaping () -> Void) {
        self.interval = interval
        self.onTick = onTick
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.onTick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit { stop() }
}
