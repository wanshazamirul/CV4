# Logs protocol

`logs/` is the session history: every day that mattered, one file per day.

```
logs/
├── current/     this month, one file per day (YYYY-MM-DD.md)
├── archived/    monthly archives (YYYY-MM/)
└── protocol.md  this file
```

## Write

- The `save` skill appends each session block: `## HH:MM` (local time), then Did / Decided / Next. The file name is the date; the block header carries the exact time.
- Append only. Never edit old entries.

## Read

- Recall searches here first for "what did we do" questions.
- When evolving memory, read the recent month before adding lessons.

## Rotate

- `current/` moves to `archived/YYYY-MM/` monthly (or when it grows heavy).
- Archives are cold storage: searchable, never rewritten.
