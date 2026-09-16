# Signed macOS releases

GitHub tag builds support two explicit modes. With Apple credentials, they import a temporary **Developer ID Application**
certificate, sign the app with the hardened runtime, notarize and staple the DMG, and publish a normal release. With no
Apple credentials, they publish an **unsigned prerelease** whose title and notes explain the Gatekeeper limitation.
Pull requests and ordinary branch builds stay ad-hoc signed and never receive release credentials. A partial set of
Apple credentials fails the build instead of silently falling back.

## Apple account preparation

1. Join the Apple Developer Program. The Account Holder creates a **Developer ID Application** certificate in
   Certificates, Identifiers & Profiles.
2. Install the certificate and private key in Keychain Access, then export that identity as a password-protected `.p12`.
3. Create an App Store Connect API key that can access the notary service. Keep the downloaded `.p8`, Key ID, and
   Issuer ID. Individual API keys may not have an Issuer ID.

An Apple Development certificate cannot replace Developer ID for public downloads.

## GitHub Actions secrets

Add these repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `MACOS_CERTIFICATE_P12` | Base64 text of the exported `.p12` |
| `MACOS_CERTIFICATE_PASSWORD` | Password used while exporting the `.p12`; may be empty |
| `APPLE_API_KEY_P8` | Complete text of the App Store Connect `.p8` file |
| `APPLE_API_KEY_ID` | App Store Connect API Key ID |
| `APPLE_API_ISSUER_ID` | App Store Connect Issuer ID; omit for an individual API key |

On macOS, create the certificate secret without writing another plaintext copy:

```sh
base64 -i DeveloperIDApplication.p12 | pbcopy
```

Never commit any of these values. The workflow writes them only to the runner's temporary directory and keychain,
then removes that material in an `always()` cleanup step.

## Publish

1. Update `VERSION` and merge it to `main`.
2. Create a tag whose name is exactly `v<contents-of-VERSION>`.
3. Push the tag. With all signing secrets configured, the workflow refuses to publish if the identity is not a
   Developer ID Application identity, notarization fails, stapling fails, or Gatekeeper rejects the DMG.

Without any signing secrets, the workflow instead creates an ad-hoc signed prerelease. Users follow the README's
first-launch Terminal instructions. The release job always downloads the exact artifact verified by the macOS build job.

## Local signed build

Store notarization credentials in Keychain once, then pass the identity and profile names to the existing packager:

```sh
xcrun notarytool store-credentials nowcast-notary \
  --key /path/to/AuthKey_KEYID.p8 --key-id KEYID --issuer ISSUER_ID

NOWCAST_SIGN_IDENTITY='Developer ID Application: Example (TEAMID)' \
NOWCAST_NOTARY_PROFILE='nowcast-notary' \
bash scripts/package.sh universal
```

The output DMG is signed, notarized, stapled, validated, and accompanied by its SHA-256 file.
