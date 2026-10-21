#!/bin/bash
# Canonical-template guard: a lived-in instance must not ship its personal zones.
# A filled template makes every fresh clone boot as that person. Fails when the
# working tree looks lived-in; the canonical main must keep the empty cup.
# Usage: bash tools/check-personal.sh [--root DIR] [--quiet]
# Exit: 0 = template-clean, 1 = filled personal zones found
set -u

ROOT=""; QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift ;;
    --quiet) QUIET=1 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "check-personal: unknown flag $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

findings=0
note() { [ "$QUIET" = 1 ] || echo "  $1"; }
bad() { findings=$((findings + 1)); echo "  FILLED  $1"; }

# Identity and relationship: the template keeps its placeholders.
if [ -f "$ROOT/main/identity-core.md" ] && ! grep -q '\[AI_NAME\]' "$ROOT/main/identity-core.md"; then
  bad "main/identity-core.md (no [AI_NAME] placeholder)"
fi
if [ -f "$ROOT/main/relationship-memory.md" ] && ! grep -q '\[USER_NAME\]' "$ROOT/main/relationship-memory.md"; then
  bad "main/relationship-memory.md (no [USER_NAME] placeholder)"
fi

# Rolling session state: the template keeps its <date time> stamp.
if [ -f "$ROOT/main/current-session.md" ] && ! grep -q '<date time>\|<YYYY-MM-DD HH:MM>' "$ROOT/main/current-session.md"; then
  bad "main/current-session.md (no <date time> placeholder)"
fi

# Memory index: the first-boot row stays a placeholder.
if [ -f "$ROOT/memory/index.md" ] && ! grep -q '| <date> |\|| <YYYY-MM-DD HH:MM> |' "$ROOT/memory/index.md"; then
  bad "memory/index.md (first-boot row is filled)"
fi

# Soul: the seed line is the template marker.
if [ -f "$ROOT/main/soul.md" ] && ! grep -q '^Seed:' "$ROOT/main/soul.md"; then
  bad "main/soul.md (seed line replaced)"
fi

# Hotlist: the personal-scars placeholder is the template marker.
if [ -f "$ROOT/main/hotlist.md" ] && ! grep -q 'Personal scars (yours go here)' "$ROOT/main/hotlist.md"; then
  bad "main/hotlist.md (personal scars replaced)"
fi

# Reminders: the empty-state line is the template marker.
if [ -f "$ROOT/memory/reminders.md" ] && ! grep -q '(add a reminder' "$ROOT/memory/reminders.md"; then
  bad "memory/reminders.md (reminders are filled)"
fi

# A lived-in instance always has at least one day log; the template ships .gitkeep only.
if [ -d "$ROOT/logs/current" ]; then
  for f in "$ROOT"/logs/current/*.md; do
    [ -e "$f" ] || continue
    bad "logs/current/$(basename "$f") (session log present)"
  done
fi

if [ "$findings" = 0 ]; then
  note "template personal zones are clean"
  exit 0
fi

echo "check-personal: $findings filled personal-zone file(s)."
echo "  Keep instance memory on your own branch or fork; the canonical main stays the empty cup."
exit 1
