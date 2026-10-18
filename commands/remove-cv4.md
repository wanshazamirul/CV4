---
description: Full CV4 removal - companion blocks off, settings offered back, command self-deletes
---

# Remove CV4 from this machine

Home: [HOME]. You are running the full uninstall. Follow the manual's uninstall rule; this is the complete version. Do the steps in order, then send one message back at the end.

1. Offer a final save ("save" ritual). If they say yes, run it before anything else.
2. Show the removal list in one line, then do it:
   a. Companion blocks: in each file below that carries the marker pair `<!-- CV4 companion: start -->` ... `<!-- CV4 companion: end -->`, delete the block between the markers, markers included. Fresh `.bak-<YYYYMMDD>` copy of the file before each edit.
      - `~/.claude/CLAUDE.md`
      - `~/.config/opencode/AGENTS.md`
      - `~/.gemini/GEMINI.md`
      - `~/.codex/AGENTS.md`
      - fallback files under [HOME]: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
      After the edit, a file left with no substantive content (whitespace only) gets deleted; it existed only for the install.
   b. Settings: look for `~/.claude/settings.json.bak-*` (written by the install). Offer once: restore the original file, or keep the clean defaults (`"attribution": false`, `"autoMemoryEnabled": false`). Restore only if they pick it.
   c. Legacy: if `instructions` in `~/.config/opencode/opencode.json` carries an entry that is exactly `[HOME]/AGENTS.md` (or its backslash variant), remove that entry and nothing else.
   d. Persona: delete `[HOME]/personas/.machine` (the role claim).
   e. Hand back: offer once. If they agree, write a short dated distillation of what CV4 learned back into the old setup: the essentials from `[HOME]/main/relationship-memory.md` plus the never-again rules from `[HOME]/main/hotlist.md` (top five each), as a "From CV4 (<date>)" section. Destination: an auto-memory file if one exists (`~/.claude/projects/*/memory/MEMORY.md`; append the section), otherwise append it under the user's original content in the global config file. Confirm what went where.
   f. Commands: delete the installed copies last.
      - `~/.claude/commands/remove-cv4.md`
      - `~/.claude/commands/cv4-recap.md`
      - `~/.config/opencode/commands/remove-cv4.md`
      - `~/.config/opencode/commands/cv4-recap.md`
3. Confirm in one line: what was removed (blocks, settings lane, command), and what remains (the [HOME] folder, with all memory, logs, and history inside).
4. Close with: "Delete the [HOME] folder when you are done; nothing else on the machine remains. From the next session on, your agents read their own configs again, exactly as before CV4."
