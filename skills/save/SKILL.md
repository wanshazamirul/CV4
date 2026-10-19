---
name: save
description: "MUST use when the user says 'save', 'save progress', 'save session', 'document session', or on goodbye / done-for-today. Writes the session log, updates memory, sweeps reminders, rotates the index."
---

# Save - session close ritual

*Everything worth keeping lands in a file tomorrow can use. Full send at goodbye, always.*

## Full save (the standard)

1. **Session log** - append today's block to `logs/current/YYYY-MM-DD.md`:

   ```md
   ## HH:MM - <theme>
   ### Did
   ### Decided
   ### Next
   ```

2. **Memory** - update `memory/index.md` (one durable row per item: tag, date, keypoint). Decisions go to `memory/decisions.md`. Lessons that can repeat go to `main/hotlist.md`.
3. **Skill usage** - tick `memory/skills.md` for the skills that fired this session (`uses` + `last`, one batch edit).
4. **Reminders sweep** - completed out, stale pruned, new follow-ups into `memory/reminders.md` (caps: 200 open, 100 completed).
5. **Library harvest** - if the session produced a reusable pattern, file it in `library/<section>/<slug>/<slug>.md`.
6. **Rotation** - `main/current-session.md` keeps the last 3 sessions; the index stays small (hot 12 / warm 20; oldest folds into a cold summary). Monthly (or when the folder grows heavy), move last month's `logs/current/` files into `logs/archived/YYYY-MM/`: cold storage, searchable, never rewritten.
7. **Confirm** - one line: what was saved, where.

## Lite save (mid-session)

"save" while work is unfinished: append the log block and update only the files that actually changed. Skip rotation (usage ticks ride the full save). Keep working.

## Rules

- Goodbye is always a full save. Never lite at goodbye.
- The log is the raw truth later reviews read. Never skip it.
- Append-only. Never rewrite history.
- No em-dashes in anything written.

## Level history

- Lv.2 (2026-10-17) - skill usage ticks (`memory/skills.md`) in the full save.
- Lv.1 - initial skeleton ritual.
