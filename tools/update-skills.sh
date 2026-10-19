#!/bin/bash
# External skill updater. Reads tools/skill-sources.txt and updates each registered
# skill source. Background-friendly: silent when offline or nothing to do.
# Usage: bash tools/update-skills.sh
set -u
cd "$(dirname "$0")/.." || exit 0

SOURCES="tools/skill-sources.txt"
[ -f "$SOURCES" ] || exit 0

while IFS= read -r line; do
  # Skip blank lines and comments.
  case "$line" in ''|\#*) continue ;; esac

  type="$(printf '%s' "$line" | awk '{print $1}')"
  name="$(printf '%s' "$line" | awk '{print $2}')"

  case "$type" in
    npm)
      [ -n "$name" ] || continue
      # Redirect all output; a missing network is silently ignored.
      npx "$name" update --providers=claude --scope=global >/dev/null 2>&1 || true
      ;;
    git)
      # Reserved for future git-based skill repos.
      true
      ;;
  esac
done < "$SOURCES"
