# Architecture

This document describes how XDRPeak pushes an Apple display past its
100-nit SDR ceiling into the EDR range that Apple already supports for
HDR video, without any private API and without a full-screen overlay.

If you only want to **use** the app, see [`README.md`](README.md). If you
want to **understand or modify** it, you're in the right place.

---

## Overview

XDRPeak is a macOS menu-bar utility (no Dock icon, no main window) that
unlocks the full peak brightness of an Apple XDR display (~1600 nits on
the internal display of MacBook Pro 14"/16", Pro Display XDR, and Studio
Display).

It does so in **two coordinated steps**:

1. **EDR trigger** — render a single 1×1 HDR pixel. macOS sees HDR content
   on screen and flips the display into Extended Dynamic Range mode,
   which unlocks the headroom above the SDR ceiling.
2. **Gamma boost** — multiply the display's gamma transfer table by a
   modest factor (1.59 on M1/M2 chips, 1.535 on M3+). With EDR mode now
   active, output values above 1.0 are rendered above 100 nits instead
   of being clamped, so everything on screen — Safari, Mail, Xcode — is
   lifted into the peak brightness range.

Step 2 alone produces a white screen (gamma > 1.0 clamps to white when
EDR is not engaged). Step 1 alone unlocks the headroom but nothing on
screen exercises it. Both are required.

---

## Components

```
XDRPeak/
├── main.swift                # NSApplication + AppDelegate hookup
├── AppDelegate.swift         # Lifecycle. Guarantees gamma restore on quit.
├── BoostController.swift     # State machine. Owns the pipeline below.
│
├── HDRPixelTrigger.swift     # 1×1 MTKView, extendedLinearSRGB clear color.
├── GammaController.swift     # CGSetDisplayTransferByTable + chip detection.
├── LUTWatchdog.swift         # 5-second timer that re-applies the boost.
│
├── MenuBarController.swift   # NSStatusItem + menu. Observes BoostController.
└── HotkeyManager.swift       # Carbon RegisterEventHotKey for ⌘⇧B / ⌘⇧⌥B.
```

Each file has a single responsibility:

| File | Responsibility |
|---|---|
| `BoostController` | Owns `state ∈ {off, engaging, boosting}`. Sole entry points for the rest of the app are `enable()`, `disable()`, `panic()`, `toggle()`. Emits `onStateChange` callbacks. |
| `HDRPixelTrigger` | Creates a borderless 1×1 transparent `NSWindow` containing an `MTKView` configured with `extendedLinearSRGB` and `rgba16Float`. The clear color is computed from the screen's actual EDR capability. |
| `GammaController` | Captures the original gamma LUT on init. `apply(factor:)` multiplies each channel of the captured table and writes it back via `CGSetDisplayTransferByTable`. Exposes `chipBrand` and the per-chip safe `defaultGammaFactor`. |
| `LUTWatchdog` | A `Timer` wrapper that re-fires `onTick` every 5 seconds while running. Used by `BoostController` to counter silent LUT resets. |
| `MenuBarController` | Owns the `NSStatusItem`. Subscribes to `BoostController.onStateChange` so the icon and menu titles stay in sync without polling. |
| `HotkeyManager` | Registers two global hotkeys via Carbon (no Accessibility / Input Monitoring TCC prompt) and dispatches to the supplied callbacks. |

---

## Data flow

```mermaid
flowchart TB
    user[User] -->|⌘⇧B / menu click| hotkey[HotkeyManager]
    hotkey -->|toggle()| boost
    user -->|⌘⇧⌥B / Panic menu| hotkey
    hotkey -->|panic()| boost

    subgraph core[BoostController state machine]
        boost{state}
        boost -->|.off → .engaging| trigger
        trigger[HDRPixelTrigger.show] -->|display flips to EDR| poll{headroom poll}
        poll -->|headroom ≥ 1.05| gammaApply[GammaController.apply]
        poll -->|10 attempts, no headroom| abort[disable]
        gammaApply -->|.engaging → .boosting| watchdog
        watchdog[LUTWatchdog start] -.->|tick every 5s| gammaApply
    end

    boost -->|.boosting → .off| restore[CGDisplayRestoreColorSyncSettings]
    restore --> trigger_close[HDRPixelTrigger.close]

    boost -->|state change| menu[MenuBarController]
    menu -->|update icon + title| user

    app_quit[applicationWillTerminate] -->|disable| boost
```

In words:

1. **Toggle on** (user clicks menu or hits ⌘⇧B). `BoostController.enable()`
   transitions to `.engaging`, places the 1×1 HDR pixel, and starts a
   200 ms polling loop on `maximumExtendedDynamicRangeColorComponentValue`.
2. As soon as headroom reaches ≥ 1.05, the boost factor is clamped to
   `min(defaultGammaFactor, headroom)` and applied to the gamma LUT.
   State moves to `.boosting` and the LUT watchdog starts.
