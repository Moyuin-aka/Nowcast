#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"

[[ -f "$VERSION_FILE" ]] || { echo "Missing VERSION file" >&2; exit 1; }
VERSION="$(<"$VERSION_FILE")"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "VERSION must contain a stable semantic version such as 1.2.3" >&2
  exit 1
}

case "${1:---print}" in
  --print)
    printf '%s\n' "$VERSION"
    ;;
  --check-tag)
    TAG="${2:-}"
    [[ "$TAG" == "v$VERSION" ]] || {
      echo "Release tag '$TAG' does not match VERSION '$VERSION' (expected v$VERSION)" >&2
      exit 1
    }
    ;;
  *)
    echo "Usage: version.sh [--print | --check-tag vX.Y.Z]" >&2
    exit 1
    ;;
esac
