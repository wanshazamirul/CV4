# Skills - the rituals

A skill is a small file with a **trigger** (its `description`) and a **procedure** (its body). When the trigger fires, the agent loads the file and follows it.

## Two zones

- `skills/` - the **bank**: these rituals, auto-updated with new versions.
- `my-skills/` - **yours**: never overwritten, and primary. Your triggers win overlaps with the bank. Bring your own, or let `forge` add one.

## Catalog

| Skill | Trigger | Does |
|---|---|---|
| `save` | "save", goodbye | Session log + memory + reminders sweep + rotation |
| `check-reminders` | session start, "remind me" | Surfaces open items; logs new ones |
| `decision-log` | a fork got resolved | Context / decision / why, append-only |
| `recall-memory` | "remember?", familiar bug | Hotlist -> index -> fts -> library, with citations |
| `build-protocol` | "build X", multi-step work | Restate, recall, plan, gates, verify |
| `forge` | "that keeps happening", 3x repeat | Turns repetition into upgrades (the ladder) |
| `intake` | foreign file arrives, "read this, what do you think?" | Fences, assesses (card), routes, merges or rejects with reasons, logs |

## Structure

- One folder per skill: `skills/<name>/SKILL.md` (bank) or `my-skills/<name>/SKILL.md` (yours).
- **Sub-skills nest under their parent**: `skills/<parent>/<sub>/SKILL.md`. The parent lists its sub-skills. Use sub-skills when a repetition extends an existing ritual instead of becoming a new one.
- The `name` must equal the folder name. The `description` is the trigger: specific, short, non-overlapping.

## Wiring (once per machine)

`bash tools/install-skills.sh` links every skill into each harness's native discovery path (opencode `.opencode/skills/`, Claude Code `.claude/skills/`, generic `.agents/skills/`) and stamps the router block (G0 + trigger table) into `AGENTS.md`. Re-run after engine updates; `--check` reports state. No symlinks on your filesystem? Add `--copy`.

## Adding a skill

1. Create `my-skills/<name>/SKILL.md` with `name` + `description` + the procedure.
2. Add a row to `my-skills/registry.md` (the gate reads it).
3. Mention it in your `AGENTS.md` skills line (so every session sees it).
4. Log it in `memory/index.md`.

Or let `forge` propose it when a pattern repeats: it scans both registries first, and your skills win (fold-in offered, never an overlap). Bank skills (`skills/`) are template-owned and update automatically; anything personal belongs in `my-skills/`.
