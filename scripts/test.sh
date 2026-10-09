#!/usr/bin/env bash
# Runs the headless tests (tests/viewer_tests.gd): every object builds and stands on the ground,
# and the viewer reacts to real mouse, keyboard and touch input.
#   scripts/test.sh                 # all tests (~30 s)
#   scripts/test.sh test_wheel_zooms   # one test
# Exit code = number of failed tests (also non-zero on script errors).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ONLY="${1:-}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

mkdir -p "$ROOT/build" && touch "$ROOT/build/.gdignore"
"$ROOT/scripts/godot.sh" --headless --path "$ROOT" --import >/dev/null 2>&1
GODOT_MEM="${GODOT_MEM:-1500M}" timeout 600 "$ROOT/scripts/godot.sh" --headless --path "$ROOT" --fixed-fps 30 \
  -- --test=1 ${ONLY:+--only=$ONLY} >"$LOG" 2>&1
rc=$?
grep -E "^TEST|SCRIPT ERROR|^ERROR|^\s+at:" "$LOG"
if grep -q "SCRIPT ERROR" "$LOG"; then echo "script errors (see above)"; rc=$((rc == 0 ? 1 : rc)); fi
grep -q "^TESTS DONE" "$LOG" || { echo "tests did not finish (exit $rc)"; tail -20 "$LOG"; rc=$((rc == 0 ? 1 : rc)); }
exit $rc
