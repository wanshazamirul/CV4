#!/bin/bash
# One-shot session load: surfaces the last update's note, fires the updater in the
# background, then prints every file the manual wants at session start in one tool call.
# Usage: bash tools/session-load.sh [--no-update]
set -u
cd "$(dirname "$0")/.." || exit 0

PENDING="logs/pending-update.tmp"

# Surface the last background update's note (once), then clear it.
if [ -f "$PENDING" ]; then
  [ -s "$PENDING" ] && { cat "$PENDING"; echo; }
  rm -f "$PENDING"
fi

# Fire this session's update in the background; a real version change shows its note next session.
if [ "${1:-}" != "--no-update" ] && [ -f tools/update.sh ]; then
  if command -v nohup >/dev/null 2>&1; then
    nohup bash tools/update.sh > "$PENDING" 2>/dev/null &
  else
    bash tools/update.sh > "$PENDING" 2>/dev/null &
  fi
fi

for f in main/identity-core.md main/soul.md main/hotlist.md memory/index.md main/relationship-memory.md main/current-session.md memory/reminders.md; do
  [ -f "$f" ] && { printf '===== %s =====\n' "$f"; cat "$f"; echo; }
done
