#!/bin/bash
# Distill a spec-kit outcome into the house memory. Append-only, idempotent.
# Usage: bash spec-kit/converge-to-memory.sh "<one-line outcome>"
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTCOME="${1:-}"
[ -n "$OUTCOME" ] || { echo 'usage: converge-to-memory.sh "<one-line outcome>"' >&2; exit 2; }
DATE="$(TZ=Asia/Kuala_Lumpur date +%F)"
LINE="- $DATE: spec-kit converge: $OUTCOME"
if grep -qF -e "$LINE" "$ROOT/memory/decisions.md" 2>/dev/null; then
  echo "converge-to-memory: already recorded (no-op)"
  exit 0
fi
printf '%s\n' "$LINE" >> "$ROOT/memory/decisions.md"
echo "converge-to-memory: recorded -> $LINE"
