#!/bin/bash
# Read-only CV4 update check. Fetches with a 3s timeout and prints one line when
# the clone is behind. Never pulls, never writes engine files. Offline is silent.
# Usage: bash tools/check-update.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || exit 0
cd "$ROOT" || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
if [ -n "${CV4_UPSTREAM:-}" ]; then
  REMOTE="upstream"
elif printf '%s' "$ORIGIN" | grep -q 'wanshazamirul/CV4'; then
  REMOTE="upstream"
elif [ -n "$ORIGIN" ]; then
  REMOTE="origin"
else
  REMOTE="upstream"
fi
if [ "$REMOTE" = "upstream" ]; then
  git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/wanshazamirul/CV4.git 2>/dev/null || exit 0
fi

export GIT_TERMINAL_PROMPT=0
if command -v timeout >/dev/null 2>&1; then
  timeout 3 git fetch --quiet "$REMOTE" main >/dev/null 2>&1 || exit 0
else
  git fetch --quiet "$REMOTE" main >/dev/null 2>&1 || exit 0
fi

BEHIND="$(git rev-list --count "HEAD..$REMOTE/main" 2>/dev/null || echo 0)"
[ "$BEHIND" = "0" ] && exit 0

OLD="$(cat versions/VERSION 2>/dev/null || echo "?")"
NEW="$(git show "$REMOTE/main:versions/VERSION" 2>/dev/null || echo "$OLD")"
echo "update: CV4 v$OLD -> v$NEW ($BEHIND commits). Ask before applying."
exit 0
