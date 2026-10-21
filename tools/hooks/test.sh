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
if have python3 && python3 -c 'import sys' >/dev/null 2>&1; then PY=python3
elif have python && python -c 'import sys' >/dev/null 2>&1; then PY=python
elif have py && py -c 'import sys' >/dev/null 2>&1; then PY=py
else echo "hooks-test: python missing (skipped)"; exit 0
fi
[ -f "$DISPATCH" ] || { echo "hooks-test: dispatcher missing"; exit 1; }

T="$(mktemp -d "${TMPDIR:-/tmp}/cv4-hooks.XXXXXX" 2>/dev/null)" || exit 1
trap 'rm -rf "$T"' EXIT

mkdir -p "$T/main" "$T/memory" "$T/logs" "$T/skills" "$T/tools/hooks"
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
cp "$ROOT/tools/hooks/dispatch.py" "$ROOT/tools/hooks/dispatch.sh" "$ROOT/tools/hooks/idle-save.sh" "$T/tools/hooks/"
printf '## Basics\n- **Timezone**: MYT (UTC+8, Malaysia)\n' > "$T/main/relationship-memory.md"
python3 - "$T/main/identity-core.md" <<'PYID'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("[from BOOT: e.g. playful]", "warm")
s = s.replace("[from BOOT: none / light / generous]", "generous")
s = s.replace("[from BOOT: short / balanced / detailed]", "short")
open(p, "w").write(s)
PYID
printf '{"auto_save":{"idle_minutes":0}}\n' > "$T/main/behavior.json"
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
expect_json "session start injects a brief" "$OUT" 'len(d["hookSpecificOutput"]["additionalContext"]) > 500 and "CV4 boot" in d["hookSpecificOutput"]["additionalContext"] and "relationship" in d["hookSpecificOutput"]["additionalContext"] and "emoji: generous" in d["hookSpecificOutput"]["additionalContext"]'

# 2. save router
OUT="$(run UserPromptSubmit '{"session_id":"hk1","prompt":"ok save and wrap up"}')"
expect_json "save prompt injects the save skill" "$OUT" '"goodbye detected" in d["hookSpecificOutput"]["additionalContext"] and "Save - session close ritual" in d["hookSpecificOutput"]["additionalContext"] and "next:" in d["hookSpecificOutput"]["additionalContext"]'

# 3. work + stop gate
run PostToolUse '{"session_id":"hk1","tool_name":"Edit","tool_input":{"file_path":"/tmp/x.ts"}}' >/dev/null
OUT="$(run Stop '{"session_id":"hk1","last_assistant_message":"done"}')"
expect_empty "stop autosaves quietly (no hook error)" "$OUT"
if [ -f "$T/logs/.state/pending-save-hk1.json" ] && [ -f "$T/logs/.state/autosave-note.json" ]; then ok "stop autosave writes note + pending"; else bad "stop autosave left no trace"; fi

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

# 7b. a stale state file (terminal closed without a SessionEnd) is surfaced too
mkdir -p "$T/logs/checkpoints"
rm -f "$T"/logs/.state/pending-save-*.json
printf '# stale checkpoint\n' > "$T/logs/checkpoints/2026-10-20-stale1.md"
"$PY" - "$T/logs/.state/stale1.json" <<'PY'
import json, sys
from datetime import datetime, timedelta, timezone
old = (datetime.now(timezone.utc) - timedelta(hours=3)).isoformat()
data = {"session_id": "stale1", "harness": "opencode", "cwd": "/tmp", "started_at": old,
        "last_event_at": old, "turns": 3, "tool_calls": 5, "edits": 2,
        "flags": {"save_done": False}, "closed": False}
open(sys.argv[1], "w").write(json.dumps(data) + "\n")
PY
OUT="$(run SessionStart '{"session_id":"hk-stale","source":"startup"}')"
expect_json "a stale session is surfaced" "$OUT" '"stale session" in d["hookSpecificOutput"]["additionalContext"]'

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

