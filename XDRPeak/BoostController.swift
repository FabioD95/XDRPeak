// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import Cocoa

/// Core state machine for the brightness boost.
///
/// Coordinates the EDR pixel trigger, the gamma controller, and the LUT
/// watchdog so the rest of the app only deals with `enable()` / `disable()`
/// / `panic()`. State transitions are exposed through `onStateChange` so the
/// menu bar UI can react without polling.
///
/// v1.0.0 is single-display by design (uses `NSScreen.main` if it's XDR-capable).
/// See DECISIONS §18.
final class BoostController {

    // MARK: - State

    enum State: Equatable {
        case off
        case engaging    // EDR trigger up, waiting for headroom to engage
        case boosting    // gamma applied
    }

    private(set) var state: State = .off {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?
    var isOn: Bool { state != .off }

    // MARK: - Components

    private var trigger: HDRPixelTrigger?
    private let gamma = GammaController()
    private lazy var watchdog = LUTWatchdog { [weak self] in self?.reapplyBoost() }

    private let gammaFactor: Float = GammaController.defaultGammaFactor

    private static let readyPollInterval: TimeInterval = 0.2
    private static let readyMaxAttempts = 10
    private static let minHeadroomForBoost: Float = 1.05

    // MARK: - API

    /// Activate the EDR trigger, wait until the display has actual EDR headroom,
    /// then apply the gamma boost. No-op if no XDR-capable display is connected.
    func enable() {
        guard state == .off, let screen = xdrScreen() else { return }
        state = .engaging
        let trig = HDRPixelTrigger(screen: screen)
        trig.show()
        trigger = trig
        waitForHeadroomThenBoost(attempt: 0)
    }

    /// Restore the original LUT, tear down the EDR trigger, return to `.off`.
    func disable() {
        watchdog.stop()
        // Global restore covers every display in one call — safer than per-display
        // when we may have created LUT side-effects on internal vs external screens.
        CGDisplayRestoreColorSyncSettings()
        trigger?.close()
        trigger = nil
        state = .off
    }

    /// Emergency restore. Same effect as `disable()` but explicitly safe to call
    /// from any state, including transitional ones where internal flags may be
    /// out of sync with reality. Always-safe dead-man switch.
    func panic() {
        CGDisplayRestoreColorSyncSettings()
        watchdog.stop()
        trigger?.close()
        trigger = nil
        state = .off
    }

    func toggle() {
        if isOn { disable() } else { enable() }
    }

    // MARK: - Internals

    /// Returns the main screen iff it has EDR potential. Uses *potential* (a
    /// constant per-display capability) rather than *current* headroom, which
    /// is 1.0 when no HDR content is on screen and would create a chicken-and-egg
    /// loop preventing us from ever creating the trigger that raises it.
    private func xdrScreen() -> NSScreen? {
        guard let screen = NSScreen.main,
              screen.maximumPotentialExtendedDynamicRangeColorComponentValue > 1.0 else {
            return nil
        }
        return screen
    }

    /// Poll headroom until EDR mode has actually engaged, then apply the clamped
    /// gamma factor. Aborts after `readyMaxAttempts` (≈ 2 s) if EDR never engages
    /// (typically: display brightness too low). Never applies factor > 1.0 in SDR
    /// mode, which would produce a white-screen.
    private func waitForHeadroomThenBoost(attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.readyPollInterval) { [weak self] in
            guard let self, self.state == .engaging else { return }

            let headroom = currentHeadroom()

            if headroom >= Self.minHeadroomForBoost {
                let safeFactor = min(self.gammaFactor, headroom)
                self.gamma.apply(factor: safeFactor)
                self.state = .boosting
                self.watchdog.start()
                return
            }

            if attempt + 1 >= Self.readyMaxAttempts {
                NSLog("XDRPeak: EDR never engaged after %d attempts (headroom=%.3f), aborting",
                      Self.readyMaxAttempts, headroom)
                self.disable()
                return
            }

            self.waitForHeadroomThenBoost(attempt: attempt + 1)
        }
    }

    /// Watchdog tick. Re-applies the clamped gamma factor against the *current*
    /// headroom (which can drop between ticks if brightness is lowered).
    private func reapplyBoost() {
        guard state == .boosting else { return }
        let headroom = max(currentHeadroom(), 1.0)
        let safeFactor = min(gammaFactor, headroom)
        gamma.apply(factor: safeFactor)
    }

    private func currentHeadroom() -> Float {
        NSScreen.main.map { Float($0.maximumExtendedDynamicRangeColorComponentValue) } ?? 0
    }
}
