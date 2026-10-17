# Changelog

## 0.6.1 - 2026-10-17
- Commits: new house rule, commits stay in the user's name with no AI attribution; README FAQ shows the one-line Claude Code switch (`"attribution": false`).
- Docs discipline: READMEs are architecture documents, updated in the same change as the feature they describe; every illustration is ASCII, never an image.

## 0.6.0 - 2026-10-17
- Skills engine: this repo is now a real Claude Code plugin; `tools/install-skills.sh` wires the bank into `.opencode/`, `.claude/`, and `.agents/`, and stamps a generated skills router (with G0: no blind action) into `AGENTS.md`. `update.sh` re-wires after updates.
- Standard shelf: the library is seven books (frontend, backend, security, infra, process, ai, design) with guardrail README keys, a `_template/` kit, and `tools/scaffold-library.sh` to restore missing books. Personal books (like `trading/`) are yours and never travel.
- Intake: a new bank skill that fences, assesses, routes, merges, logs, and verifies foreign material before anything lands. Nothing adopts blind, rejections get logged.
- Personas: empty cups in the repo, one role claim per machine (owner / member / just-me), three lanes (engine down, knowledge up, personal never), and `tools/git-guard.sh` for member machines.
- Spec-kit bridge: `spec-kit/` ships a constitution template (behavioral clauses, blank Stack section) and an idempotent converge-to-memory hook.
- House rule: stack defaults are suggestions; the project's constitution wins.

## 0.5.6 - 2026-10-17
- Uninstall: a two-step exit in README (remove the signpost, delete the folder), an FAQ pointer, and a manual rule so the companion runs it on request (final save first).

## 0.5.5 - 2026-10-17
- Signpost: onboarding offers one marked block in the agent's global rules, so any folder wakes with memory. opencode also gets the native `instructions` wiring.
- Manual: Home anchoring (`[HOME]` baked at boot; all paths resolve against it), the updater works from any folder, signpost house rules.
- README: signpost FAQ + where the block lives per tool.

## 0.5.4 - 2026-10-17
- Boot: the hello now hands over home base. Open the agent in this folder from now on; the manual loads with the session.
- Manual: a new house rule for sessions that started outside the repo (say it, ask them to restart inside).
- FAQ: "Where do I start my agent from now on?"

## 0.5.3 - 2026-10-17
- House rules: punctuation manners. Pause with commas, colons, or periods; no hyphen chains between clauses; greetings are prose, not status reports.
- Manual: greeting example and section headers cleaned; updater note uses parentheses; manual rev bumped to 0.5.3.

## 0.5.2 - 2026-10-17
- Manual: the session-start load is now blocking on the first message (even a bare "hi"): update + reads first, then greet. No more two-prompt warm-up.
- Manual upkeep: `AGENTS.md` carries its manual rev; after engine updates the agent offers a refresh (replace for default, merge for customized).

## 0.5.1 - 2026-10-17
- BOOT interview: all three questions render as question prompts (never a prose list); simpler wording: "What is your name?" and "What is my name?", free entry with no suggested names.

## 0.5.0 - 2026-10-17
- Your own skills: `my-skills/` zone (never overwritten, primary) with its own registry. The bank (`skills/`) gets a registry too; usage lives in `memory/skills.md`, ticked at save.
- The gate: `forge` scans both registries before generating anything. Dedicated wins: fold-in offered, never an auto-created overlap.
- Updater: one-time `my-skills/` seed for old clones, then never touched again.

## 0.4.4 - 2026-10-17
- Windows: shell scripts stay LF (`.gitattributes` + updater self-heal), so `bash tools/update.sh` no longer hits `$'\r'` errors on fresh checkouts. BOOT + FAQ first aid for old clones; FAQ also notes `python` vs `python3`.

## 0.4.3 - 2026-10-17
- BOOT: name questions are plain text (no examples, no suggestions); choice UI only for behavior dials + confirm.

## 0.4.2 - 2026-10-17
- README: quickstart is now "paste the link to your agent"; First 5 minutes section removed.

## 0.4.1 - 2026-10-17
- README: first-5-minutes flow updated to the real enrollment (3 questions + silent region detection).

## 0.4.0 - 2026-10-17
- Public line opens: this content mirrors to the CV4 repo (clean history per release). Auto-update pulls from CV4.

## 0.3.8 - 2026-10-17
- Windows: docs note `python` (not `python3`); index step degrades gracefully without Python.

## 0.3.7 - 2026-10-17
- Script level: local words in native script when the user reads it (お疲れ様でした), romaji otherwise; full-width characters stay out of ASCII diagrams.
- relationship template: Script level field added.

## 0.3.6 - 2026-10-17
- Language: English default, user-led adaptive mix (mirror their blend at the same level; local words where they carry the meaning, glossed once). Never drifts on its own.
- relationship template: Language mix field added.

## 0.3.5 - 2026-10-17
- Language rule: always English, all regions. Region affects naming convention only.
- Region table simplified to address conventions: JP (`-san` / `-chan`), PH (`po` politeness), MY/ID and others (plain name).

## 0.3.4 - 2026-10-17
- BOOT: behavior step is explicit dials now: voice (multi), emoji (none/light/generous), answers (short/balanced/detailed), all captured at enrollment and confirmed on the summary card.
- identity template: Communication block matches the dials; manual tells the agent not to drift from them.

## 0.3.3 - 2026-10-17
- BOOT: enrollment uses the agent's interactive question UI (opencode `question`, Claude Code `AskUserQuestion`) with preset options and typed fallbacks; plain text still supported.
- BOOT: name suggestions (Rei / Nova / Sage / Mika) and behavior as a multi-select; one summary card to confirm.

## 0.3.2 - 2026-10-17
- BOOT: enrollment is now 3 questions (name, AI name, behavior); timezone/region/address style are auto-detected and stored.
- BOOT: region table with local conventions (Japan: -san / -chan; Malaysia: BM once invited; polite fallback).
- Manual: address + timezone rule moved into the house rules.

## 0.3.1 - 2026-10-17
- README: skills section is now a proper per-line tree (no collapsed entries).

## 0.3.0 - 2026-10-16
- BOOT-only door: `AGENTS.md` (and the CLAUDE/GEMINI pointers) are now created locally by BOOT; the manual template lives inside BOOT.md.
- `versions/` folder: VERSION + CHANGELOG move out of the root.
- forge: the ladder grows a sub-skill rung (extend an existing skill before creating a new one).
- library: book + chapter structure (shelf -> book README -> chapters).
- Feature READMEs: main/, memory/, logs/, skills/, library/ now document themselves.
- Removed from the repo (now created locally): AGENTS.md, CLAUDE.md, GEMINI.md, UPDATE-POLICY.md, AGENTS.local.md.

## 0.2.0 - 2026-10-16
- NEW: `forge` skill - self-improvement: repetitions become hotlist lines, library patterns, or new skills.
- README: "It improves itself" + "The knowledge base" sections, with diagrams.

## 0.1.2 - 2026-10-16
- README: proper box-drawing file tree in "What's in the box".
- README: credits section removed.

## 0.1.1 - 2026-10-16
- README: four illustrations (concept loop, first boot, day in the life, update flow) + expanded detail and FAQ.

## 0.1.0 - 2026-10-16
- Initial skeleton: solo mode (files + skills + zero-dep FTS search).
- Core: main/, memory/, logs/, library/.
- Skills: save, check-reminders, decision-log, recall-memory, build-protocol.
- Tools: fts.py (stdlib search index), update.sh (safe engine auto-update).
