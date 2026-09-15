# GitHub Copilot instructions

Nowcast is a provider-neutral macOS menu bar app that publishes a deliberately small description of the user's current activity to any receiver implementing the v1 protocol. Read `DEVELOPMENT.md` before changing code because the current snapshot still has unverified macOS behaviors.

## Non-negotiable privacy boundary

- Keep raw window titles, full URLs, document contents, terminal commands, browser history, credentials, and personal configuration on the Mac.
- Only encode fields explicitly declared by the v1 protocol. Treat new collectors and new wire fields as privacy-sensitive design changes.
- Use `example.com`, synthetic payloads, and local receivers in tests and documentation. Never add a real endpoint, secret, account identifier, personal site content, or production response.
- Receiver implementations, database migrations, framework UI components, and deployment settings stay in their own repositories. This repository defines only the public receiver contract.

## Protocol and runtime invariants

- `activity` and `music` are independent nullable channels. Explicit nulls clear public state.
- Preserve `startedAt` across heartbeats. `observedAt` describes the current sample.
- Keep latest-state behavior: retries may send the newest sample and must not replay activity history.
- Unknown apps produce no activity. Browsers may fall back to a generic browsing label without exposing their host.
- Collectors run away from the main actor, have a deadline, degrade clearly when permission is denied, and clear stale state after failure.
- Receivers must authenticate writes, validate an allowlist schema, use their own receipt time for expiry, reject stale or out-of-order observations, and stop exposing expired data.
- A breaking wire-format change requires a new integer protocol version and migration documentation. Do not silently change v1 semantics.

## Repository map and validation

- Protocol, rules, and debounce logic: `Sources/NowcastCore/`.
- AppKit/SwiftUI UI, collection, storage, and networking: `Sources/Nowcast/`.
- Focused XCTest coverage: `Tests/NowcastCoreTests/`.
- Packaging and release automation: `scripts/`, `Resources/Info.plist`, `VERSION`, and `.github/workflows/`.
- Receiver contract and repository boundary: `docs/integrations.md`.

Run `swift test` for protocol or rule changes. Run `bash scripts/package.sh native` for application and packaging changes when a complete Xcode toolchain is available. Report toolchain blockers precisely. For PR review, prioritize privacy regressions, concurrency races, stale public state, permission failures, version drift, signing mistakes, and release permissions.
