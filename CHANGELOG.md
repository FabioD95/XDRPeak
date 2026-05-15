# Changelog

All notable changes to XDRPeak are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - TBD

Initial public release.

### Added

- **Menu-bar app** with a sun-icon `NSStatusItem`, no Dock icon
  (`LSUIElement`).
- **Brightness boost toggle**: enables a 1×1 HDR pixel trigger that
  flips the main display into Extended Dynamic Range mode, then
  multiplies the gamma transfer table by a chip-aware factor (1.59
  on M1/M2, 1.535 on M3/M4/M5).
- **Global hotkeys** via Carbon `RegisterEventHotKey`, no Accessibility
  or Input Monitoring TCC prompt:
  - `⌘⇧B` — toggle the brightness boost.
  - `⌘⇧⌥B` — panic restore.
- **Menu item: Panic — Restore gamma now** — always-safe restore of the
  original color profile, callable from any state.
- **Pre-flight headroom poll** — waits until the display actually has
  EDR headroom before applying `factor > 1.0`, preventing the
  white-screen failure mode.
- **LUT watchdog** — re-applies the boosted gamma every 5 seconds to
  counter silent resets by Night Shift, True Tone, or screen-parameter
  changes that don't fire `didChangeScreenParametersNotification`.
- **Mandatory LUT restore** on toggle off, on panic, and on
  `applicationWillTerminate` — XDRPeak never leaves a boosted LUT
  behind on clean exit.
- **Chip detection** via `sysctl machdep.cpu.brand_string`, exposed as
  `GammaController.chipBrand` and `GammaController.defaultGammaFactor`.

### Requirements

- macOS 14 (Sonoma) or later.
- Apple Silicon Mac with an XDR-capable display (internal Liquid Retina
  XDR on MBP 14"/16" 2021+, Pro Display XDR, or Studio Display).

### Notes — explicit non-goals of this release

The following are intentionally out of scope for v1.0.0 and may land in
a future minor release based on user feedback:

- Multi-display support (only `NSScreen.main` is boosted).
- Auto-disable timer after N minutes of idle.
- Auto-disable on lid close.
- Quintuple-click panic gesture.
- User-preference persistence across app launches.
- Debug HUD overlay.
- App Store distribution (incompatible with the App Sandbox).

[Unreleased]: https://github.com/FabioD95/XDRPeak/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/FabioD95/XDRPeak/releases/tag/v1.0.0
