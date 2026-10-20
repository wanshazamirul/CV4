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

## Firing

- Native discovery: the harness lists each trigger and the model chooses.
- Behavior spine: `tools/hooks` injects the exact skill body when the trigger is explicit (save, remind, decision, build, debug), so the ritual does not depend on memory. Details: `tools/hooks/README.md`.

## Structure

- One folder per skill: `skills/<name>/SKILL.md` (bank) or `my-skills/<name>/SKILL.md` (yours).
- **Sub-skills nest under their parent**: `skills/<parent>/<sub>/SKILL.md`. The parent lists its sub-skills. Use sub-skills when a repetition extends an existing ritual instead of becoming a new one.
- The `name` must equal the folder name. The `description` is the trigger: specific, short, non-overlapping.

## Wiring (once per machine)

`bash tools/install-skills.sh --global` links every skill into each harness's native discovery paths: the project folders (opencode `.opencode/skills/`, Claude Code `.claude/skills/`, generic `.agents/skills/`) and the global ones (`~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/`), wiring only the harnesses actually installed on the machine. The global wiring is the important half: the companion lives in your global config, so sessions start in any folder, and a ritual like `save` must resolve there too. It also stamps the router block (G0 + trigger table) into `AGENTS.md`.

The session-start updater runs this with `--global` after every update, so the wiring never goes stale. Wired copies carry a `.cv4-wired` marker and are refreshed in place; a real folder you made yourself is never touched. No symlinks on your filesystem (Windows without dev mode)? Add `--copy`, and the marked copies refresh the same way. `--check` reports state.

## Adding a skill

1. Create `my-skills/<name>/SKILL.md` with `name` + `description` + the procedure.
2. Add a row to `my-skills/registry.md` (the gate reads it).
3. Mention it in your `AGENTS.md` skills line (so every session sees it).
4. Log it in `memory/index.md`.

Or let `forge` propose it when a pattern repeats: it scans both registries first, and your skills win (fold-in offered, never an overlap). Bank skills (`skills/`) are template-owned and update automatically; anything personal belongs in `my-skills/`.