# gemini prompt / gate / stop shapes
run SessionStart '{"session_id":"hk9","source":"startup"}' gemini >/dev/null
OUT="$(run UserPromptSubmit '{"session_id":"hk9","prompt":"save and wrap up"}' gemini)"
expect_json "gemini prompt injects save" "$OUT" '"additionalContext" in d["hookSpecificOutput"] and "goodbye detected" in d["hookSpecificOutput"]["additionalContext"]'
run PostToolUse '{"session_id":"hk9","tool_name":"write_file","tool_input":{"file_path":"/tmp/g.ts"}}' gemini >/dev/null
OUT="$(run Stop '{"session_id":"hk9"}' gemini)"
expect_empty "gemini turn end autosaves quietly" "$OUT"
[ -f "$T/logs/.state/pending-save-hk9.json" ] && ok "gemini autosave writes a pending marker" || bad "gemini autosave left no marker"
run SessionStart '{"session_id":"hk11","source":"startup"}' gemini >/dev/null
run UserPromptSubmit '{"session_id":"hk11","prompt":"this is broken"}' gemini >/dev/null
OUT="$(run PreToolUse '{"session_id":"hk11","tool_name":"replace","tool_input":{"file_path":"/tmp/g.ts"}}' gemini)"
expect_json "gemini tool gate denies once" "$OUT" 'd["decision"] == "deny"'

# codex prompt / gate / stop shapes
run SessionStart '{"session_id":"hk10","source":"startup"}' codex >/dev/null
OUT="$(run UserPromptSubmit '{"session_id":"hk10","prompt":"save and wrap up"}' codex)"
expect_json "codex prompt injects save" "$OUT" '"additionalContext" in d["hookSpecificOutput"] and "goodbye detected" in d["hookSpecificOutput"]["additionalContext"]'
run PostToolUse '{"session_id":"hk10","tool_name":"apply_patch","tool_input":{"file_path":"/tmp/c.ts"}}' codex >/dev/null
OUT="$(run Stop '{"session_id":"hk10"}' codex)"
expect_empty "codex turn end autosaves quietly" "$OUT"
[ -f "$T/logs/.state/pending-save-hk10.json" ] && ok "codex autosave writes a pending marker" || bad "codex autosave left no marker"
run SessionStart '{"session_id":"hk12","source":"startup"}' codex >/dev/null
run UserPromptSubmit '{"session_id":"hk12","prompt":"this is broken"}' codex >/dev/null
OUT="$(run PreToolUse '{"session_id":"hk12","tool_name":"apply_patch","tool_input":{"file_path":"/tmp/c.ts"}}' codex)"
expect_json "codex tool gate denies once" "$OUT" 'd["hookSpecificOutput"]["permissionDecision"] == "deny"'

# 13. install/uninstall sandbox (Claude + opencode + Gemini + Codex)
TH="$T/home"
CR="$T/cv4-copy"
mkdir -p "$CR"
cp -a "$ROOT/." "$CR/" 2>/dev/null
rm -rf "$CR/.git" "$CR/logs/.state" "$CR/logs/checkpoints"
mkdir -p "$TH/.claude" "$TH/.config/opencode" "$TH/.gemini" "$TH/.codex"
printf '%s\n' '{"attribution":false,"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo user-hook"}]}]}}' > "$TH/.claude/settings.json"
printf '%s\n' '{"$schema":"https://opencode.ai/config.json","model":"test/model"}' > "$TH/.config/opencode/opencode.json"
printf '%s\n' '{"hooks":{"BeforeTool":[{"matcher":"x","hooks":[{"name":"user","type":"command","command":"echo user-hook"}]}]}}' > "$TH/.gemini/settings.json"
printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo user-hook"}]}]}}' > "$TH/.codex/hooks.json"
HOME="$TH" bash "$CR/tools/hooks/install.sh" all install --force --quiet >/dev/null 2>&1
if "$PY" - "$TH" <<'PY'
import json, sys, pathlib
home = pathlib.Path(sys.argv[1])
claude = json.loads((home / ".claude/settings.json").read_text())
hooks = claude.get("hooks", {})
cv4 = sum(1 for ev in hooks.values() for g in ev for h in g.get("hooks", []) if "dispatch.sh" in h.get("command", ""))
user = any("user-hook" in h.get("command", "") for g in hooks.get("Stop", []) for h in g.get("hooks", []))
oc = json.loads((home / ".config/opencode/opencode.json").read_text())
plugin = any("cv4-hooks" in p for p in oc.get("plugins", []))
g = json.loads((home / ".gemini/settings.json").read_text())
gcv4 = sum(1 for ev in g.get("hooks", {}).values() for gr in ev for h in gr.get("hooks", []) if "dispatch.sh" in h.get("command", ""))
guser = any("user-hook" in h.get("command", "") for ev in g.get("hooks", {}).values() for gr in ev for h in gr.get("hooks", []))
c = json.loads((home / ".codex/hooks.json").read_text())
ccv4 = sum(1 for ev in c.get("hooks", {}).values() for gr in ev for h in gr.get("hooks", []) if "dispatch.sh" in h.get("command", ""))
cuser = any("user-hook" in h.get("command", "") for ev in c.get("hooks", {}).values() for gr in ev for h in gr.get("hooks", []))
assert cv4 == 7 and user and plugin, (cv4, user, plugin)
assert gcv4 == 7 and guser, (gcv4, guser)
assert ccv4 == 7 and cuser, (ccv4, cuser)
PY
then ok "installer wires all four adapters, keeps user hooks"; else bad "installer wiring failed"; fi

