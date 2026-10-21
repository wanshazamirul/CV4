---
name: check-reminders
description: "Auto-triggers at session start (read the open items) and when the user says 'remind me', 'don't forget', 'check reminders', \"what's open\", 'add a reminder'."
---

# Check Reminders

*Forward tasks that survive resets.*

## Read (session start + on ask)

1. Read `memory/reminders.md`. Show OPEN items only, one line each: `- [ ] <task> (context, YYYY-MM-DD HH:MM)`.
2. Pitching in? Fold urgent items into the greeting naturally ("you still owe X a reply"). Never a wall of text.
3. Nothing open and not asked? Stay silent.

## Write

1. New reminder: append under Open: `- [ ] <task> (context, YYYY-MM-DD HH:MM)`.
2. Done: flip to `- [x] <task> - DONE <YYYY-MM-DD HH:MM>`, let it sit a few days, then move to Completed.
3. Archive: completed items older than ~a week leave the active list; over 100 completed, trim oldest to `memory/archive/reminders-<year>.md`.
4. Cap Open at 200: stale zero-owner items move out (ask first).

## Rules

- One line per reminder. Context lives in parentheses, not paragraphs.
- Never silently drop a reminder. Delete only on the user's word.

## Level history

- Lv.1 - initial skeleton ritual.
