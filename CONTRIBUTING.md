# Contributing to XDRPeak

Thanks for considering a contribution! Bug reports, feature ideas, and
pull requests are all welcome.

This is a small single-maintainer project, so don't be surprised if it
takes a few days to respond. Please be patient.

---

## Before you start

- For **non-trivial changes** (new features, refactoring, anything
  touching the gamma pipeline), open an issue or a discussion first to
  align on the approach. Saves both of us from wasted PRs.
- For **bug fixes** and **doc improvements**, just open the PR.
- For **security issues**, do **not** open a public issue. See
  [`SECURITY.md`](SECURITY.md).

---

## Development setup

**Requirements**

- macOS 14 Sonoma or later
- Xcode 15 or later
- Apple Silicon Mac with an XDR-capable display (internal Liquid Retina
  XDR on MBP 14"/16" 2021+, Pro Display XDR, or Studio Display) — for
  real-world testing. Most unit tests pass on any Mac.

**Build**

```bash
git clone https://github.com/FabioD95/XDRPeak.git
cd XDRPeak
open XDRPeak.xcodeproj
```

In Xcode: select the **XDRPeak** scheme, then `⌘R`. The first run will
prompt to sign with your local Apple ID — that's normal for unsigned
development builds.

Or from the command line:

```bash
xcodebuild -project XDRPeak.xcodeproj \
  -scheme XDRPeak -configuration Release build
```

**Run the tests**

```bash
xcodebuild -project XDRPeak.xcodeproj -scheme XDRPeak \
  -destination 'platform=macOS' test
```

All tests must pass before opening a PR. CI on `macos-14` runs the
same command on every pull request.

---

## Hard rules

These are not negotiable for any code change touching the boost
pipeline:

1. **Public Apple APIs only.** No `DisplayServicesSetBrightness`, no
   other private framework calls. They break on every major macOS
   release and the project's long-term stability depends on this rule.
2. **`CGDisplayRestoreColorSyncSettings()` must run on three paths:**
   - `BoostController.disable()` (normal toggle off)
   - `BoostController.panic()` (always-safe dead-man switch)
   - `AppDelegate.applicationWillTerminate` (Cmd-Q, logout, kill)
   Skipping any of these would leave a boosted gamma table active
   after the app exits, persisting across logout and reboot.
3. **Never apply `gamma > 1.0` before EDR mode has engaged.** Use the
   pre-flight headroom poll, or document explicitly why bypassing it
   is safe in your case. Applying gamma > 1.0 in SDR saturates
   everything > `1.0 / factor` to white.

---

## Code style

- **Swift API design guidelines**:
  https://www.swift.org/documentation/api-design-guidelines/
- Prefer `final class` over open inheritance unless there's a real
  reason to subclass.
- Default access (internal) is fine; export `public` only at module
  boundaries (the project has none yet — single target).
- Default to writing no comments. Add one only when the *why* is
  non-obvious: a hidden constraint, a subtle invariant, a workaround
  for a specific bug.
- Keep files small. The longest source file is currently `BoostController.swift`
  at ~120 lines; that's roughly the ceiling we're aiming for.
- Every `.swift` file must carry the SPDX GPL-3.0 header (5 lines).
  See any existing file for the exact format.

---

## Workflow for a pull request

1. Fork the repo and create a topic branch off `main`:
   ```bash
   git checkout -b fix-watchdog-leak
   ```
2. Make your change. Keep the commit history clean — squash WIP commits
   before pushing.
3. Run the tests and make sure the build is green:
   ```bash
   xcodebuild -project XDRPeak.xcodeproj -scheme XDRPeak \
     -destination 'platform=macOS' test
   ```
4. Update `CHANGELOG.md` under `[Unreleased]` if the change is
   user-visible.
5. Open the PR. Describe **what** changed, **why**, and **how you
   tested it** (especially on real hardware, since most of the
   interesting bugs only surface there).
6. Be patient — first review is usually within a week.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`. Use the
imperative mood ("add foo", not "added foo").

---

## What "out of scope" looks like

This release is intentionally minimal. The
[non-goals listed in `CHANGELOG.md`](CHANGELOG.md#notes--explicit-non-goals-of-this-release)
(multi-display, auto-disable, lid-close handling, persistence, debug
HUD, App Store distribution) are not refusals on principle — they're
work that hasn't been prioritized yet. If you want to land any of
them, please **open a discussion first** so we can agree on the design
before you write code.

---

## Questions

For anything that isn't a bug or a feature request, open a thread in
[Discussions](https://github.com/FabioD95/XDRPeak/discussions) instead
of an issue. Issues are reserved for actionable work.
