#!/bin/bash
# CV4 behavior spine entry point. Thin wrapper: find Python, run one dispatcher.
# Any failure exits 0 with no output. The manual path always stays alive.
# Usage: dispatch.sh <claude|opencode|gemini|codex> <event> [--root DIR]
set -u
[ "${CV4_HOOKS:-1}" = "0" ] && exit 0

ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)" || exit 0
[ -f "$ROOT/tools/hooks/dispatch.py" ] || exit 0

if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys' >/dev/null 2>&1; then
  PY="python3"
elif command -v python >/dev/null 2>&1 && python -c 'import sys' >/dev/null 2>&1; then
  PY="python"
elif command -v py >/dev/null 2>&1 && py -3 -c 'import sys' >/dev/null 2>&1; then
  PY="py -3"
else
  exit 0
fi

LOG="$ROOT/logs/hooks.log"
if mkdir -p "$ROOT/logs" 2>/dev/null && { [ -w "$ROOT/logs" ] || [ -w "$LOG" ]; }; then
  exec $PY "$ROOT/tools/hooks/dispatch.py" "$@" 2>>"$LOG"
fi
exec $PY "$ROOT/tools/hooks/dispatch.py" "$@" 2>/dev/null
