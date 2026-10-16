# Skills - the rituals

A skill is a small file with a **trigger** (its `description`) and a **procedure** (its body). When the trigger fires, the agent loads the file and follows it.

## Catalog

| Skill | Trigger | Does |
|---|---|---|
| `save` | "save", goodbye | Session log + memory + reminders sweep + rotation |
| `check-reminders` | session start, "remind me" | Surfaces open items; logs new ones |
| `decision-log` | a fork got resolved | Context / decision / why, append-only |
| `recall-memory` | "remember?", familiar bug | Hotlist -> index -> fts -> library, with citations |
| `build-protocol` | "build X", multi-step work | Restate, recall, plan, gates, verify |
| `forge` | "that keeps happening", 3x repeat | Turns repetition into upgrades (the ladder) |

## Structure

- One folder per skill: `skills/<name>/SKILL.md`.
- **Sub-skills nest under their parent**: `skills/<parent>/<sub>/SKILL.md`. The parent lists its sub-skills. Use sub-skills when a repetition extends an existing ritual instead of becoming a new one.
- The `name` must equal the folder name. The `description` is the trigger: specific, short, non-overlapping.

## Adding a skill

1. Create `skills/<name>/SKILL.md` with `name` + `description` + the procedure.
2. Add a row to the catalog above.
3. Mention it in your `AGENTS.md` skills line (so every session sees it).
4. Log it in `memory/index.md`.

Or let `forge` propose it when a pattern repeats. Skills are template-owned: new versions of this repo update them automatically, so keep personal tweaks in your own files.
