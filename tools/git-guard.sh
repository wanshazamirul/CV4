#!/bin/bash
# Team-mode pre-push guard: member machines push engine/skills/library changes to dev, never straight to main.
# Canonical guard: no clone may publish a filled personal instance to the canonical CV4 main. The public
# repo is the empty cup; a lived-in clone keeps its memory on its own branch or fork.
# The real gate is branch protection + owner review; this hook is the courtesy layer.
# Install: bash tools/git-guard.sh --install [--quiet]   (writes .git/hooks/pre-push)
# Off switch: remove .git/hooks/pre-push, or delete personas/.machine (no claim = owner/personal).
# Escape hatch (intentional personal-zone commit): CV4_ALLOW_PERSONAL=1 git push ...
set -u

QUIET=0; INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    --quiet) QUIET=1 ;;
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "git-guard: not inside a git repo"; exit 2; }

if [ "$INSTALL" = 1 ]; then
  [ -d "$ROOT/.git/hooks" ] || { echo "git-guard: no .git/hooks here"; exit 1; }
  cp "$0" "$ROOT/.git/hooks/pre-push"
  chmod +x "$ROOT/.git/hooks/pre-push"
  [ "$QUIET" = 1 ] || echo "git-guard: pre-push hook installed"
  exit 0
fi

# The hook receives the remote name and URL as arguments, refs on stdin. Read stdin once.
PUSH_LINES="$(cat 2>/dev/null || true)"
REMOTE_URL="${2:-}"

# --- canonical guard: never publish filled personal zones to main ------------
if [ "${CV4_ALLOW_PERSONAL:-0}" != "1" ] \
   && printf '%s' "$REMOTE_URL" | grep -q 'wanshazamirul/CV4' \
   && printf '%s\n' "$PUSH_LINES" | grep -Eq 'refs/heads/(main|master)$' \
   && [ -f "$ROOT/tools/check-personal.sh" ]; then
  if ! bash "$ROOT/tools/check-personal.sh" --root "$ROOT" --quiet; then
    echo "git-guard: BLOCKED - this clone's personal zones are filled."
    echo "           The canonical main is the empty template. Keep your memory on a personal branch or fork."
    echo "           Intentional override: CV4_ALLOW_PERSONAL=1 git push ..."
    exit 1
  fi
fi

# --- member guard: engine-owned zones go to dev + PR, never straight to main --
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
done <<< "$PUSH_LINES"
[ "$blocked" = 1 ] && exit 1
exit 0
