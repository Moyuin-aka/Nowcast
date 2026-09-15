# Nowcast repository guidelines

Read `DEVELOPMENT.md` before continuing; this is an unverified development preview.

- Core protocol, mapping and debounce: `Sources/NowcastCore/`.
- Native macOS UI, collection and networking: `Sources/Nowcast/`.
- Unit tests: `Tests/NowcastCoreTests/`.
- Packaging and CI: `scripts/package.sh`, `.github/workflows/build.yml`.
- Host website snapshots: `integrations/tyndall/`; compare before copying to the sibling Tyndall checkout.
- Keep raw window titles, URLs, commands and document contents local. Only explicitly allowed status fields may be uploaded.
- Do not commit credentials, certificates, personal config, build artifacts or local logs.
- Validate with `swift test` and `bash scripts/package.sh native` when the toolchain supports them.
- Report test/build blockers accurately; workflow files alone do not prove a DMG works.
- Use Conventional Commits. Do not change the sibling Tyndall repository's unrelated work.
