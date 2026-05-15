# Security Policy

## Reporting a vulnerability

If you believe you've found a security vulnerability in XDRPeak,
**please do not open a public GitHub issue.** Instead, email the
maintainer privately at:

**fabio.delrio95@gmail.com**

Include:

- A clear description of the issue.
- Steps to reproduce, if known.
- The version of XDRPeak and your macOS version.
- (Optional) A proof-of-concept, in whatever form is convenient.

You can expect:

- An acknowledgement within **7 days**.
- A first assessment (confirmed / not a vulnerability / need more info)
  within **14 days**.
- A fix or a status update at least every **30 days** while the issue
  is open.

Once a fix is published, you'll be credited in the release notes
unless you'd prefer to stay anonymous.

---

## Scope

XDRPeak's attack surface is small because the app:

- Has no network code.
- Does not bundle external dependencies (only Apple frameworks).
- Is not sandboxed but does not request elevated privileges.
- Does not handle user data, files, or credentials.

The realistic risks in scope:

- **Privilege issues** in how the app interacts with display gamma APIs
  (although these APIs do not require elevated privileges in macOS).
- **Code-signing / notarization** issues that could let a tampered build
  be confused with an official one.
- **Supply-chain issues** in the build / release pipeline (the GitHub
  Actions release workflow that produces the notarized `.dmg`).

The following are explicitly **out of scope** because they aren't really
security issues:

- "Brightness boost doesn't engage on display X" — that's a bug, please
  open a regular issue.
- "I closed the lid and the LUT wasn't restored" — same.
- Anything that requires a malicious actor to already have local root
  on your Mac. If they do, they don't need XDRPeak.

---

## Supported versions

| Version | Supported |
|---------|-----------|
| latest released | yes |
| previous patch (e.g. 1.0.x for 1.0.y) | best-effort |
| anything older | no |

This is a small project. Only the latest release receives security
fixes guaranteed.

---

## Public disclosure

Once a fix is released, the vulnerability will be disclosed in the
release notes and `CHANGELOG.md` after a reasonable grace period
(typically 30 days from the fix being available, sooner if the issue
is already public).
