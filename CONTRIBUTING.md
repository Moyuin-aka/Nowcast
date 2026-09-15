# Contributing

Nowcast is a small macOS presence publisher. Keep collection local and output intentional.

- Swift 5.9+, macOS 13+. No third-party runtime dependencies.
- `swift test` checks domain boundaries, rules, debouncing and the wire format.
- `bash scripts/package.sh native` builds an app and DMG.
- `VERSION` is the canonical release version. A release tag must be exactly `v<version>`.
- Add application/domain mappings to `Configuration`; include a focused rule test.
- Never upload raw URLs, window titles, terminal commands, documents or browser history.
- New collectors must be optional, have a timeout, clear stale state on failure and explain permissions.
- Use a local receiver and synthetic data for debugging. Never commit production keys or personal config.
- Follow the boundary in `docs/integrations.md`; receiver code and host deployment state belong in the receiver's repository.
- Before a PR, test foreground switching, pause/resume, denied Automation permission, Music pause,
  sleep/wake and offline recovery. Include macOS version and screenshots for UI changes.

Pull requests use `.github/copilot-instructions.md` and path-specific review instructions. Complete the PR template so automated and human reviewers can distinguish verified behavior from toolchain blockers.

To publish a release, update `VERSION`, merge that change to `main`, then create and push the matching tag, for example `v0.2.0`. GitHub Actions verifies the tag/version pair, tests and packages the universal app, checks its metadata and checksum, and publishes the DMG to a GitHub Release.

Useful next contributions: optional browser extension for playback state, configurable per-app icons,
  English UI, automated notarized releases and local mock-receiver test tooling.
