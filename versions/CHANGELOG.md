# Changelog

## 0.8.1 - 2026-10-18
- Interview tool-proofed: every pick list is 4 options or fewer (a fifth throws `too big: expected array to have <= 4 items` in Claude Code), the voice pick reads warm/playful/blunt/dry with type-your-own covering the rest (`formal` included), and a failed question-tool call never surfaces a raw error or retries: it falls back to plain text in the same message.

## 0.8.0 - 2026-10-18
- `/cv4-recap` ships (`commands/`): the cross-session recap built from the files (current-session, reminders, newest log), installed globally like `/remove-cv4`, working in any tool. Claude Code's built-in `/recap` stays for the live session; the two pair.
- Setup never wipes an existing setup: an existing global config keeps every line, and Claude Code auto memory (`~/.claude/projects/*/memory/`) is read and folded into `main/relationship-memory.md` under a dated import heading. Originals stay in place; backups as always.
- Uninstall hands memory back: `/remove-cv4` (and the uninstall rule) offers a short dated distillation of what CV4 learned (relationship essentials + never-again rules) into the old setup's memory home, after blocks, settings, and commands are handled.

## 0.7.3 - 2026-10-18
- Execution-first BOOT: the file opens with a banner telling an AI agent plainly that it is a procedure to execute, not a document to summarize: no explaining CV4, no asking whether to begin, start Step 0 immediately, first reply opens the setup.
- The start-here line now says "run the setup in BOOT.md" instead of "read BOOT.md": reading invited summaries, running invites setups.

## 0.7.2 - 2026-10-18
- Interview pinned: one question at a time, always (ask, wait, continue; opencode asks one call per question too). Opening is one short line, not a speech.
- Test drive: the setup closes with the proof - open the agent in a different folder, say hi, watch memory arrive from anywhere. Stranger? Restart the app once, then check the block and settings together.
- "Restart setup" / "start over" explicitly mean the re-boot reset (Step 0), same confirmation card.
- Setup-flow discipline pass (reference: the MemoryCore setup wizard): taken are the one-at-a-time asks with a wait between, and the closing activation test. Not adopted: per-answer instant file writes (CV4 seeds right after the confirm card, minutes later), setup-file deletion (BOOT.md is the reinstall door), and the emoji-heavy voice (the user's chosen voice rules here).

## 0.7.1 - 2026-10-18
- Clone path, settled for good: the start-here instruction names the target (your home folder), and on a terminal it is `cd ~` first then `git clone <url>`: git names the folder itself, so no path string gets typed, so nothing can get mangled.
- BOOT Step 0 is evidence-first now: run the `pwd` + `ls` check, then speak only about what it shows. A healthy Home gets zero path talk; a genuinely mangled folder name gets one quoted move command, then a re-check. Speculative mangling warnings are called out as wrong behavior.

## 0.7.0 - 2026-10-18
- The install model, one level simpler: the manual lives in your tool's GLOBAL config (`~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.gemini/GEMINI.md`, `~/.codex/AGENTS.md`), written as the actual content, not a pointer or a signpost stub. The global config loads in every session anywhere, so launch your agent wherever you are: your companion is simply there. No folder habits, no start-inside-Home primary path.
- One install card: role + the companion install + clean Claude defaults; one approval, backups first. Declined, or a tool with no global config? The fallback is the same marked block in a repo file in Home.
- `/remove-cv4` ships in `commands/`: the setup installs it into your tool's global commands directory (Claude Code `~/.claude/commands/`, opencode `~/.config/opencode/commands/`), so any session anywhere can run the full uninstall: blocks off, settings offered back (keep or restore the install backup), persona marker off, natural-language close, and the command removes its own copies.
- Re-boot safety: reading BOOT.md again on an already-set-up machine triggers a one-question reset (Reinstall fresh / Cancel) before anything else. Reinstall removes the old config (fresh backups first), keeps the memory, and reruns the setup.
- The generated router table retires from the manual: native skill lists plus the catalogs (`skills/README.md`, the registries) carry triggers; G0 stays verbatim in the manual. `install-skills.sh` refreshes markers only; bare pointer files and marker-less files are never touched.

## 0.6.9 - 2026-10-18
- Native agent files: the pointer is gone. BOOT writes the full manual into your tool's own file (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`); every tool reads it natively, no imports. One template serves all three; refreshes regenerate whichever files the machine carries, and a one-line `@...` import from an older setup gets an offer to go native.
- One setup card: the interview is the only question-heavy moment; role plus signpost plus clean Claude defaults ride a single recommended card. No per-item questions, no second asks.
- Clean Claude defaults bundled (`"attribution": false` + `"autoMemoryEnabled": false`): the intended setup, because CV4 is the one memory store.
- Backups before every global-file edit (`<file>.bak-<YYYYMMDD>`); uninstall offers keep-or-restore and returns the machine closer to its pre-setup state.
- Clone sanity (Step 0): verify Home before anything; mangled paths get fixed up front. Windows paths canonical as `C:/Users/<you>/CV4` in configs.
- Interview: Q1/Q2 are plain-text free entry (option tools reject free entry); question-tool failures fall back to text at once. Region detection runs silently, with a Windows `tzutil /g` fallback.
- Launch anywhere: with the signpost, any folder works (that is its point); folder-start is the fallback for signpost-less sessions. The repo itself never installs globally.
- Engine: the router stamps every present agent file and skips bare `@...` pointers (older setups and CV3 stay untouched); self-test proves both.

## 0.6.8 - 2026-10-17
- "Put it in the docs" is house law: chat diagrams get enshrined in the right doc (README, book chapter, bridge doc, `docs/`), ASCII, mechanically aligned.
- Two keepers promoted: the compaction before/after diagram (README FAQ) and the ownership table (spec-kit bridge doc).

## 0.6.7 - 2026-10-17
- The "One day at the desk" diagram: the companion layer wrapping the work layer (spec-kit nested inside CV4), in the README and the spec-kit bridge doc, with who-leads rules underneath.

## 0.6.6 - 2026-10-17
- Self-test: `tools/self-test.sh` proves an instance end to end. Layout + README keys, engine wiring and router, registry consistency, then a scratch integration pass: installer idempotency, G0 in the router, personal zones untouched, scaffold restore, converge hook, git-guard (member blocked / owner allowed).

## 0.6.5 - 2026-10-17
- Tagline: spec-driven by design (pairs with spec-kit; the bridge ships in `spec-kit/`, lessons land in `memory/`).
- Boot step 7: the companion now offers the agent's global defaults (clean commits + one memory store) and applies them to the user's settings file with approval.

## 0.6.4 - 2026-10-17
- Single memory store: the manual and README FAQ now say it plainly. Agents with built-in memory (Claude Code auto memory) get switched off (`"autoMemoryEnabled": false`); lessons land in the repo where you can read, diff, and keep them.

## 0.6.3 - 2026-10-17
- Compaction survival: the manual now mandates a reload after any context compaction (session-load step 3, house rule, README FAQ), with the per-agent config names (opencode `compaction`, Claude Code `autoCompactEnabled` / `autoCompactWindow`). Truth lives in files; context is a lossy cache.

## 0.6.2 - 2026-10-17
- README honesty pass: every folder now carries a README key (tools, versions, docs, .claude-plugin added), and the box map shows every README consistently (main, memory, logs included).

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
