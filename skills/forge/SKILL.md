---
name: forge
description: "Use when a pattern repeats 3+ times, the same mistake happens twice, or the user says 'forge this', 'that keeps happening', 'make this a rule'. Turns repetition into permanent upgrades: hotlist lines, library chapters, sub-skills, or new skills."
---

# Forge - turn repetition into upgrades

*The system that improves the system. Nothing repeats a third time for free.*

## Triggers

- The same fix, mistake, or workaround shows up a 3rd time.
- A mistake happens twice (twice is enough for a rule; 3x for a skill).
- The user says: "forge this", "that keeps happening", "make this a rule".

## The ladder (cheapest upgrade that fits, top first)

1. **Hotlist line** (mistakes, gotchas) -> `main/hotlist.md`: `trigger -> action`.
2. **Library chapter** (solutions that generalize) -> `library/<book>/<chapter>/<chapter>.md`: Problem / Solution / Sources. Add the chapter to the book's README.
3. **Sub-skill** (the repetition lives INSIDE an existing skill's workflow) -> `skills/<parent>/<sub>/SKILL.md`, and the parent lists its sub-skills. Extend before multiplying.
4. **New skill** (a workflow that repeats end to end, standalone) -> `skills/<name>/SKILL.md` with a clear trigger; add it to `skills/README.md` and the manual's skills list.

**Rung 3 vs 4 test:** does the repetition interrupt or extend something that already has a ritual? Sub-skill. Is it a whole new ritual? New skill.

## How

1. Name the repetition: what happened, how many times, evidence from `logs/`.
2. Pick the rung. When unsure, climb down: a hotlist line beats a whole skill.
3. Draft the exact text or file structure.
4. Show the user before writing. Get a yes.
5. Write it + add the index row in `memory/index.md` so recall finds it.
6. Confirm in one line: "Forged: <what> -> <where>."

## Monthly mini-review (only when the user asks for a review)

Read the last month of `logs/`:

- Corrections the user made -> hotlist lines, or tone notes in `main/soul.md`.
- Repeated workflows -> skill or sub-skill candidates (propose, never auto-create).
- Max 3 proposals. Never nag.

## Rules

- Forge is propose-first: humans approve upgrades, always.
- Rules come from real repetitions, never from a single theory.
- Prefer extending over multiplying: the catalog (`skills/README.md`) stays small and legible.
- One upgrade per repetition. Don't turn one bug into three files.
- No em-dashes in anything written.

## Level history

- Lv.2 (2026-10-16) - sub-skill rung added; ladder unified with the library book structure.
- Lv.1 - initial skeleton ritual.
