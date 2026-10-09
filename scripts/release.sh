#!/usr/bin/env bash
# One-step release: tests, commit, push main, wait for the VPS webhook deploy (it builds the
# web export in the Docker image), then verify the live site.
#   scripts/release.sh "Commit message"   # commits all changes, then releases
#   scripts/release.sh                    # releases what is already committed
#   SKIP_TESTS=1 scripts/release.sh "…"
# The project must be registered on the deploy platform (~/clones/config) for the deploy step.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="${URL:-https://3d-objects2.ironstrike.de}"
LOGS="$HOME/clones/config/logs"
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
cd "$ROOT"

[[ "$(git branch --show-current)" == main ]] || die "not on main"

if [[ "${SKIP_TESTS:-0}" != 1 ]]; then
  log "Tests"
  scripts/test.sh || die "tests failed"
fi

if [[ -n "$(git status --porcelain)" ]]; then
  [[ $# -ge 1 ]] || die "uncommitted changes: pass a commit message"
  git add -A
  git commit -q -m "$1"
fi

git fetch -q origin main
[[ -z "$(git log --oneline HEAD..origin/main)" ]] || die "origin/main has commits you don't have; pull first"
sha="$(git rev-parse HEAD)"
if [[ "$(git rev-parse origin/main)" == "$sha" ]] && grep -q "\"sha\":\"$sha\".*\"status\":\"success\"" "$LOGS/deploys.jsonl" 2>/dev/null; then
  log "${sha:0:7} is already live"
else
  log "Push ${sha:0:7}: $(git log -1 --format=%s)"
  git push -q origin main
  log "Waiting for the deploy (~1–5 min)"
  line=""
  for _ in $(seq 1 60); do
    line="$(grep "\"sha\":\"$sha\"" "$LOGS/deploys.jsonl" 2>/dev/null | grep '"finished"' | tail -1 || true)"
    [[ -n "$line" ]] && break
    sleep 10
  done
  [[ -n "$line" ]] || die "no finished deploy for ${sha:0:7} after 10 min — is the project registered? (https://deploy.ironstrike.de/dashboard)"
  if ! grep -q '"status":"success"' <<<"$line"; then
    logfile="$(sed -n 's/.*"log":"\([^"]*\)".*/\1/p' <<<"$line")"
    tail -30 "$LOGS/$logfile"
    die "deploy failed (log: $LOGS/$logfile)"
  fi
fi

log "Verify live site"
code=$(curl -s -o /dev/null -w '%{http_code}' "$URL/")
[[ "$code" == 200 ]] || die "$URL/ answered $code"
wasm=$(curl -s -o /dev/null -w '%{http_code}' "$URL/index.wasm")
[[ "$wasm" == 200 ]] || die "$URL/index.wasm answered $wasm"
log "Live: $URL"
