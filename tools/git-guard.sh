#!/bin/bash
# Team-mode pre-push guard: member machines push engine/skills/library changes to dev, never straight to main.
# The real gate is branch protection + owner review; this hook is the courtesy layer.
# Install: bash tools/git-guard.sh --install   (writes .git/hooks/pre-push)
# Off switch: remove .git/hooks/pre-push, or delete personas/.machine (no claim = owner/personal).
set -u

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "git-guard: not inside a git repo"; exit 2; }

if [ "${1:-}" = "--install" ]; then
  [ -d "$ROOT/.git/hooks" ] || { echo "git-guard: no .git/hooks here"; exit 1; }
  cp "$0" "$ROOT/.git/hooks/pre-push"
  chmod +x "$ROOT/.git/hooks/pre-push"
  echo "git-guard: pre-push hook installed"
  exit 0
fi

ROLE=""
[ -f "$ROOT/personas/.machine" ] && ROLE="$(sed -n 's/^role=//p' "$ROOT/personas/.machine" | head -1)"
[ -n "$ROLE" ] || ROLE="personal"     # no claim = personal instance = your repo
[ "$ROLE" = "member" ] || exit 0      # personal (and legacy owner / just-me): no interference

PROTECTED='^(skills/|tools/|library/|BOOT.md$|README.md$|\.claude-plugin/|versions/)'
blocked=0
while read -r local_ref local_sha remote_ref remote_sha; do
  case "$remote_ref" in refs/heads/main|refs/heads/master) ;; *) continue ;; esac
  [ "$local_sha" = "0000000000000000000000000000000000000000" ] && continue
  base="$remote_sha"
  [ "$base" = "0000000000000000000000000000000000000000" ] && base="$(git rev-list --max-parents=0 "$local_sha" 2>/dev/null | tail -1)"
  for f in $(git diff --name-only "$base".."$local_sha" 2>/dev/null); do
    if printf '%s' "$f" | grep -Eq "$PROTECTED"; then
      echo "git-guard: BLOCKED - '$f' touches engine-owned zones on main."
      echo "           Member machines: push to 'dev' and open a PR; the owner merges after review."
      blocked=1
    fi
  done
done
[ "$blocked" = 1 ] && exit 1
exit 0
