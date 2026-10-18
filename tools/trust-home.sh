#!/bin/bash
# Trust this CV4 folder in Claude Code. Run it YOURSELF, in your own terminal:
#   bash "<HOME>/tools/trust-home.sh"
# It is the documented fix for Claude Code's repeating "do you trust this folder?"
# prompt (a known bug makes it ask again and again). The flag is consent-shaped,
# which is why your agent will not set it for you and you set it with your own hands.
set -u
cd "$(dirname "$0")/.." || exit 1

CFG="$HOME/.claude.json"
[ -f "$CFG" ] || { echo "trust-home: no ~/.claude.json yet; launch Claude Code once first, then rerun this."; exit 0; }
[ -f "$CFG.cv4bak" ] || cp "$CFG" "$CFG.cv4bak" 2>/dev/null || true

py=""
command -v python3 >/dev/null 2>&1 && py=python3
[ -n "$py" ] || { command -v python >/dev/null 2>&1 && py=python; }
[ -n "$py" ] || { echo "trust-home: python not found. By hand: in ~/.claude.json, set projects[\"<this folder>\"].hasTrustDialogAccepted to true."; exit 0; }

"$py" - "$(pwd -W 2>/dev/null || pwd)" "$CFG" <<'PY'
import json, os, sys

target = os.path.abspath(sys.argv[1])
cfg = sys.argv[2]

with open(cfg, encoding="utf-8") as f:
    data = json.load(f)

projects = data.setdefault("projects", {})

def norm(p):
    p = os.path.abspath(p).replace("\\", "/").rstrip("/")
    return p.lower() if os.name == "nt" else p

# match an existing key (any separator/case form) before creating a new one
key = next((k for k in projects if norm(k) == norm(target)), None)
if key is None:
    key = target

projects.setdefault(key, {})["hasTrustDialogAccepted"] = True

with open(cfg, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
print(f"trust-home: trusted {key}")
print(f"trust-home: original kept at {cfg}.cv4bak (first run only)")
PY
