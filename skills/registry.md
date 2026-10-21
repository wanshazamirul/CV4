# Bank registry

> The template's rituals, auto-updated with new versions. You never edit this file; the gate (`skills/forge/`) reads it so generation never duplicates what already exists.
> Your own skills live in `my-skills/` and always win overlaps.

| skill | source | absorbed | triggers |
|---|---|---|---|
| save | core | - | "save", goodbye |
| check-reminders | core | - | session start, "remind me" |
| decision-log | core | - | a fork got resolved |
| recall-memory | core | - | "remember?", familiar bug |
| build-protocol | core | - | "build X", multi-step work |
| forge | core | - | same pattern 3+ times, "forge this" |
| intake | core | - | foreign material arrives: import/adopt requests, "what do you think?" |

`absorbed` records consolidations: when several skills merge into one door, the merge is listed here (nothing gets lost quietly).

Wiring: `bash tools/install-skills.sh` links every skill into each harness's native path (`.opencode/skills/`, `.claude/skills/`, `.agents/skills/`) and generates the router block in the repo agent files that carry its markers (`AGENTS.md`; `CLAUDE.md`/`GEMINI.md` stay pointers). Re-run after updates; `--check` reports state.

Sources: `core` (written here) · `external` (installed by another tool, e.g. spec-kit `speckit-*`; the engine never touches it) · `personal` (your `my-skills/`, never travels).
