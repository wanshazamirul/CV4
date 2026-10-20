#!/bin/bash
# CV4 behavior spine installer entry. Finds Python, runs install.py.
# Silent no-op when Python is missing (the manual path stays).
# Usage: bash tools/hooks/install.sh [--root DIR] [--quiet] <claude|opencode|all> <install|remove|check>
set -u
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)" || exit 0
[ -f "$ROOT/tools/hooks/install.py" ] || exit 0

if command -v python3 >/dev/null 2>&1; then
  PY="python3"
elif command -v python >/dev/null 2>&1; then
  PY="python"
elif command -v py >/dev/null 2>&1; then
  PY="py -3"
else
  exit 0
fi

exec $PY "$ROOT/tools/hooks/install.py" "$@"
