#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"
PORT="${PORT:-3000}"
export PORT

run_timed() {
  /usr/bin/time -p "$@"
}

run_timed test -d "$PROJECT_DIR"

if [[ -f "$PROJECT_DIR/package.json" ]]; then
  if [[ -f "$PROJECT_DIR/package-lock.json" ]]; then
    run_timed npm ci --no-audit --no-fund
  else
    run_timed npm install --no-audit --no-fund
  fi

  has_build="$(run_timed node -e "const p=require('./package.json'); process.stdout.write(p.scripts?.build ? 'yes' : 'no')")"
  if [[ "$has_build" == yes ]]; then
    run_timed npm run build
  fi
fi

if [[ -n "${BUILD_DIR:-}" ]]; then
  OUTPUT_DIR="$(realpath -m "$BUILD_DIR")"
elif [[ -f "$PROJECT_DIR/dist/index.html" ]]; then
  OUTPUT_DIR="$PROJECT_DIR/dist"
elif [[ -f "$PROJECT_DIR/build/index.html" ]]; then
  OUTPUT_DIR="$PROJECT_DIR/build"
else
  OUTPUT_DIR="$PROJECT_DIR"
fi

case "$OUTPUT_DIR/" in
  "$PROJECT_DIR/"*) ;;
  *) echo "Built static directory must be inside $PROJECT_DIR: $OUTPUT_DIR" >&2; exit 1 ;;
esac
if [[ ! -f "$OUTPUT_DIR/index.html" ]]; then
  echo "No built index.html found in $OUTPUT_DIR. Add the project source/build before starting the preview." >&2
  exit 1
fi

WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
run_timed mkdir -p "$WEB_DIR"
run_timed node -e 'const fs=require("node:fs"); const [file,project,directory]=process.argv.slice(1); fs.writeFileSync(file, JSON.stringify({project,directory}, null, 2)+"\n")' \
  "$WEB_DIR/deployment-output.json" "$PROJECT_DIR" "$OUTPUT_DIR"

exec /usr/bin/time -p node "$PROJECT_DIR/serve.mjs" "$OUTPUT_DIR"
