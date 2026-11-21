#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

: "${CAPTURE_URL:?Set CAPTURE_URL}" 
: "${CAPTURE_DIR:?Set CAPTURE_DIR}"
RUNTIME_DIR="${RUNTIME_DIR:-/home/runner/work/_temp/omgithub-runtime}"
export CAPTURE_URL CAPTURE_DIR RUNTIME_DIR

run_timed() {
  /usr/bin/time -p "$@"
}

run_timed mkdir -p "$CAPTURE_DIR"

set +e
run_timed node "$RUNTIME_DIR/scripts/default-capture.mjs"
status=$?
set -e

if [[ $status -eq 75 ]]; then
  echo "Temporary capture infrastructure/navigation failure (exit 75)." >&2
  exit 75
fi
if [[ $status -ne 0 ]]; then
  echo "Capture script or rendering defect (exit $status)." >&2
  exit 1
fi

for shot in final-desktop.png final-mobile.png; do
  if [[ ! -s "$CAPTURE_DIR/$shot" ]]; then
    echo "Required capture missing or empty: $CAPTURE_DIR/$shot" >&2
    exit 1
  fi
done

exit 0
