#!/bin/bash
# Print the CV4 boot brief without a harness hook. Useful for a manual load or a
# harness that has no hook surface yet. No state is written; the update check may
# run once (3s timeout, cached).
# Usage: bash tools/hooks/brief.sh [--root DIR]
set -u
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)" || exit 0
[ -f "$ROOT/tools/hooks/dispatch.py" ] || exit 0

if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
elif command -v py >/dev/null 2>&1; then PY="py -3"
else exit 0
fi

exec $PY "$ROOT/tools/hooks/dispatch.py" claude session-start --brief --root "$ROOT" "$@"