3. If headroom never appears (e.g. brightness slider too low to give the
   display any EDR room), the controller aborts after 10 attempts and
   returns to `.off` — never applies gamma > 1.0 in SDR mode, never
   produces a white screen.
4. While `.boosting`, the watchdog re-applies the clamped factor every
   5 s. Night Shift, True Tone, and screen-parameter changes can silently
   reset the LUT without firing a notification; re-applying keeps the
   boost visible.
5. **Toggle off** or **Panic**: `CGDisplayRestoreColorSyncSettings()`
   restores the LUT, the 1×1 trigger is closed, watchdog stops, state
   returns to `.off`.
6. On `applicationWillTerminate`, the same teardown runs.
   `CGDisplayRestoreColorSyncSettings()` is mandatory: leaving a boosted
   LUT behind would persist past app exit and across logout, until
   another app resets the gamma.

---

## Key design decisions

### Public APIs only

No private framework calls. The two load-bearing APIs are:

- `CGSetDisplayTransferByTable` — gamma LUT manipulation. Stable since
  macOS 10.4, public, never deprecated.
- `CAMetalLayer.wantsExtendedDynamicRangeContent` + `rgba16Float` —
  Apple's documented EDR pipeline.

Private APIs like `DisplayServicesSetBrightness` break on every major
macOS release. We avoid them on principle and as a long-term stability
guarantee.

### Mandatory LUT restore

`CGDisplayRestoreColorSyncSettings()` runs in three places:

- `BoostController.disable()` (normal toggle off)
- `BoostController.panic()` (always-safe dead-man switch)
- `AppDelegate.applicationWillTerminate` (Cmd-Q, logout, kill)

Skipping this leaves the user staring at a permanently boosted display
until another process touches the gamma. This is the single most
important invariant in the codebase.

### EDR trigger before gamma — always

`enable()` always raises the trigger first, polls headroom, then applies
gamma. Applying gamma > 1.0 to a display that hasn't switched to EDR
mode saturates every output value > `1.0 / factor` to white. The
pre-flight poll prevents this failure mode deterministically — no
fixed-delay `asyncAfter`, no race between "EDR engaging" and "gamma
applied."

### Single display

v1.0.0 targets `NSScreen.main`. If the main display is not XDR-capable
(`maximumPotentialExtendedDynamicRangeColorComponentValue ≤ 1.0`),
`enable()` is a graceful no-op — the controller stays in `.off`. Multi-
display support is on the roadmap for v1.1+.

### No sandbox

The macOS App Sandbox is disabled in the entitlements file. Sandbox
forbids `CGSetDisplayTransferByTable`, so a sandboxed build would not
work. This is the same reason XDRPeak is not on the Mac App Store —
not a deliberate choice against it, just an Apple platform constraint.

### Chip-aware gamma factor

`GammaController.defaultGammaFactor` reads `machdep.cpu.brand_string`
via `sysctl` and picks:

- **1.59** on M1, M2, and any unknown/older chip (BrightIntosh reference
  value)
- **1.535** on M3, M4, M5

M3+ chips have a brighter ~600-nit SDR baseline and less proportional
EDR headroom, so they need a slightly lower factor to land in the same
absolute peak range without saturating.

---

## Limitations

XDRPeak is intentionally minimal. The following are explicit non-goals
of the v1.0.0 release; some may land in v1.1+ if demand justifies them.

- **Single display only.** External XDR monitors connected next to the
  main display are not boosted in v1.0.0.
- **No auto-disable timer.** The boost stays on until you toggle it off
  or quit the app. (v1.0.0 omits the 60-min idle disable.)
- **No lid-close auto-disable.** Closing the MacBook lid puts the
  display to sleep but does not pre-emptively disable the boost.
- **No multi-click panic gesture.** Panic is via the menu item or the
  ⌘⇧⌥B hotkey only.
- **No persistence.** The boost state is not restored across app
  launches; you start each session in `.off`.
- **No App Store distribution.** Sandbox would forbid gamma table
  access. Builds are distributed as a notarized `.dmg` via GitHub
  Releases.

If a power-loss / kernel-panic occurs while boosted, the LUT will be
left in its boosted state until another graphics-policy event (sleep/
wake, display reconfig, another app's color management) clears it.
Quitting XDRPeak normally avoids this entirely.

---

## Requirements

- macOS 14 Sonoma or later (build target).
- Apple Silicon with an XDR-capable display (internal Liquid Retina XDR
  on MBP 14"/16" 2021+, Pro Display XDR, Studio Display).
- Display brightness high enough that macOS reports EDR headroom > 1.05.
  At very low brightness levels the display refuses to enter EDR mode;
  raise the brightness slider first.
