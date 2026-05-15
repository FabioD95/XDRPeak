# XDRPeak

> Peak XDR brightness for your Mac display.
> Push your XDR display past its 100-nit SDR ceiling into the full peak
> brightness range — up to ~1600 nits on supported Macs, in any workflow,
> not just HDR video playback.

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%20Sonoma%2B-black.svg)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-required-orange.svg)](https://support.apple.com/en-us/HT211814)

<details>
<summary><b>Table of contents</b></summary>

- [Features](#-features)
- [Quick Start](#-quick-start)
- [How it works](#-how-it-works)
- [Build from source](#%EF%B8%8F-build-from-source)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgements](#acknowledgements)

</details>

---

## ✨ Features

- **One-click peak brightness.** Toggle from the menu bar or with `⌘⇧B`
  and your display jumps from ~500-nit SDR to ~1600-nit peak XDR.
- **System-wide.** Works in any app — Safari, Mail, Xcode, Figma. Not
  limited to HDR video playback.
- **Public macOS APIs only.** No private framework hacks. The technique
  doesn't break across macOS updates.
- **Safe by default.** A `Panic: Restore gamma now` menu item and the
  `⌘⇧⌥B` hotkey always reset your display to the original color profile.
  Quitting the app or `applicationWillTerminate` also restores the LUT.
- **Resists Night Shift and True Tone.** A 5-second watchdog re-applies
  the boost when macOS silently resets the gamma table.
- **Chip-aware.** Auto-picks a safe boost factor: 1.59 on M1/M2,
  1.535 on M3/M4/M5.
- **Light-touch.** Menu-bar utility with no Dock icon, no main window.
  Quits cleanly, leaves no daemon, no login item.

---

## 🚀 Quick Start

> **Pre-built binary** — coming with the v1.0.0 release. Watch this repo
> or check the [Releases page](https://github.com/FabioD95/XDRPeak/releases).

In the meantime, [build from source](#%EF%B8%8F-build-from-source).

After install:

1. Launch XDRPeak. A sun icon appears in your menu bar.
2. Hit `⌘⇧B` or click the icon → **Bright Boost: On**.
3. Look at the display. Whites are now in the peak XDR range.
4. Hit `⌘⇧B` again or quit the app to return to normal SDR.

If the display brightness slider is very low, macOS won't allow EDR mode
and XDRPeak will silently abort. Raise the brightness and try again.

---

## 🧠 How it works

XDRPeak coordinates two public macOS APIs:

1. A 1×1 invisible HDR pixel rendered with Metal flips the display into
   **EDR (Extended Dynamic Range)** mode, unlocking the headroom above
   the standard 100-nit SDR ceiling.
2. The display's gamma transfer table is multiplied by a modest factor
   (1.59 or 1.535 depending on the chip) via `CGSetDisplayTransferByTable`.
   With EDR mode active, output values above 1.0 are now rendered into
   the unlocked headroom — every pixel on screen is lifted.

A pre-flight headroom poll prevents applying gamma > 1.0 before EDR has
engaged (which would otherwise saturate everything to white). A 5-second
watchdog re-applies the boost to counter silent LUT resets by Night
Shift, True Tone, and screen-parameter changes.

For the full technical write-up — state machine, components, design
decisions, limitations — see [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## 🛠️ Build from source

**Requirements**

- macOS 14 Sonoma or later
- Xcode 15 or later
- Apple Silicon Mac with an XDR-capable display (internal Liquid Retina XDR
  on MBP 14"/16" 2021+, Pro Display XDR, or Studio Display)

**Steps**

```bash
git clone https://github.com/FabioD95/XDRPeak.git
cd XDRPeak
open XDRPeak.xcodeproj
```

In Xcode: select the **XDRPeak** scheme, then `⌘R` to build and run.
The first run will prompt to sign with your local Apple ID — that's
normal for unsigned development builds.

Or from the command line:

```bash
xcodebuild -project XDRPeak.xcodeproj -scheme XDRPeak -configuration Release build
```

**Run the tests**

```bash
xcodebuild -project XDRPeak.xcodeproj -scheme XDRPeak \
  -destination 'platform=macOS' test
```

---

## 🤝 Contributing

Bug reports, feature ideas, and pull requests are welcome.

Before opening a PR, please:

- Run `xcodebuild test` and make sure all tests pass.
- Stick to **public Apple APIs only** — no `DisplayServicesSetBrightness`
  or similar private framework calls.
- If you touch the gamma pipeline, make sure
  `CGDisplayRestoreColorSyncSettings()` still runs on `disable`, `panic`,
  and `applicationWillTerminate`. Leaving a boosted LUT behind is the
  single most important regression to avoid.

A `CONTRIBUTING.md` with full guidelines is on the way. For now, opening
a discussion or draft PR is fine.

---

## 📜 License

XDRPeak is licensed under **GPL-3.0-or-later**. See [`LICENSE`](LICENSE)
for the full text.

The GPL is "viral": any derivative work must also be licensed under
GPL-3.0. This is inherited from [starkdmi/BrightXDR](https://github.com/starkdmi/BrightXDR)
and is not negotiable for this project.

---

## Acknowledgements

XDRPeak builds on the work of several open-source projects that pioneered
the techniques used here. None of their code is bundled or redistributed
— the techniques are independently re-implemented, the credits below
are intellectual attribution. See [`NOTICE`](NOTICE) for the full text.

- **[starkdmi/BrightXDR](https://github.com/starkdmi/BrightXDR)** —
  the menu-bar utility model and the GPL-3.0 inheritance.
- **[niklasr22/BrightIntosh](https://github.com/niklasr22/BrightIntosh)** —
  the 1×1 HDR pixel trigger, per-chip gamma factors, and EDR clear-color
  formula.
- **[alin23/Lunar](https://github.com/alin23/Lunar)** — the EDR headroom
  analysis behind the pre-flight poll that prevents the all-white-screen
  failure mode.

---

Made by [Fabio Del Rio](https://github.com/FabioD95). Questions, bug
reports, or just want to say hi? Open an issue or email
`fabio.delrio95@gmail.com`.
