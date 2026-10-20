#!/bin/bash
# One idle watcher per session. Sleeps in small steps, asks the dispatcher whether
# the session has been inactive long enough, then runs the save worker once.
# It never fires while the agent is working: every new hook event updates
# last_event_at, and idle-check resets the window.
# Usage: idle-save.sh <session> <harness> <home> <minutes>
set -u
SID="${1:-}"; HARNESS="${2:-}"; ROOT="${3:-}"; MINUTES="${4:-15}"
[ -n "$SID" ] && [ -n "$HARNESS" ] && [ -n "$ROOT" ] || exit 0
[ -f "$ROOT/tools/hooks/dispatch.sh" ] || exit 0
STEP="${CV4_IDLE_SECONDS:-60}"
case "$STEP" in ''|*[!0-9]*) STEP=60 ;; esac
[ "$STEP" -ge 1 ] || STEP=1

empty=0
while true; do
  sleep "$STEP"
  [ -f "$ROOT/logs/.state/$SID.json" ] || break
  STATUS="$(printf '{"session_id":"%s"}' "$SID" | bash "$ROOT/tools/hooks/dispatch.sh" "$HARNESS" idle-check --root "$ROOT" 2>/dev/null)"
  case "$STATUS" in
    save)
      printf '{"session_id":"%s"}' "$SID" | bash "$ROOT/tools/hooks/dispatch.sh" "$HARNESS" idle-save --root "$ROOT" >/dev/null 2>&1
      break
      ;;
    stop)
      break
      ;;
    wait)
      empty=0
      ;;
    *)
      empty=$((empty + 1))
      [ "$empty" -ge 3 ] && break
      ;;
  esac
done

printf '{"session_id":"%s","pid":%s}' "$SID" "$$" | bash "$ROOT/tools/hooks/dispatch.sh" "$HARNESS" idle-clear --root "$ROOT" >/dev/null 2>&1
exit 0
