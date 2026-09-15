---
applyTo: "Sources/**/*.swift,Tests/**/*.swift"
---

- Preserve the local-first privacy boundary and the explicit v1 wire allowlist.
- Keep UI state on `@MainActor`; run Automation scripts and network work without blocking the UI.
- New collectors must be optional, bounded by a timeout, and covered by a focused failure-path test where practical.
- Test domain boundaries, debounce timing, explicit null encoding, and stable activity start times when those behaviors change.
- Avoid third-party runtime dependencies unless the maintenance and privacy costs are justified in the pull request.
