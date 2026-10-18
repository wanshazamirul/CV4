#!/bin/bash
# One-shot session load: runs the updater, then prints every file the manual wants at
# session start, with headers, in one tool call.
# Usage: bash tools/session-load.sh [--no-update]
set -u
cd "$(dirname "$0")/.." || exit 0

if [ "${1:-}" != "--no-update" ] && [ -f tools/update.sh ]; then
  bash tools/update.sh 2>/dev/null
  echo
fi

for f in main/identity-core.md main/soul.md main/hotlist.md memory/index.md main/relationship-memory.md main/current-session.md memory/reminders.md; do
  [ -f "$f" ] && { printf '===== %s =====\n' "$f"; cat "$f"; echo; }
done