# 13b. the installed commands actually run
for pair in "claude:$TH/.claude/settings.json" "gemini:$TH/.gemini/settings.json" "codex:$TH/.codex/hooks.json"; do
  name="${pair%%:*}"; cfg="${pair#*:}"
  CMD="$("$PY" - "$cfg" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
cmds = [h["command"] for g in d["hooks"]["SessionStart"] for h in g.get("hooks", []) if "dispatch.sh" in h.get("command", "")]
print(cmds[0])
PY
)"
  OUT="$(printf '{"session_id":"cfg-%s","source":"startup"}' "$name" | HOME="$TH" bash -c "$CMD" 2>/dev/null)"
  if printf '%s' "$OUT" | grep -q 'additionalContext'; then ok "installed $name SessionStart command runs"; else bad "installed $name command failed"; fi
done
mv "$CR/tools/hooks/dispatch.sh" "$CR/tools/hooks/dispatch.sh.off"
OUT="$(printf '{"session_id":"gone","source":"startup"}' | HOME="$TH" bash -c "$CMD" 2>&1)"
if [ -z "$OUT" ]; then ok "missing Home exits 0 silently"; else bad "missing Home produced output: ${OUT:0:120}"; fi
mv "$CR/tools/hooks/dispatch.sh.off" "$CR/tools/hooks/dispatch.sh"
HOME="$TH" bash "$CR/tools/hooks/install.sh" all install --force --quiet >/dev/null 2>&1
if "$PY" - "$TH" <<'PY'
import json, sys, pathlib
home = pathlib.Path(sys.argv[1])
def cv4(path, key="hooks"):
    d = json.loads(path.read_text())
    return sum(1 for ev in d.get(key, {}).values() for gr in ev for h in gr.get("hooks", []) if "dispatch.sh" in h.get("command", ""))
claude = cv4(home / ".claude/settings.json")
g = cv4(home / ".gemini/settings.json")
c = cv4(home / ".codex/hooks.json")
oc = json.loads((home / ".config/opencode/opencode.json").read_text())
plugin = len([p for p in oc.get("plugins", []) if "cv4-hooks" in p])
assert claude == 7 and g == 7 and c == 7 and plugin == 1, (claude, g, c, plugin)
PY
then ok "installer is idempotent across all four"; else bad "installer duplicates on a second run"; fi
HOME="$TH" bash "$CR/tools/hooks/install.sh" all remove --quiet >/dev/null 2>&1
if "$PY" - "$TH" <<'PY'
import json, sys, pathlib
home = pathlib.Path(sys.argv[1])
def state(path, key="hooks"):
    d = json.loads(path.read_text())
    n = sum(1 for ev in d.get(key, {}).values() for gr in ev for h in gr.get("hooks", []) if "dispatch.sh" in h.get("command", ""))
    u = any("user-hook" in h.get("command", "") for ev in d.get(key, {}).values() for gr in ev for h in gr.get("hooks", []))
    return n, u
