#!/usr/bin/env bash
# Exports the web build and screenshots objects in headless Chromium.
#   scripts/shots.sh [id,id,…|all] [views]     e.g. scripts/shots.sh bear_0,bear_1 hero,front,side,back
#   scripts/shots.sh ui                         the viewer with its UI
# Writes build/screenshots/<id>__<view>.png and, for several views, a 2x2 sheet <id>.png.
#   SKIP_EXPORT=1 scripts/shots.sh …            reuse the last export
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="${GODOT_TOOLS:-$HOME/.local/opt/3D-objects2}/web-test"
PORT="${PORT:-8766}"
IDS="${1:-all}"
VIEWS="${2:-hero,front,side,back}"

[[ "${SKIP_EXPORT:-0}" == 1 ]] || "$ROOT/scripts/export.sh"
export PLAYWRIGHT_BROWSERS_PATH="$TOOLS/browsers"
export LD_LIBRARY_PATH="$TOOLS/libroot/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
mkdir -p "$ROOT/build/screenshots"
python3 -m http.server -d "$ROOT/build/web" "$PORT" >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null' EXIT
sleep 1
node "$ROOT/tests/web/shots.cjs" "$TOOLS/node_modules" "http://localhost:$PORT" "$ROOT/build/screenshots" "$IDS" "$VIEWS"
