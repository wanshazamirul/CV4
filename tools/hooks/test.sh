#!/bin/bash
# Fixture tests for the behavior spine dispatcher. No network, no harness, no real Home.
# Usage: bash tools/hooks/test.sh [--quiet]
# Exit: 0 = PASS, 1 = FAIL
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)" || exit 1
DISPATCH="$ROOT/tools/hooks/dispatch.py"
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

have() { command -v "$1" >/dev/null 2>&1; }
if have python3; then PY=python3
elif have python; then PY=python
else echo "hooks-test: python missing (skipped)"; exit 0
fi
[ -f "$DISPATCH" ] || { echo "hooks-test: dispatcher missing"; exit 1; }

T="$(mktemp -d "${TMPDIR:-/tmp}/cv4-hooks.XXXXXX" 2>/dev/null)" || exit 1
trap 'rm -rf "$T"' EXIT

mkdir -p "$T/main" "$T/memory" "$T/logs" "$T/skills" "$T/tools"
for s in save recall-memory build-protocol check-reminders decision-log forge intake; do
  [ -d "$ROOT/skills/$s" ] && cp -a "$ROOT/skills/$s" "$T/skills/"
done
for f in identity-core.md soul.md hotlist.md current-session.md relationship-memory.md; do
  [ -f "$ROOT/main/$f" ] && cp "$ROOT/main/$f" "$T/main/$f"
done
for f in index.md reminders.md; do
  [ -f "$ROOT/memory/$f" ] && cp "$ROOT/memory/$f" "$T/memory/$f"
done
[ -f "$ROOT/tools/fts.py" ] && cp "$ROOT/tools/fts.py" "$T/tools/"
[ -f "$ROOT/tools/.fts.db" ] && cp "$ROOT/tools/.fts.db" "$T/tools/"
printf '## Basics\n- **Timezone**: MYT (UTC+8, Malaysia)\n' > "$T/main/relationship-memory.md"
# Old session stamp so a save is never detected by the copy itself.
touch -t 202001010000 "$T/main/current-session.md" 2>/dev/null || true

passes=0; fails=0
ok()   { passes=$((passes + 1)); [ "$QUIET" = 1 ] || echo "  ok    $1"; }
bad()  { fails=$((fails + 1)); echo "  FAIL  $1"; }

run() { # run <event> <json> [harness]
  local event="$1" body="$2" harness="${3:-claude}"
  printf '%s' "$body" | "$PY" "$DISPATCH" "$harness" "$event" --root "$T" 2>/dev/null
}

expect_json() { # expect_json <name> <json> <python-expr on d>
  local name="$1" body="$2" expr="$3"
  if printf '%s' "$body" | "$PY" -c "import sys,json; d=json.load(sys.stdin); assert $expr" 2>/dev/null; then
    ok "$name"
  else
    bad "$name"
  fi
}

expect_empty() { # expect_empty <name> <body>
  if [ -z "$2" ]; then ok "$1"; else bad "$1 (expected empty, got: ${2:0:120})"; fi
}

# 1. session start brief
OUT="$(run SessionStart '{"session_id":"hk1","source":"startup"}')"
expect_json "session start injects a brief" "$OUT" 'len(d["hookSpecificOutput"]["additionalContext"]) > 500 and "CV4 boot" in d["hookSpecificOutput"]["additionalContext"]'

# 2. save router
OUT="$(run UserPromptSubmit '{"session_id":"hk1","prompt":"ok save and wrap up"}')"
expect_json "save prompt injects the save skill" "$OUT" '"goodbye detected" in d["hookSpecificOutput"]["additionalContext"] and "Save - session close ritual" in d["hookSpecificOutput"]["additionalContext"]'

# 3. work + stop gate
run PostToolUse '{"session_id":"hk1","tool_name":"Edit","tool_input":{"file_path":"/tmp/x.ts"}}' >/dev/null
OUT="$(run Stop '{"session_id":"hk1","last_assistant_message":"done"}')"
expect_json "stop blocks once for autosave" "$OUT" 'd["decision"] == "block" and "autosave" in d["reason"]'

