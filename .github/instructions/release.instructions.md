---
applyTo: ".github/workflows/**/*.yml,scripts/**/*.sh,VERSION,Resources/Info.plist"
---

- `VERSION` is the release version source. Release tags must be exactly `v<contents-of-VERSION>`.
- Packaging must write the release version into `CFBundleShortVersionString` and a valid monotonic build number into `CFBundleVersion`.
- Keep pull-request builds unprivileged. Grant `contents: write` only to the tag release job.
- Pin third-party GitHub Actions to full commit SHAs and retain the human-readable major version in a comment.
- Never add signing identities, certificates, notarization credentials, or other secrets to the repository or workflow output.
- Tag builds with no Apple credentials may publish an unsigned release whose notes clearly explain the Gatekeeper limitation. A partial credential set must fail instead of silently falling back.
- Only describe a release as signed or notarized after Developer ID, notarization, stapling, and Gatekeeper checks pass.
- Pull-request and branch builds remain ad-hoc signed so forks can validate packaging without access to release secrets.
- A release job must consume the exact package that passed architecture, signature, disk-image, metadata, and checksum verification.