claude = state(home / ".claude/settings.json")
g = state(home / ".gemini/settings.json")
c = state(home / ".codex/hooks.json")
oc = json.loads((home / ".config/opencode/opencode.json").read_text())
plugin = any("cv4-hooks" in p for p in oc.get("plugins", []))
gone = not (home / ".config/opencode/plugins/cv4-hooks").exists()
assert claude == (0, True) and g == (0, True) and c == (0, True), (claude, g, c)
assert not plugin and gone, (plugin, gone)
PY
then ok "uninstaller removes only CV4 entries across all four"; else bad "uninstaller left CV4 entries or removed user hooks"; fi

# 14. close-save worker (fake harness binary, personal vs member role)
WR="$T/worker"
mkdir -p "$WR/main" "$WR/memory" "$WR/logs" "$WR/skills" "$WR/personas" "$T/bin"
cp -a "$ROOT/skills/save" "$WR/skills/"
printf '**Last updated: <date time> - template**\n' > "$WR/main/current-session.md"
printf 'role=personal\n' > "$WR/personas/.machine"
cat > "$T/bin/opencode" <<'EOF'
#!/bin/bash
echo "$@" > "$WORKER_OUT"
EOF
chmod +x "$T/bin/opencode"
run_at() { # run_at <root> <event> <json> <harness>
  printf '%s' "$3" | "$PY" "$DISPATCH" "$4" "$2" --root "$1" 2>/dev/null
}
WORKER_OUT="$T/worker-personal.out" PATH="$T/bin:$PATH" run_at "$WR" SessionStart '{"session_id":"w1","source":"startup"}' opencode >/dev/null
PATH="$T/bin:$PATH" run_at "$WR" PostToolUse '{"session_id":"w1","tool_name":"write_file","tool_input":{"file_path":"/tmp/w.ts"}}' opencode >/dev/null
WORKER_OUT="$T/worker-personal.out" PATH="$T/bin:$PATH" run_at "$WR" SessionEnd '{"session_id":"w1"}' opencode >/dev/null
sleep 1
if [ -f "$T/worker-personal.out" ] && grep -q "CV4 close-save worker" "$T/worker-personal.out"; then
  ok "personal close spawns the save worker"
else
  bad "personal close did not spawn the save worker"
fi
printf 'role=member\n' > "$WR/personas/.machine"
rm -f "$T/worker-member.out"
WORKER_OUT="$T/worker-member.out" PATH="$T/bin:$PATH" run_at "$WR" SessionStart '{"session_id":"w2","source":"startup"}' opencode >/dev/null
PATH="$T/bin:$PATH" run_at "$WR" PostToolUse '{"session_id":"w2","tool_name":"write_file","tool_input":{"file_path":"/tmp/w2.ts"}}' opencode >/dev/null
WORKER_OUT="$T/worker-member.out" PATH="$T/bin:$PATH" run_at "$WR" SessionEnd '{"session_id":"w2"}' opencode >/dev/null
sleep 1
[ ! -f "$T/worker-member.out" ] && ok "member close stays checkpoint-only" || bad "member close spawned a worker"

# 14b. idle autosave: waits for real inactivity, then fires
printf '{"auto_save":{"idle_minutes":0.05}}\n' > "$T/main/behavior.json"
run SessionStart '{"session_id":"hk-idle","source":"startup"}' >/dev/null
run PostToolUse '{"session_id":"hk-idle","tool_name":"Edit","tool_input":{"file_path":"/tmp/idle.ts"}}' >/dev/null
CV4_IDLE_SECONDS=1 CV4_IDLE_MINUTES=0.05 run Stop '{"session_id":"hk-idle"}' >/dev/null
sleep 2
if ls "$T"/logs/.state/pending-save-hk-idle.json >/dev/null 2>&1; then bad "idle watcher fired while active"; else ok "idle watcher waits for inactivity"; fi
sleep 3
if ls "$T"/logs/.state/pending-save-hk-idle.json >/dev/null 2>&1; then ok "idle watcher saves after inactivity"; else bad "idle watcher missed the save"; fi
if [ -f "$T/logs/.state/autosave-note.json" ]; then ok "idle save writes the next-greeting note"; else bad "idle save left no greeting note"; fi
OUT="$(run SessionStart '{"session_id":"hk-idle-next","source":"startup"}')"
expect_json "idle autosave is summarized at the next boot" "$OUT" '"autosave:" in d["hookSpecificOutput"]["additionalContext"] and "next:" in d["hookSpecificOutput"]["additionalContext"]'
rm -f "$T"/logs/.state/pending-save-hk-idle.json
printf '{"auto_save":{"idle_minutes":0}}\n' > "$T/main/behavior.json"