# 4. simulated save clears the gate
mkdir -p "$T/logs/current"
printf '## saved\n' > "$T/logs/current/$(date +%Y-%m-%d).md"
OUT="$(run Stop '{"session_id":"hk1","last_assistant_message":"saved"}')"
expect_empty "save is detected, no second block" "$OUT"

# 5. bug prompt gets auto-recall
OUT="$(run UserPromptSubmit '{"session_id":"hk2","prompt":"this is broken, why is login failing"}')"
expect_json "bug prompt injects recall + skill" "$OUT" '"[CV4 recall]" in d["hookSpecificOutput"]["additionalContext"] and "Recall Memory" in d["hookSpecificOutput"]["additionalContext"]'

# 6. hard recall gate once
OUT="$(run PreToolUse '{"session_id":"hk2","tool_name":"Edit","tool_input":{"file_path":"/tmp/x.ts"}}')"
expect_json "first edit is blocked by the recall gate" "$OUT" 'd["hookSpecificOutput"]["permissionDecision"] == "deny"'
OUT="$(run PreToolUse '{"session_id":"hk2","tool_name":"Edit","tool_input":{"file_path":"/tmp/x.ts"}}')"
expect_empty "second edit passes the gate" "$OUT"

# 7. unsaved close -> pending marker -> next boot surfaces it
run PostToolUse '{"session_id":"hk2","tool_name":"Edit","tool_input":{"file_path":"/tmp/y.ts"}}' >/dev/null
run SessionEnd '{"session_id":"hk2","reason":"other"}' >/dev/null
if ls "$T"/logs/.state/pending-save-*.json >/dev/null 2>&1; then ok "unsaved session writes a pending marker"; else bad "pending marker missing"; fi
OUT="$(run SessionStart '{"session_id":"hk3","source":"startup"}')"
expect_json "next boot surfaces the unsaved session" "$OUT" '"unsaved session" in d["hookSpecificOutput"]["additionalContext"]'

# 8. kill switch
OUT="$(CV4_HOOKS=0 "$PY" "$DISPATCH" claude SessionStart --root "$T" 2>/dev/null <<<'{"session_id":"hk4"}')"
expect_empty "kill switch silences the dispatcher" "$OUT"

# 9. malformed input is a silent no-op
OUT="$(printf 'not json' | "$PY" "$DISPATCH" claude SessionStart --root "$T" 2>/dev/null)"
expect_empty "malformed input is a silent no-op" "$OUT"

# 10. shadow mode injects and blocks nothing
printf '{"mode":"shadow"}\n' > "$T/main/behavior.json"
OUT="$(run SessionStart '{"session_id":"hk5","source":"startup"}')"
expect_empty "shadow session start stays quiet" "$OUT"
OUT="$(run UserPromptSubmit '{"session_id":"hk5","prompt":"save and wrap up"}')"
expect_empty "shadow router stays quiet" "$OUT"
run PostToolUse '{"session_id":"hk5","tool_name":"Edit","tool_input":{"file_path":"/tmp/z.ts"}}' >/dev/null
OUT="$(run Stop '{"session_id":"hk5"}')"
expect_empty "shadow stop does not block" "$OUT"
rm -f "$T/main/behavior.json"

# 11. other harness shapes
OUT="$(run SessionStart '{"session_id":"hk6","source":"startup"}' opencode)"
expect_json "opencode returns a context block" "$OUT" '"context" in d and len(d["context"]) > 500'
OUT="$(run SessionStart '{"session_id":"hk7","source":"startup"}' gemini)"
expect_json "gemini returns additionalContext" "$OUT" '"additionalContext" in d["hookSpecificOutput"]'
OUT="$(run SessionStart '{"session_id":"hk8","source":"startup"}' codex)"
expect_json "codex returns additionalContext" "$OUT" '"additionalContext" in d["hookSpecificOutput"]'

