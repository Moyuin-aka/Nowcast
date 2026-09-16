#!/bin/bash
set -euo pipefail

APP="${1:-dist/Nowcast.app}"
BINARY="$APP/Contents/MacOS/Nowcast"
SECONDS_TO_WAIT="${NOWCAST_SMOKE_SECONDS:-5}"

[[ -x "$BINARY" ]] || {
  echo "Nowcast executable was not found at $BINARY" >&2
  exit 1
}
[[ "$SECONDS_TO_WAIT" =~ ^[1-9][0-9]*$ ]] || {
  echo 'NOWCAST_SMOKE_SECONDS must be a positive integer' >&2
  exit 1
}

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nowcast-smoke.XXXXXX")"
RUN_HOME="$RUN_DIR/home"
STDOUT_LOG="$RUN_DIR/stdout.log"
STDERR_LOG="$RUN_DIR/stderr.log"
PID=''
mkdir -p "$RUN_HOME"

cleanup() {
  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
  rm -rf "$RUN_DIR"
}
trap cleanup EXIT

# Keep sharing disabled and isolate app configuration during the smoke test.
HOME="$RUN_HOME" CFFIXED_USER_HOME="$RUN_HOME" \
  "$BINARY" -sharingEnabled NO -onboarded YES >"$STDOUT_LOG" 2>"$STDERR_LOG" &
PID=$!
sleep "$SECONDS_TO_WAIT"

if ! kill -0 "$PID" 2>/dev/null; then
  set +e
  wait "$PID"
  EXIT_CODE=$?
  set -e
  PID=''
  echo "Nowcast exited during the ${SECONDS_TO_WAIT}-second launch smoke test (status $EXIT_CODE)." >&2
  if [[ -s "$STDOUT_LOG" ]]; then
    echo 'stdout:' >&2
    cat "$STDOUT_LOG" >&2
  fi
  if [[ -s "$STDERR_LOG" ]]; then
    echo 'stderr:' >&2
    cat "$STDERR_LOG" >&2
  fi
  exit 1
fi

echo "Nowcast remained running for ${SECONDS_TO_WAIT} seconds."
