#!/bin/bash
# Post-update repair: idempotent fixes for gaps earlier versions left behind.
# update.sh runs this after every successful pull; you can also run it by hand.
# Every check is safe on any version, so a machine that skipped several releases
# heals in one boot. When a release changes install state, add its fix here.
# Usage: bash tools/repair.sh [--quiet]
set -u
cd "$(dirname "$0")/.." || exit 0
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
say() { [ "$QUIET" = 1 ] || echo "$@"; }
note() { say "repair: $1"; }

# 1. Skills: project + global wiring (0.11.2: rituals resolve from any folder;
#    0.11.3: hand-copied folders are adopted, edited ones are left alone).
if [ -f tools/install-skills.sh ]; then
  bash tools/install-skills.sh --global --quiet >/dev/null 2>&1 || true
fi

# 2. Ignore rules: the pending update note and other working files rely on *.tmp (0.11.1).
if [ -f .gitignore ] && ! grep -qx '\*\.tmp' .gitignore 2>/dev/null; then
  printf '*.tmp\n' >> .gitignore
  note "added *.tmp to .gitignore"
fi

# 3. Legacy pending note from the pre-0.11.1 manual patch: keep its content, drop the old name.
if [ -f logs/.pending-update ]; then
  mkdir -p logs
  [ -s logs/.pending-update ] && cat logs/.pending-update >> logs/pending-update.tmp 2>/dev/null || true
  rm -f logs/.pending-update
  note "cleared the legacy pending-update note"
fi

# 4. An empty pending note is noise; the next real update writes a fresh one.
if [ -f logs/pending-update.tmp ] && [ ! -s logs/pending-update.tmp ]; then
  rm -f logs/pending-update.tmp
fi

# 5. The load writes here; older clones may lack the folder.
if [ ! -d logs/current ]; then
  mkdir -p logs/current
  note "restored logs/current"
fi

# 6. Pre-push guard: no clone publishes a filled personal instance to the canonical
#    main (0.12.0). Never overwrite a hook the user already has.
if [ -d .git/hooks ] && [ ! -f .git/hooks/pre-push ] && [ -f tools/git-guard.sh ]; then
  bash tools/git-guard.sh --install --quiet >/dev/null 2>&1 || true
  note "installed the pre-push guard"
fi

[ "$QUIET" = 1 ] || echo "repair: done"
exit 0
