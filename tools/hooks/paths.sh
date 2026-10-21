#!/bin/bash
# Read-only audit of the paths the companion uses: load, save, hook.
# Usage: bash tools/hooks/paths.sh [--quiet]
# Exit: 0 = required paths present, 1 = a required path is missing.
set -u
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)" || exit 1
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
FAILS=0
say() { [ "$QUIET" = 1 ] || echo "  $1"; }
ok() { say "ok    $1"; }
info() { say "info  $1"; }
bad() { FAILS=$((FAILS + 1)); echo "  FAIL  $1"; }

file_req() {
  if [ -f "$ROOT/$1" ]; then ok "file $1"; else bad "missing file $1"; fi
}
file_opt() {
  if [ -f "$ROOT/$1" ]; then ok "file $1"; else info "missing optional $1"; fi
}
dir_req() {
  if [ -d "$ROOT/$1" ]; then
    [ -w "$ROOT/$1" ] && ok "dir  $1 (writable)" || bad "dir $1 not writable"
  else
    bad "missing dir $1"
  fi
}
dir_opt() {
  if [ -d "$ROOT/$1" ]; then
    [ -w "$ROOT/$1" ] && ok "dir  $1 (writable)" || info "dir $1 not writable"
  else
    info "missing optional dir $1"
  fi
}
global_file() {
  if [ -f "$1" ]; then ok "global $1"; else info "global absent $1"; fi
}

say "== load =="
for f in main/identity-core.md main/soul.md main/hotlist.md main/relationship-memory.md main/current-session.md memory/index.md memory/reminders.md; do
  file_req "$f"
done
file_req skills/save/SKILL.md
file_req skills/recall-memory/SKILL.md

say "== save =="
dir_req logs/current
dir_req logs/archived
file_req main/current-session.md
file_req memory/index.md
file_req memory/reminders.md
for f in memory/decisions.md memory/skills.md; do
  file_opt "$f"
done
dir_opt library
dir_opt main

say "== hook =="
file_req tools/fts.py
file_req tools/hooks/dispatch.py
file_req tools/hooks/dispatch.sh
file_req tools/hooks/idle-save.sh
file_req tools/hooks/install.sh
dir_opt logs/.state
dir_opt logs/checkpoints
file_opt logs/hooks.log

say "== global config (optional) =="
for f in "$HOME/.claude/CLAUDE.md" "$HOME/.config/opencode/AGENTS.md" "$HOME/.gemini/GEMINI.md" "$HOME/.codex/AGENTS.md"; do
  global_file "$f"
done

if [ "$FAILS" = 0 ]; then
  [ "$QUIET" = 1 ] || echo "PATHS: PASS"
  exit 0
fi
echo "PATHS: FAIL ($FAILS required path(s) missing)"
exit 1
