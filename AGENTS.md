# Nowcast repository guidelines

Read `DEVELOPMENT.md` before continuing; this is an unverified development preview.

- Core protocol, mapping and debounce: `Sources/NowcastCore/`.
- Native macOS UI, collection and networking: `Sources/Nowcast/`.
- Unit tests: `Tests/NowcastCoreTests/`.
- Packaging and CI: `scripts/package.sh`, `.github/workflows/build.yml`.
- `VERSION` is the release version source; tag releases must use the matching `vX.Y.Z` tag.
- Receiver contract: `docs/`; keep host implementations, migrations, UI components and deployment settings outside this repository.
- Keep raw window titles, URLs, commands and document contents local. Only explicitly allowed status fields may be uploaded.
- Do not commit credentials, certificates, personal config, host identifiers, deployment metadata, build artifacts or local logs.
- Validate with `swift test` and `bash scripts/package.sh native` when the toolchain supports them.
- Report test/build blockers accurately; workflow files alone do not prove a DMG works.
- Use Conventional Commits. Do not copy code or configuration from a receiver's private repository into Nowcast.
- **Required PR follow-up:** After opening a PR or pushing updates, check Copilot's review and inline comments. Address actionable findings, explain any suggestions not adopted, and check again after fixes. If the review is pending or unavailable, report that explicitly; do not treat a passing build as a completed review.