# 15. adaptive timing: learned late and cadence boundaries
TR="$T/time"
mkdir -p "$TR/main" "$TR/memory" "$TR/logs" "$TR/skills"
printf '## Basics\n- **Timezone**: MYT (UTC+8, Malaysia)\n' > "$TR/main/relationship-memory.md"
printf '**Last updated: 2020-01-01 00:00 - seed**\n' > "$TR/main/current-session.md"
cp -a "$ROOT/skills/save" "$TR/skills/"
CV4_NOW="2026-10-20T22:55:00+08:00" run_at "$TR" SessionStart '{"session_id":"ht1","source":"startup"}' claude >/dev/null
CV4_NOW="2026-10-20T22:56:00+08:00" run_at "$TR" PostToolUse '{"session_id":"ht1","tool_name":"Edit","tool_input":{"file_path":"/tmp/t.ts"}}' claude >/dev/null
OUT="$(CV4_NOW="2026-10-20T23:01:00+08:00" run_at "$TR" Stop '{"session_id":"ht1"}' claude)"
expect_empty "late boundary autosaves quietly" "$OUT"
[ -f "$TR/logs/.state/pending-save-ht1.json" ] && ok "late autosave writes a pending marker" || bad "late autosave left no marker"
CV4_NOW="2026-10-21T09:00:00+08:00" run_at "$TR" SessionStart '{"session_id":"ht2","source":"startup"}' claude >/dev/null
CV4_NOW="2026-10-21T09:01:00+08:00" run_at "$TR" PostToolUse '{"session_id":"ht2","tool_name":"Edit","tool_input":{"file_path":"/tmp/t2.ts"}}' claude >/dev/null
OUT="$(CV4_NOW="2026-10-21T10:31:00+08:00" run_at "$TR" Stop '{"session_id":"ht2"}' claude)"
expect_empty "cadence boundary autosaves quietly" "$OUT"
[ -f "$TR/logs/.state/pending-save-ht2.json" ] && ok "cadence autosave writes a pending marker" || bad "cadence autosave left no marker"
mkdir -p "$TR/logs/.state"
"$PY" - "$TR/logs/.state/usage.jsonl" <<'PY'
import json, sys
rows = []
for day in range(15, 20):
    rows.append({"date": f"2026-10-{day}", "harness": "claude", "start": f"2026-10-{day}T21:20:00+08:00", "end": f"2026-10-{day}T23:00:00+08:00", "minutes": 100, "turns": 8, "tools": 25, "saved": True})
with open(sys.argv[1], "w") as f:
    for row in rows:
        f.write(json.dumps(row) + "\n")
PY
CV4_NOW="2026-10-21T11:00:00+08:00" run_at "$TR" SessionStart '{"session_id":"ht3","source":"startup"}' claude >/dev/null
CV4_NOW="2026-10-21T11:05:00+08:00" run_at "$TR" PostToolUse '{"session_id":"ht3","tool_name":"Edit","tool_input":{"file_path":"/tmp/t3.ts"}}' claude >/dev/null
CV4_NOW="2026-10-21T11:10:00+08:00" run_at "$TR" SessionEnd '{"session_id":"ht3"}' claude >/dev/null
if "$PY" - "$TR/logs/.state/timing.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d.get("late") == "22:45", d
assert d.get("cadence_min") == 80, d
PY
then ok "usage history teaches the late and cadence boundary"; else bad "adaptive timing did not learn"; fi

