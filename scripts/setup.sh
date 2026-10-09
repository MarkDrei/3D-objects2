#!/usr/bin/env bash
# Installs everything needed to build, export and screenshot this project — without root.
# Idempotent: already installed parts are skipped. Re-run any time.
#
#   Godot editor + web export templates, Playwright with headless Chromium (screenshots)
#   and the shared libraries Chromium needs (unpacked from .debs).
#
# Install location: $GODOT_TOOLS (default ~/.local/opt/3D-objects2), ~1 GB.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
GODOT_TOOLS="${GODOT_TOOLS:-$HOME/.local/opt/3D-objects2}"
GODOT_DIR="$GODOT_TOOLS/godot-$GODOT_VERSION"
GODOT_BIN="$GODOT_DIR/godot"
WEB_TEST="$GODOT_TOOLS/web-test"
DL="$GODOT_TOOLS/downloads"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
mkdir -p "$GODOT_TOOLS" "$DL"

download() { # url target
  [[ -f "$2" ]] || { log "Download $(basename "$2")"; curl -fL --retry 3 -o "$2.part" "$1" && mv "$2.part" "$2"; }
}

# --- Godot editor (self-contained mode: settings + templates live next to the binary) ---
if [[ ! -x "$GODOT_BIN" ]]; then
  base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
  zip="Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
  download "$base/$zip" "$DL/$zip"
  mkdir -p "$GODOT_DIR"
  unzip -oq "$DL/$zip" -d "$GODOT_DIR"
  mv "$GODOT_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64" "$GODOT_BIN"
  touch "$GODOT_DIR/._sc_"   # self-contained marker
  rm -f "$DL/$zip"
fi

# --- Web export templates (only the single-threaded web variant, to save disk) ---
TEMPLATES="$GODOT_DIR/editor_data/export_templates/${GODOT_VERSION}.stable"
if [[ ! -f "$TEMPLATES/version.txt" ]]; then
  tpz="Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
  download "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/$tpz" "$DL/$tpz"
  log "Extract web export templates"
  mkdir -p "$TEMPLATES"
  unzip -q -j -o "$DL/$tpz" templates/version.txt templates/web_nothreads_release.zip \
    templates/web_nothreads_debug.zip -d "$TEMPLATES"
  rm -f "$DL/$tpz"
fi

# --- Playwright + headless Chromium for screenshots of the web export ---
if [[ ! -d "$WEB_TEST/node_modules/playwright" ]]; then
  log "Install Playwright"
  mkdir -p "$WEB_TEST"
  (cd "$WEB_TEST" && npm init -y >/dev/null && npm install --silent playwright@1 >/dev/null)
fi
export PLAYWRIGHT_BROWSERS_PATH="$WEB_TEST/browsers"
if ! ls "$PLAYWRIGHT_BROWSERS_PATH" 2>/dev/null | grep -q chromium_headless_shell; then
  log "Install headless Chromium"
  (cd "$WEB_TEST" && npx playwright install --only-shell chromium >/dev/null)
fi
# Shared libraries Chromium needs, fetched as .debs and unpacked (no root).
SHELL_BIN=$(ls -d "$PLAYWRIGHT_BROWSERS_PATH"/chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell | head -1)
LIBROOT="$WEB_TEST/libroot"
export LD_LIBRARY_PATH="$LIBROOT/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
if ldd "$SHELL_BIN" | grep -q "not found"; then
  log "Fetch missing system libraries"
  mkdir -p "$WEB_TEST/debs" "$LIBROOT"
  (cd "$WEB_TEST/debs" && apt-get download libatk1.0-0t64 libatk-bridge2.0-0t64 libxcomposite1 libxdamage1 \
    libxfixes3 libxrandr2 libgbm1 libasound2t64 libatspi2.0-0t64 libwayland-server0 libxrender1 libxi6 >/dev/null 2>&1 || true)
  for d in "$WEB_TEST"/debs/*.deb; do dpkg-deb -x "$d" "$LIBROOT"; done
  rm -rf "$WEB_TEST/debs"
fi

rmdir "$DL" 2>/dev/null || true
log "Setup complete: $GODOT_BIN (Godot $GODOT_VERSION)"
