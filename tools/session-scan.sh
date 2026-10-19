#!/bin/bash
# session-scan.sh: surface recently closed Claude Code sessions at load time.
# Prints a compact block for each closed session: what it opened with, what the
# last message was, and a warning if no save was detected.
#
# Usage: bash tools/session-scan.sh [HOURS]   (default: 24)

set -u
HOURS="${1:-24}"
PROJECTS_DIR="$HOME/.claude/projects"

[ -d "$PROJECTS_DIR" ] || exit 0

NOW_EPOCH=$(date +%s 2>/dev/null) || exit 0
CUTOFF=$(( NOW_EPOCH - HOURS * 3600 ))

PRINTED=0

while IFS= read -r file; do
  [ -f "$file" ] || continue

  FILE_EPOCH=$(date -r "$file" +%s 2>/dev/null) || continue

  # skip if older than the cutoff window
  [ "$FILE_EPOCH" -lt "$CUTOFF" ] && continue

  # skip files modified in the last 3 minutes (likely the current live session)
  AGE_SEC=$(( NOW_EPOCH - FILE_EPOCH ))
  [ "$AGE_SEC" -lt 180 ] && continue

  # working directory the session ran in
  CWD=$(grep -om1 '"cwd":"[^"]*"' "$file" 2>/dev/null | head -1 \
        | sed 's/.*"cwd":"//;s/".*//' | sed 's/\\\\/\//g')

  # first human text message (skip tool-result lines that also have "content")
  FIRST=$(grep -m5 '"origin":{"kind":"human"}' "$file" 2>/dev/null \
          | grep -o '"content":"[^"]*"' | head -1 \
          | sed 's/"content":"//;s/".*//' | cut -c1-72)

  # last prompt (written by the harness at session close)
  LAST=$(grep -o '"lastPrompt":"[^"]*"' "$file" 2>/dev/null \
         | tail -1 | sed 's/"lastPrompt":"//;s/".*//' | cut -c1-72)

  # loose save detection: look for save-ritual markers in the last 40 lines
  SAVED=$(tail -40 "$file" 2>/dev/null \
          | grep -ic 'skills/save\|save session\|full save\|goodbye' || true)
  SAVED="${SAVED:-0}"

  # completion signal: last prompt looks like a deliberate close
  # (explicit farewell or short affirmative that ends a conversation)
  CLOSED_CLEAN=0
  if echo "$LAST" | grep -qiE '^\s*(bye|goodbye|see you|good night|that.?s all|all good|thanks|thank you|cheers|done for today|we.?re done|stop here)\s*[.!]?\s*$'; then
    CLOSED_CLEAN=1
  fi

  # hanging signal: session had substance and last prompt is mid-task
  # (contains a question mark, or is a non-trivial command/statement)
  MSG_COUNT=$(grep -c '"type":"user"' "$file" 2>/dev/null || echo 0)
  HANGING=0
  if [ "$SAVED" -eq 0 ] && [ "$CLOSED_CLEAN" -eq 0 ] && [ "$MSG_COUNT" -gt 3 ]; then
    HANGING=1
  fi

  # human-readable age
  AGE_MIN=$(( AGE_SEC / 60 ))
  if   [ "$AGE_MIN" -lt 60 ];   then AGO="${AGE_MIN}m ago"
  elif [ "$AGE_MIN" -lt 1440 ]; then AGO="$(( AGE_MIN / 60 ))h ago"
  else                               AGO="$(( AGE_MIN / 1440 ))d ago"
  fi

  SHORT_ID=$(basename "$file" .jsonl | cut -c1-8)

  # emit a machine-readable alert: recent + hanging = likely accidental close
  if [ "$HANGING" -eq 1 ] && [ "$AGE_MIN" -lt 30 ]; then
    echo "ALERT_RECENT_UNSAVED: $AGO | last: ${LAST:-(unknown)}"
  fi

  echo "--- session $SHORT_ID  |  $AGO  |  ${CWD:-unknown dir}"
  [ -n "$FIRST" ] && echo "    opened : $FIRST"
  [ -n "$LAST"  ] && echo "    last   : $LAST"
  if [ "$HANGING" -eq 1 ]; then
    echo "    !! looks like it was cut off mid-conversation (no save, no goodbye)"
  elif [ "$SAVED" -eq 0 ] && [ "$CLOSED_CLEAN" -eq 0 ]; then
    echo "    !! no save detected -- consider folding notes into memory"
  fi
  echo

  PRINTED=$(( PRINTED + 1 ))
  [ "$PRINTED" -ge 5 ] && break
done < <(find "$PROJECTS_DIR" -name "*.jsonl" 2>/dev/null | xargs ls -t 2>/dev/null)

if [ "$PRINTED" -gt 0 ]; then
  echo "(${PRINTED} closed session(s) in last ${HOURS}h shown above)"
fi
