#!/bin/bash
# CV4 update handoff: checkpoint -> update -> repair -> print the save + reload steps.
# Never forces a conflict and never saves by itself; the model runs the save ritual
# after this returns. Usage: bash tools/update-flow.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || exit 0
cd "$ROOT" || exit 0

CP="$(bash tools/hooks/checkpoint.sh 2>/dev/null | tail -1)"
[ -n "$CP" ] && echo "checkpoint: $CP"

OLD="$(cat versions/VERSION 2>/dev/null || echo "?")"
if [ -f tools/update.sh ]; then
  bash tools/update.sh || {
    echo "update: failed; nothing forced. Checkpoint kept at $CP."
    exit 1
  }
else
  echo "update: tools/update.sh missing"
  exit 1
fi
[ -f tools/repair.sh ] && bash tools/repair.sh --quiet >/dev/null 2>&1 || true
NEW="$(cat versions/VERSION 2>/dev/null || echo "?")"

if [ "$OLD" = "$NEW" ]; then
  echo "update: already current (v$NEW); no engine change."
else
  echo "update: v$OLD -> v$NEW"
fi
echo "next: run the save ritual (skills/save), refresh the installed manual block if the rev changed, then bash tools/session-load.sh --no-update."
exit 0
