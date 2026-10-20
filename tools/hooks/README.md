# tools/hooks - the CV4 behavior spine

One policy core, thin harness adapters. The manual says how to behave; this folder makes the ritual fire even when the model forgets.

```ascii
  harness hook  ->  dispatch.sh  ->  dispatch.py  ->  inject / block / checkpoint
                                         │
                                         ├─ logs/.state/<session>.json
                                         ├─ logs/checkpoints/<date>-<sid>.md
                                         └─ logs/hooks.log
```

## Files

| File | What |
|---|---|
| `dispatch.py` | the whole policy: brief, router, auto-recall, save gate, checkpoint, adaptive timing |
| `dispatch.sh` | Python finder + silent no-op wrapper. Every adapter calls this |
| `brief.sh` | print the boot brief as text (manual load, or a harness with no hook surface yet) |
| `policy.json` | engine defaults; `main/behavior.json` overrides them |
| `install.py` | merge/remove adapters, atomic writes, one rolling `.cv4bak` per config |
| `install.sh` | Python finder for the installer |
| `doctor.sh` | first aid: adapters, fixtures, state, kill switch, last decision |
| `test.sh` | fixture suite, no harness and no network |
| `checkpoint.sh` | fast pre-update checkpoint used by `update-flow.sh` (working tree + current session) |
| `idle-save.sh` | one watcher per session; resets on activity, fires the save worker after `idle_minutes` of real inactivity |
| `e2e-checklist.md` | the live-harness release gate: five checks per harness, with expected evidence |
| `adapters/claude.json` | reference shape (the installer builds it) |
| `adapters/opencode/index.ts` | opencode plugin template; `__CV4_HOME__` is filled at install |

## Contract

| Event | What the dispatcher does |
|---|---|
| `session-start` | injects the budgeted boot brief (identity, soul, hotlist, current session, reminders, index hot), pending update, unsaved checkpoint |
| `prompt` | injects the matching skill body; on bug-shaped prompts it runs `fts.py` + hotlist and injects the hits |
| `pre-tool` | blocks the first edit after a bug prompt once, until the model cites or clears recall |
| `post-tool` | tracks tool, file, and command in the checkpoint |
| `stop` | quiet autosave worker at a goodbye, late trigger, cadence trigger, or pre-compact; no block, no hook error; the next prompt or greeting carries `saved:` + `next:` |
| `session-end` | writes the pending-save marker so the next boot can fold the checkpoint in |
| `pre-compact` | writes a checkpoint before context loss |
| `idle-check` / `idle-save` | the idle watcher asks whether the session has been quiet long enough, then runs the save worker once; a greeting note carries the result to the next load |

Shapes are per harness: Claude and Codex use `hookSpecificOutput.additionalContext`, Gemini uses its `decision`/`additionalContext`, opencode receives a small JSON contract from the plugin.

## Rules

- **No brick.** Any error, timeout, missing Python, malformed JSON, read-only Home, or blocked machine exits 0 with no output. The manual path stays.
- **Only the recall gate blocks**, once per bug prompt. Autosave never blocks a turn.
- **No network** on prompt, tool, or turn-end hooks. Only the session-start update check runs `git fetch`, with a 3s timeout and `GIT_TERMINAL_PROMPT=0`.
- **Every autosave hands back a next line.** The worker writes a note; the next prompt or greeting consumes it and shows `saved:` + `next:`. An explicit save replies immediately. No dead-end hooks.
- **Idle is a watcher, not a prompt.** One per session, spawned at turn end. It resets on any new event and refuses to fire while the session is active. Default 15 minutes; `{"auto_save": {"idle_minutes": 60}}` changes it, `0` turns it off.
- **Local only.** Checkpoints are gitignored, capped, and redacted. No telemetry.

## Commands

```bash
bash tools/hooks/install.sh all install     # claude + opencode where present
bash tools/hooks/install.sh all check
bash tools/hooks/install.sh all remove
bash tools/hooks/doctor.sh
bash tools/hooks/test.sh
```

`install` skips a template clone (identity still `[AI_NAME]`), so a dev checkout never wires itself into the machine. `--force` overrides that for tests. Kill switch: `CV4_HOOKS=0`, or `main/behavior.json` -> `{"enabled": false}`. Per-feature flags live in the same file.

## Capability matrix

| Harness | Start | Prompt | Tool gate | Turn end | Session end | Compact |
|---|---|---|---|---|---|---|
| Claude Code | yes | yes | yes | yes | yes | yes |
| opencode | yes | yes | best effort (throw) | log + checkpoint | on delete | on compact |
| Gemini CLI | yes | yes | yes | yes (retry) | yes | yes (checkpoint) |
| Codex | yes (trust) | yes | yes | yes (continue) | yes | yes |

Codex skips untrusted hooks until you approve them once in `/hooks`; the install line says so. Live harness tests are part of the release gate for each tool.
