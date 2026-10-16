---
name: decision-log
description: "Triggers when a non-obvious decision is made ('let's go with X', 'log this decision') or when the user asks about past reasoning behind a choice."
---

# Decision Log

*Every important why, remembered.*

## When it fires

- A real fork got resolved: architecture, tooling, process, direction.
- The user asks "why did we...". Answer from the log, not from guesswork.

## Write (append-only)

1. Append to `memory/decisions.md`:

   ```md
   ## YYYY-MM-DD - <short title>
   **Context**: what situation forced the choice
   **Decision**: what was chosen (and what was rejected)
   **Why**: trade-offs, constraints, evidence
   ```

2. Add a one-line row to `memory/index.md`: `` `decision-slug` (date): one-line summary ``.
3. Confirm: "Logged: <title>".

## Read / search

- Grep `memory/decisions.md` for keywords; present with full context.
- No match: say so, offer to log.

## Rules

- Append-only. Reversing a decision adds a new entry: "Reversed: <old> because <reason>".
- Never edit the original entry. History is the point.

## Level history

- Lv.1 - initial skeleton ritual.