# 16. update offer + snooze (local bare remote, no network)
if command -v git >/dev/null 2>&1; then
  UR="$T/update-root"; BR="$T/update-remote.git"; UC="$T/update-clone"
  if git clone --quiet "$ROOT" "$UR" 2>/dev/null && git init --quiet --bare "$BR" 2>/dev/null; then
    git -C "$BR" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
    cp "$ROOT/tools/update-flow.sh" "$UR/tools/update-flow.sh" 2>/dev/null || true
    cp "$ROOT/tools/check-update.sh" "$UR/tools/check-update.sh" 2>/dev/null || true
    cp "$ROOT/tools/hooks/checkpoint.sh" "$UR/tools/hooks/checkpoint.sh" 2>/dev/null || true
    git -C "$UR" remote set-url origin "$BR" >/dev/null 2>&1
    git -C "$UR" push --quiet origin main >/dev/null 2>&1
    git clone --quiet "$BR" "$UC" >/dev/null 2>&1
    printf '9.9.9\n' > "$UC/versions/VERSION"
    git -C "$UC" -c user.name=test -c user.email=test@example.com commit -qam "test bump" >/dev/null 2>&1
    git -C "$UC" push --quiet origin main >/dev/null 2>&1
    OLDV="$(cat "$UR/versions/VERSION" 2>/dev/null || echo '?')"
    OUT="$(run_at "$UR" SessionStart '{"session_id":"up1","source":"startup"}' claude)"
    if printf '%s' "$OUT" | grep -q "update: CV4 v$OLDV -> v9.9.9"; then ok "greeting brief offers an update"; else bad "greeting brief missed the update"; fi
    OUT="$(run_at "$UR" UserPromptSubmit '{"session_id":"up1","prompt":"yes"}' claude)"
    expect_json "yes injects the update handoff" "$OUT" '"approved the update" in d["hookSpecificOutput"]["additionalContext"] and "next:" in d["hookSpecificOutput"]["additionalContext"]'
    OUT="$(run_at "$UR" SessionStart '{"session_id":"up2","source":"startup"}' claude)"
    if printf '%s' "$OUT" | grep -q "update: CV4"; then ok "a fresh session offers it again"; else bad "a fresh session missed the update"; fi
    run_at "$UR" UserPromptSubmit '{"session_id":"up2","prompt":"no"}' claude >/dev/null
    OUT="$(run_at "$UR" SessionStart '{"session_id":"up3","source":"startup"}' claude)"
    if printf '%s' "$OUT" | grep -q "update: CV4"; then bad "declined version still offered"; else ok "declined version is snoozed"; fi
    ( cd "$UR" && HOME="$TH" CV4_UPSTREAM="$BR" bash tools/update-flow.sh ) >/dev/null 2>&1
    NEWV="$(cat "$UR/versions/VERSION" 2>/dev/null || echo '?')"
    [ "$NEWV" = "9.9.9" ] && ok "update-flow pulls and repairs" || bad "update-flow did not pull"
  else
    ok "update test skipped (git clone unavailable)"
  fi
else
  ok "update test skipped (no git)"
fi

# 17. manual refresh: update the block, preserve names and Home
RH="$T/refresh-home"; mkdir -p "$RH/.claude"
cat > "$RH/.claude/CLAUDE.md" <<'EOF'
# Notes
<!-- CV4 companion: start (delete this block, markers included, to detach) -->
# How I operate

> Manual rev: 0.0.1
> Home: /tmp/cv4. All paths in this file resolve against Home.

I am mira, wan's AI companion.
<!-- CV4 companion: end -->
tail
EOF
HOME="$RH" bash "$ROOT/tools/refresh-manual.sh" --write --root "$ROOT" >/dev/null 2>&1
REV="$(grep -m1 'Manual rev' "$ROOT/BOOT.md" | sed 's/.*Manual rev: //')"
if grep -q "Manual rev: $REV" "$RH/.claude/CLAUDE.md" && grep -q "I am mira" "$RH/.claude/CLAUDE.md" && [ "$(tail -1 "$RH/.claude/CLAUDE.md")" = "tail" ]; then
  ok "manual refresh preserves names/home and updates the rev"
else
  bad "manual refresh failed"
fi

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
