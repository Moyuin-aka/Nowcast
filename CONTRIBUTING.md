# Contributing

Nowcast is a small macOS presence publisher. Keep collection local and output intentional.

- Swift 5.9+, macOS 13+. No third-party runtime dependencies.
- `swift test` checks domain boundaries, rules, debouncing and the wire format.
- `bash scripts/package.sh native` builds an app and DMG.
- Add application/domain mappings to `Configuration`; include a focused rule test.
- Never upload raw URLs, window titles, terminal commands, documents or browser history.
- New collectors must be optional, have a timeout, clear stale state on failure and explain permissions.
- Use a local receiver and synthetic data for debugging. Never commit production keys or personal config.
- Before a PR, test foreground switching, pause/resume, denied Automation permission, Music pause,
  sleep/wake and offline recovery. Include macOS version and screenshots for UI changes.

Useful next contributions: optional browser extension for playback state, configurable per-app icons,
  English UI, automated signed releases and a standalone receiver template.
