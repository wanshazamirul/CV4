#!/bin/bash
# Skeleton engine updater. Pulls the latest template-owned files from upstream.
# Safe by design: never touches personal zones (main/ memory/ logs/ library/).
set -u
cd "$(dirname "$0")/.." || exit 0

UPSTREAM_URL="${CV4_UPSTREAM:-https://github.com/wanshazamirul/CV4.git}"
TEMPLATE_PATHS="BOOT.md README.md skills tools versions .gitattributes"

git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
git fetch --quiet upstream main 2>/dev/null || { echo "update: offline, skipped"; exit 0; }

BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo 0)
if [ "$BEHIND" = "0" ]; then exit 0; fi

git checkout --quiet upstream/main -- $TEMPLATE_PATHS 2>/dev/null

# Normalize shell scripts to LF: Windows checkouts can add \r and bash chokes on it.
for f in tools/*.sh; do
  [ -f "$f" ] || continue
  tr -d '\r' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

NEWV=$(cat versions/VERSION 2>/dev/null || echo "?")
git add -A >/dev/null 2>&1
git commit -q -m "engine update: v$NEWV ($BEHIND commit(s) from upstream)" >/dev/null 2>&1 || true
echo "update: engine pulled to v$NEWV - $BEHIND new upstream commit(s). Mention this to the user in one line."
