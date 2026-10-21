#!/bin/bash
# Refresh the installed CV4 companion block from BOOT.md. Finds Python, runs the script.
# Usage: bash tools/refresh-manual.sh [--check|--write] [--root DIR]
set -u
ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || exit 0
[ -f "$ROOT/tools/refresh-manual.py" ] || exit 0
if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys' >/dev/null 2>&1; then
  PY="python3"
elif command -v python >/dev/null 2>&1 && python -c 'import sys' >/dev/null 2>&1; then
  PY="python"
elif command -v py >/dev/null 2>&1 && py -3 -c 'import sys' >/dev/null 2>&1; then
  PY="py -3"
else
  exit 0
fi
exec $PY "$ROOT/tools/refresh-manual.py" "$@"
