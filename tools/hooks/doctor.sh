#!/bin/bash
# CV4 behavior spine first aid. Checks the install, the dispatcher, the fixtures,
# state, and the last decisions. Read-only except for the fixture scratch dir.
# Usage: bash tools/hooks/doctor.sh [--quiet]
# Exit: 0 = healthy, 1 = something needs attention
set -u
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)" || exit 1
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
FAILS=0
say() { [ "$QUIET" = 1 ] || echo "  $1"; }
bad() { FAILS=$((FAILS + 1)); echo "  FAIL  $1"; }

[ -f "$ROOT/tools/hooks/dispatch.py" ] && say "dispatcher present" || bad "dispatcher missing"
[ -x "$ROOT/tools/hooks/dispatch.sh" ] && say "dispatch.sh executable" || bad "dispatch.sh not executable"

if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else echo "  FAIL  python missing (hooks are a silent no-op)"; exit 1
fi

if "$PY" -m py_compile "$ROOT/tools/hooks/dispatch.py" 2>/dev/null; then
  say "dispatcher compiles"
else
  bad "dispatcher does not compile"
fi

OUT="$(bash "$ROOT/tools/hooks/install.sh" all check 2>/dev/null || true)"
while IFS= read -r line; do
  [ -n "$line" ] && say "$line"
done <<< "$OUT"

HARNESS=0
[ -d "$HOME/.claude" ] && HARNESS=1
[ -d "$HOME/.config/opencode" ] && HARNESS=1
[ -d "$HOME/.gemini" ] && HARNESS=1
[ -d "$HOME/.codex" ] && HARNESS=1
TEMPLATE=0
grep -q '\[AI_NAME\]' "$ROOT/main/identity-core.md" 2>/dev/null && TEMPLATE=1
if [ "$TEMPLATE" = 1 ]; then
  say "template clone: adapters are not expected here (run BOOT first)"
elif [ "$HARNESS" = 1 ]; then
  if printf '%s\n' "$OUT" | grep -Eq 'CV4 hook handler\(s\) installed|[1-9][0-9]* config entry'; then
    say "at least one adapter installed"
  else
    bad "a harness exists but no CV4 adapter is installed (run: bash tools/hooks/install.sh all install)"
  fi
else
  say "no supported harness config on this machine"
fi

if bash "$ROOT/tools/hooks/test.sh" --quiet >/dev/null 2>&1; then
  say "fixture suite passes"
else
  bad "fixture suite failed (run: bash tools/hooks/test.sh)"
fi

if mkdir -p "$ROOT/logs/.state" 2>/dev/null && [ -w "$ROOT/logs/.state" ]; then
  say "state dir writable"
else
  bad "state dir not writable"
fi

OUT="$(CV4_HOOKS=0 bash "$ROOT/tools/hooks/dispatch.sh" claude SessionStart 2>/dev/null <<<'{"session_id":"doctor"}')"
[ -z "$OUT" ] && say "kill switch works" || bad "kill switch did not silence the dispatcher"

if [ -f "$ROOT/logs/hooks.log" ]; then
  say "last decision: $(tail -1 "$ROOT/logs/hooks.log")"
else
  say "no decisions logged yet"
fi

if [ "$FAILS" = 0 ]; then
  [ "$QUIET" = 1 ] || echo "DOCTOR: PASS"
  exit 0
fi
echo "DOCTOR: FAIL ($FAILS item(s))"
exit 1
