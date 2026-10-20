#!/bin/bash
# One-shot session load: surfaces the last update's note, checks (never pulls) for a
# new engine version, fires registered external skill updaters in the background, then
# prints every file the manual wants at session start in one tool call.
# Usage: bash tools/session-load.sh [--no-update|--update]
set -u
cd "$(dirname "$0")/.." || exit 0

PENDING="logs/pending-update.tmp"

# Surface the last update's note (once), then clear it.
if [ -f "$PENDING" ]; then
  [ -s "$PENDING" ] && { cat "$PENDING"; echo; }
  rm -f "$PENDING"
fi

# Check only: never pull without the user's yes. --update runs the full handoff.
if [ "${1:-}" != "--no-update" ] && [ -f tools/check-update.sh ]; then
  if [ "${1:-}" = "--update" ] && [ -f tools/update-flow.sh ]; then
    bash tools/update-flow.sh
  else
    NOTE="$(bash tools/check-update.sh 2>/dev/null || true)"
    [ -n "$NOTE" ] && { printf '%s\n' "$NOTE"; echo; }
  fi
fi

# Fire external skill updates in the background (silent; registered in main/skill-sources.txt).
if [ "${1:-}" != "--no-update" ] && [ -f tools/update-skills.sh ]; then
  if command -v nohup >/dev/null 2>&1; then
    nohup bash tools/update-skills.sh >/dev/null 2>&1 &
  else
    bash tools/update-skills.sh >/dev/null 2>&1 &
  fi
fi

for f in main/identity-core.md main/soul.md main/hotlist.md memory/index.md main/relationship-memory.md main/current-session.md memory/reminders.md; do
  [ -f "$f" ] && { printf '===== %s =====\n' "$f"; cat "$f"; echo; }
done
