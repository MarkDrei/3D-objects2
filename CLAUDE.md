# 3D-objects2

Godot 4 project for web (and possibly Android). Overview and commands: `README.md`.
Architecture: `doc/arc42.md` (keep both current).

VPS-wide rules (git identity, deploys, no root) are in `~/clones/CLAUDE.md` and apply here too.

## Conventions
- Code, comments and docs in English.
- No root on this VPS: the toolchain (Godot, export templates, Android SDK, …) is installed rootless
  in `~/.local/opt/3D-objects2` by `scripts/setup.sh`. Keep that script the single source of truth
  for the toolchain, so a fresh machine can be set up with one command.

## Memory (most important rule)
The VPS has ~8 GB RAM, shared with all other projects and sessions. Running out of memory has
already frozen the server (network lost until reboot) and killed whole Claude sessions.
- Start Godot only through `scripts/godot.sh`, a wrapper with a memory cap, so that a runaway
  Godot gets killed on its own (exit code 137) instead of the session:
  `exec systemd-run --user --scope -q -p MemoryMax="${GODOT_MEM:-3G}" -p MemorySwapMax=0 "$GODOT_BIN" "$@"`
- Keep all Godot and browser processes together under ~3-4 GB. Run tests sequentially or with a
  small, capped number of jobs; no parallel test or screenshot runs in subagents.
- Headless browsers (Playwright/Chromium): one at a time, always closed in `try/finally`, also on
  timeout or error. Check with `pgrep -c chrom` that none are left over.

## Working
- Before debugging or testing, read `doc/testing-notes.md`.
- Check visual changes with screenshots (headless browser on the web export) and look at the PNGs
  with the Read tool. That is the only way to check visuals, layout and placement.
- Test behaviour with headless scenario tests (scripts that play the game with real input), not
  with browser clicks. When you add or change a feature, add or update its test in the same commit.
- Ship through one release script (`scripts/release.sh "message"`): test, commit, push `main`,
  wait for the deploy and verify the live site. Don't push and check by hand.
- Pushing `main` deploys live once the project is registered on the deploy platform (Dockerfile in
  the repo root serving the web export on port 3000); other branches get preview deploys.

## Maintaining doc/testing-notes.md
Whenever you lose time to a testing or debugging problem, add the lesson to
`doc/testing-notes.md` in the same commit: a misleading error, a flaky test, a tool limitation, a
dev option or an engine pitfall. Keep entries short and concrete (symptom → cause → what to do).
Update or delete entries that turn out to be wrong or outdated. Keep a quick-reference table of
the test/dev scripts (command, purpose, duration) at the top.
