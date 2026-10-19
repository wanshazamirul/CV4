#!/bin/bash
# Skeleton engine updater. Pulls the latest template-owned files from the right source:
# a clone of the canonical repo pulls from the canonical repo; a clone of a team fork
# pulls from that fork's own main (the owner merges upstream into the fork; members
# receive it here). CV4_UPSTREAM overrides everything.
# Background-friendly: quiet when there is nothing to do; speaks only when the version
# actually changes (the note rides to the next session's load). Offline is silent.
# Safe by design: never touches personal zones (main/ memory/ logs/ library/ my-skills/).
set -u
cd "$(dirname "$0")/.." || exit 0

CANON_URL="https://github.com/wanshazamirul/CV4.git"
ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"
if [ -n "${CV4_UPSTREAM:-}" ]; then
  SRC_REMOTE="upstream"; SRC_URL="$CV4_UPSTREAM"
elif printf '%s' "$ORIGIN_URL" | grep -q 'wanshazamirul/CV4'; then
  SRC_REMOTE="upstream"; SRC_URL="$CANON_URL"
elif [ -n "$ORIGIN_URL" ]; then
  SRC_REMOTE="origin"; SRC_URL="$ORIGIN_URL"
else
  SRC_REMOTE="upstream"; SRC_URL="$CANON_URL"
fi

# Invariant: my-skills/ is deliberately NOT in this list. It is the user's zone: never fetched, never overwritten.
TEMPLATE_PATHS="BOOT.md README.md skills tools commands versions .gitattributes .claude-plugin personas spec-kit"

if [ "$SRC_REMOTE" = "upstream" ]; then
  git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$SRC_URL"
fi
git fetch --quiet "$SRC_REMOTE" main 2>/dev/null || exit 0

BEHIND=$(git rev-list --count "HEAD..$SRC_REMOTE/main" 2>/dev/null || echo 0)
if [ "$BEHIND" = "0" ]; then exit 0; fi

OLDV=$(cat versions/VERSION 2>/dev/null || echo "?")

git checkout --quiet "$SRC_REMOTE/main" -- $TEMPLATE_PATHS 2>/dev/null

# One-time seed: clones that predate my-skills/ get it once, then it is never touched again.
if [ ! -d my-skills ]; then
  git checkout --quiet "$SRC_REMOTE/main" -- my-skills 2>/dev/null || true
fi

# Normalize shell scripts to LF: Windows checkouts can add \r and bash chokes on it.
for f in tools/*.sh; do
  [ -f "$f" ] || continue
  tr -d '\r' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

# Re-wire the skills engine and top up the library shelf after updates (best effort; never fails the update).
[ -f tools/install-skills.sh ] && bash tools/install-skills.sh --global --quiet >/dev/null 2>&1 || true
[ -f tools/scaffold-library.sh ] && bash tools/scaffold-library.sh --quiet >/dev/null 2>&1 || true

NEWV=$(cat versions/VERSION 2>/dev/null || echo "?")
git add -A >/dev/null 2>&1
git commit -q -m "engine update: v$NEWV ($BEHIND commit(s) from $SRC_REMOTE)" >/dev/null 2>&1 || true
# Speak only when the version actually changed: the count above stays above zero once
# a local engine commit exists (it never joins the upstream ancestry), so the count
# alone cannot gate the message. Quiet syncs stay quiet.
if [ "$OLDV" != "$NEWV" ]; then
  echo "update: engine pulled to v$NEWV ($BEHIND commit(s) from $SRC_REMOTE). Mention it to the user in one line."
fi
