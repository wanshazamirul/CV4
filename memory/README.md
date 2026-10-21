# memory - the knowledge base

The working memory. Four parts, one rule: append, never rewrite.

| Part | What | Caps |
|---|---|---|
| `index.md` | the fast layer: one line per durable item | hot 12 / warm 20; oldest folds into cold |
| `decisions.md` | forks in the road: context, decision, why | append-only; reversals add new entries |
| `reminders.md` | forward tasks that survive resets | 200 open / 100 completed |
| `feedback/` | suggestions about the workflow, one file each | review at pauses, never mid-flow |

**When to write where:** a durable fact or lesson -> `index.md`. A choice worth remembering why -> `decisions.md`. Something to do later -> `reminders.md`. A gripe or idea about the system -> `feedback/`.

**Times:** every dated entry in `index.md`, `decisions.md`, `reminders.md`, and `skills.md` carries the local time (`YYYY-MM-DD HH:MM`). File names and release history stay date-only; the block inside carries the time.

**Why it stays small:** the index is scanned every session. If it bloats, recall slows and focus dies. Rotate: hot to warm, warm to cold summaries. The full story lives in `logs/`.

Search everything with `python3 tools/fts.py "<query>"`. Personal zone: never auto-updated.
