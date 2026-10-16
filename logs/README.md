# logs - session history

Every day that mattered, one file per day. The raw truth later reviews work from.

```
logs/
├── current/     this month (YYYY-MM-DD.md)
├── archived/    monthly cold storage (YYYY-MM/)
└── protocol.md  the full rules
```

**Write:** the `save` skill appends each session block (Did / Decided / Next). Append-only. Never edit old entries.

**Read:** recall searches here first for "what did we do" questions. The forge mini-review reads the last month.

**Rotate:** `current/` moves to `archived/YYYY-MM/` monthly, or when it grows heavy. Archives are cold storage: searchable, never rewritten.

Personal zone: never auto-updated.
