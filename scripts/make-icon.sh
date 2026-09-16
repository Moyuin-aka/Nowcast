#!/bin/bash
# Build a macOS .icns file from the checked-in 1024×1024 PNG master.
set -euo pipefail

cd "$(dirname "$0")/.."
SOURCE="${NOWCAST_ICON_SOURCE:-Resources/AppIcon.png}"
OUTPUT="${1:-Resources/Nowcast.icns}"

test -f "$SOURCE" || { echo "Missing icon master: $SOURCE" >&2; exit 1; }
test "$(sips -g pixelWidth "$SOURCE" | awk '/pixelWidth/ {print $2}')" = "1024"
test "$(sips -g pixelHeight "$SOURCE" | awk '/pixelHeight/ {print $2}')" = "1024"
test "$(sips -g hasAlpha "$SOURCE" | awk '/hasAlpha/ {print $2}')" = "yes"

ICONSET="$(mktemp -d "${TMPDIR:-/tmp}/nowcast-iconset.XXXXXX")/Nowcast.iconset"
trap 'rm -rf "$(dirname "$ICONSET")"' EXIT
mkdir -p "$ICONSET" "$(dirname "$OUTPUT")"

make_icon() {
  local size="$1" name="$2"
  sips -z "$size" "$size" "$SOURCE" --out "$ICONSET/$name" >/dev/null
}

make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
make_icon 1024 icon_512x512@2x.png

iconutil -c icns "$ICONSET" -o "$OUTPUT"
echo "Built $OUTPUT"
