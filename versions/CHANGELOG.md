# Changelog

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
