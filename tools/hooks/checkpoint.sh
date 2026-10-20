#!/bin/bash
# Pre-update checkpoint. Fast, local, no model. Writes one file under logs/checkpoints/.
# Usage: bash tools/hooks/checkpoint.sh
set -u
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)" || exit 0
cd "$ROOT" || exit 0
mkdir -p logs/checkpoints 2>/dev/null || exit 0
FILE="logs/checkpoints/update-$(date +%Y-%m-%d-%H%M%S).md"
{
  echo "# CV4 pre-update checkpoint"
  echo "- time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "- version: $(cat versions/VERSION 2>/dev/null || echo '?')"
  echo "- commit: $(git rev-parse --short HEAD 2>/dev/null || echo '?')"
  echo "- branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  echo
  echo "## Working tree"
  git status --short 2>/dev/null | head -30
  echo
  echo "## Current session"
  sed -n '1,40p' main/current-session.md 2>/dev/null
} > "$FILE" 2>/dev/null || exit 0
[ -s "$FILE" ] && echo "$FILE"
exit 0