# 13. install/uninstall sandbox (Claude + opencode)
TH="$T/home"
mkdir -p "$TH/.claude" "$TH/.config/opencode"
printf '%s\n' '{"attribution":false,"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo user-hook"}]}]}}' > "$TH/.claude/settings.json"
printf '%s\n' '{"$schema":"https://opencode.ai/config.json","model":"test/model"}' > "$TH/.config/opencode/opencode.json"
HOME="$TH" bash "$ROOT/tools/hooks/install.sh" all install --force --quiet >/dev/null 2>&1
if python3 - "$TH" <<'PY'
import json, sys, pathlib
home = pathlib.Path(sys.argv[1])
claude = json.loads((home / ".claude/settings.json").read_text())
hooks = claude.get("hooks", {})
cv4 = sum(1 for ev in hooks.values() for g in ev for h in g.get("hooks", []) if "dispatch.sh" in h.get("command", ""))
user = any("user-hook" in h.get("command", "") for g in hooks.get("Stop", []) for h in g.get("hooks", []))
oc = json.loads((home / ".config/opencode/opencode.json").read_text())
plugin = any("cv4-hooks" in p for p in oc.get("plugins", []))
assert cv4 == 7 and user and plugin, (cv4, user, plugin)
PY
then ok "installer wires Claude + opencode, keeps user hooks"; else bad "installer wiring failed"; fi
HOME="$TH" bash "$ROOT/tools/hooks/install.sh" all install --force --quiet >/dev/null 2>&1
if python3 - "$TH" <<'PY'
import json, sys, pathlib
home = pathlib.Path(sys.argv[1])
hooks = json.loads((home / ".claude/settings.json").read_text()).get("hooks", {})
cv4 = sum(1 for ev in hooks.values() for g in ev for h in g.get("hooks", []) if "dispatch.sh" in h.get("command", ""))
oc = json.loads((home / ".config/opencode/opencode.json").read_text())
plugin = len([p for p in oc.get("plugins", []) if "cv4-hooks" in p])
assert cv4 == 7 and plugin == 1, (cv4, plugin)
PY
then ok "installer is idempotent"; else bad "installer duplicates on a second run"; fi
HOME="$TH" bash "$ROOT/tools/hooks/install.sh" all remove --quiet >/dev/null 2>&1
if python3 - "$TH" <<'PY'
import json, sys, pathlib
home = pathlib.Path(sys.argv[1])
hooks = json.loads((home / ".claude/settings.json").read_text()).get("hooks", {})
cv4 = sum(1 for ev in hooks.values() for g in ev for h in g.get("hooks", []) if "dispatch.sh" in h.get("command", ""))
user = any("user-hook" in h.get("command", "") for g in hooks.get("Stop", []) for h in g.get("hooks", []))
oc = json.loads((home / ".config/opencode/opencode.json").read_text())
plugin = any("cv4-hooks" in p for p in oc.get("plugins", []))
gone = not (home / ".config/opencode/plugins/cv4-hooks").exists()
assert cv4 == 0 and user and not plugin and gone, (cv4, user, plugin, gone)
PY
then ok "uninstaller removes only CV4 entries"; else bad "uninstaller left CV4 entries or removed user hooks"; fi

# 12. no personal-zone writes from the test itself
if [ -e "$ROOT/logs/hooks.log" ] && grep -q '"sid":"hk' "$ROOT/logs/hooks.log" 2>/dev/null; then
  bad "test wrote into the live hooks.log"
else
  ok "test kept the live logs clean"
fi

if [ "$fails" -eq 0 ]; then
  [ "$QUIET" = 1 ] || echo
  echo "HOOKS RESULT: PASS ($passes checks)"
  exit 0
fi
echo "HOOKS RESULT: FAIL ($passes passed, $fails failed)"
exit 1
