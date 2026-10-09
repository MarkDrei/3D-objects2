#!/usr/bin/env bash
# Exports the web build to build/web (installs the toolchain first if needed).
#   scripts/export.sh
#   RELEASE=1 scripts/export.sh   # release instead of debug export
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="--export-debug"; [[ "${RELEASE:-0}" == 1 ]] && MODE="--export-release"
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

"$ROOT/scripts/setup.sh" >/dev/null
# build/ holds exports and screenshots: keep Godot from importing them as project assets.
mkdir -p "$ROOT/build" && touch "$ROOT/build/.gdignore"
"$ROOT/scripts/godot.sh" --headless --path "$ROOT" --import >/dev/null 2>&1
rm -rf "$ROOT/build/web" && mkdir -p "$ROOT/build/web"
out=$("$ROOT/scripts/godot.sh" --headless --path "$ROOT" "$MODE" "Web" "$ROOT/build/web/index.html" 2>&1) || { echo "$out"; exit 1; }
if grep -qE '^(ERROR|SCRIPT ERROR)' <<<"$out"; then echo "$out"; exit 1; fi
for f in index.html index.js index.wasm index.pck; do
  [[ -s "$ROOT/build/web/$f" ]] || { echo "missing build/web/$f"; exit 1; }
done
log "Web OK: build/web ($(du -sh "$ROOT/build/web" | cut -f1)) — play: python3 -m http.server -d build/web 8000"
