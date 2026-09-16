#!/bin/bash
# Usage: bash scripts/package.sh [native|universal]
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-native}"
VERSION="$(bash scripts/version.sh --print)"
BUILD_VERSION="${NOWCAST_BUILD_NUMBER:-$VERSION}"
[[ "$BUILD_VERSION" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || {
  echo 'NOWCAST_BUILD_NUMBER must contain one to three dot-separated integers' >&2
  exit 1
}
ARGS=(-c release)
case "$MODE" in
  native) ;;
  universal) ARGS+=(--arch arm64 --arch x86_64) ;;
  *) echo 'Usage: package.sh [native|universal]' >&2; exit 1 ;;
esac
swift build "${ARGS[@]}"
BIN_DIR="$(swift build "${ARGS[@]}" --show-bin-path)"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/nowcast-stage.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/Nowcast.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" dist
cp "$BIN_DIR/Nowcast" "$APP/Contents/MacOS/Nowcast"
cp Resources/Info.plist "$APP/Contents/Info.plist"
bash scripts/make-icon.sh "$APP/Contents/Resources/Nowcast.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_VERSION" "$APP/Contents/Info.plist"
SIGN_IDENTITY="${NOWCAST_SIGN_IDENTITY:--}"
if [[ "$SIGN_IDENTITY" == '-' ]]; then
  codesign --force --sign - --options runtime --timestamp=none \
    --entitlements Resources/Nowcast.entitlements "$APP"
else
  codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp \
    --entitlements Resources/Nowcast.entitlements "$APP"
fi
codesign --verify --deep --strict "$APP"
# Preserve the app for local installation, and also provide drag-to-Applications DMG.
OUTPUT_APP="dist/Nowcast.app"
rm -rf "$OUTPUT_APP"
ditto "$APP" "$OUTPUT_APP"
ln -s /Applications "$STAGE/Applications"
DMG="dist/Nowcast-$VERSION-$MODE.dmg"
hdiutil create -volname Nowcast -srcfolder "$STAGE" -ov -format UDZO "$DMG"
if [[ -n "${NOWCAST_NOTARY_PROFILE:-}" ]]; then
  NOTARY_ARGS=(--keychain-profile "$NOWCAST_NOTARY_PROFILE")
  if [[ -n "${NOWCAST_NOTARY_KEYCHAIN:-}" ]]; then
    NOTARY_ARGS+=(--keychain "$NOWCAST_NOTARY_KEYCHAIN")
  fi
  xcrun notarytool submit "$DMG" "${NOTARY_ARGS[@]}" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
fi
(cd dist && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "Built $DMG"
