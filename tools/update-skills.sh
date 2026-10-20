#!/bin/bash
# External skill updater. Reads tools/skill-sources.txt and updates each registered
# source. Background-friendly: silent when offline or nothing to do.
# Pinned by design: an entry without @version is skipped, never run (supply chain).
# Every run appends one line to logs/update-skills.log; failures never break a session.
# Usage: bash tools/update-skills.sh
set -u
cd "$(dirname "$0")/.." || exit 0

SOURCES="tools/skill-sources.txt"
[ -f "$SOURCES" ] || exit 0

# Claude is the only provider for now; skip on machines that do not have it.
[ -d "$HOME/.claude" ] || exit 0

LOG="logs/update-skills.log"
mkdir -p logs 2>/dev/null || true
stamp() { date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "?"; }
log() { printf '%s %s\n' "$(stamp)" "$*" >> "$LOG" 2>/dev/null || true; }

while IFS= read -r line; do
  # Skip blank lines and comments.
  case "$line" in ''|\#*) continue ;; esac

  type="$(printf '%s' "$line" | awk '{print $1}')"
  spec="$(printf '%s' "$line" | awk '{print $2}')"

  case "$type" in
    npm)
      [ -n "$spec" ] || continue
      case "$spec" in
        *@?*) ;;                       # name@version, good
        *) log "skip unpinned: $spec"; continue ;;
      esac
      name="${spec%@*}"
      ver="${spec##*@}"
      [ -n "$name" ] && [ -n "$ver" ] || { log "skip malformed: $spec"; continue; }
      if npx --yes "$spec" update --providers=claude --scope=global >/dev/null 2>&1; then
        log "ok $spec"
      else
        rc=$?
        log "fail $spec (exit $rc)"
      fi
      ;;
    git)
      # Reserved for future git-based skill repos.
      log "skip git source: $spec"
      ;;
    *)
      log "skip unknown type: $type $spec"
      ;;
  esac
done < "$SOURCES"

# Keep the log bounded; the last 500 lines are plenty for forensics.
[ -f "$LOG" ] && tail -n 500 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG" 2>/dev/null || true
exit 0
