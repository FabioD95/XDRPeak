<!--
Thanks for the contribution! Before submitting, please read CONTRIBUTING.md.
-->

## What this PR does

<!-- One or two sentences. What changed and why. -->

## How it was tested

<!-- Real hardware? CI only? Specific display / chip? -->

## Checklist

- [ ] `xcodebuild -project XDRPeak.xcodeproj -scheme XDRPeak -destination 'platform=macOS' test` passes locally.
- [ ] No private Apple APIs were introduced (`DisplayServicesSetBrightness` and friends are off-limits — see CONTRIBUTING.md).
- [ ] If this change touches the boost pipeline, `CGDisplayRestoreColorSyncSettings()` still runs on **disable**, **panic**, and **applicationWillTerminate**.
- [ ] If this change is user-visible, `CHANGELOG.md` has been updated under `[Unreleased]`.
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`).
