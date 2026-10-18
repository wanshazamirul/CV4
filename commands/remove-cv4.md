---
description: Full CV4 removal - everything back to pre-CV4, memory handed back prefilled, no prompts
---

# Remove CV4 from this machine

Home: [HOME]. You are running the full uninstall. Full means full: everything ends back as it was before CV4, prefilled with what was learned. Run the steps in order, sequentially, never in parallel: the edits overlap (the hand-back may write into the same global file the blocks came from), and the folder delete must stay last. No questions; one message back at the end.

1. Final save: run the "save" ritual now (session log + memory + reminders sweep), quietly, then continue.
2. Blocks off: in each file below that carries the marker pair `<!-- CV4 companion: start -->` ... `<!-- CV4 companion: end -->`, delete the block between the markers, markers included. Fresh `.bak-<YYYYMMDD>` copy of the file before each edit.
   - `~/.claude/CLAUDE.md`
   - `~/.config/opencode/AGENTS.md`
   - `~/.gemini/GEMINI.md`
   - `~/.codex/AGENTS.md`
   - fallback files under [HOME]: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
   A file left with no substantive content (whitespace only) gets deleted; it existed only for the install.
3. Settings, restored: first copy the current `~/.claude/settings.json` to `.bak-<YYYYMMDD>` (the pre-uninstall state, kept), then:
   - an install backup exists (`~/.claude/settings.json.bak-*`)? Copy it back over the file.
   - no install backup? Remove only the keys CV4 added (`"attribution"`, `"autoMemoryEnabled"`; older setups may say `"includeCoAuthoredBy"`), keep everything else, and delete the file if nothing else remains.
4. Legacy: if `instructions` in `~/.config/opencode/opencode.json` carries an entry that is exactly `[HOME]/AGENTS.md` (or its backslash variant), remove that entry and nothing else.
5. Trust, best effort: in `~/.claude.json`, delete `hasTrustDialogAccepted` from the `projects["<HOME>"]` entry if one exists (fresh `.bak-<YYYYMMDD>` copy first); drop the entry itself if it empties. If tooling blocks the write, say so in the confirm line; a stale flag is harmless once the folder is gone.
6. Persona: delete `[HOME]/personas/.machine`.
7. Hand back, prefilled: write a short dated distillation of what CV4 learned (the essentials from `[HOME]/main/relationship-memory.md` plus the never-again rules from `[HOME]/main/hotlist.md`, top five each) as a "From CV4 (<date>)" section, routed to match the restored setup:
   - auto memory is on after the restore (`autoMemoryEnabled` true or absent) and a memory file exists (`~/.claude/projects/*/memory/MEMORY.md`)? Append to the most recently modified one.
   - otherwise: append it to the global config file (`~/.claude/CLAUDE.md`, or the tool's global file) if it exists; create that file with just the section if it does not.
8. Commands: delete the installed copies.
   - `~/.claude/commands/remove-cv4.md`
   - `~/.config/opencode/commands/remove-cv4.md`
   Older installs may also carry a `cv4-recap.md` in either commands directory (retired in 0.9.3); delete it if present.
9. Launch shortcut: remove the marked CV4 block from `~/.bashrc` / `~/.zshrc` / the PowerShell `$PROFILE` if one was added (fresh `.bak-<YYYYMMDD>` first; if the machine blocks the write, note it in the confirm line).
10. The folder: delete [HOME] itself. Run it only after step 7 landed; if the hand-back did not land, STOP and say so instead of deleting. `cd ~` first (the session may be running inside it), then `rm -rf "[HOME]"` (Git Bash on Windows handles this; in Explorer, delete normally). If the delete fails because a file is held open (Windows), retry once; if it still resists, say plainly that the folder is the only thing left and it can go once the app closes.
11. Confirm in one line: what was removed (blocks, settings restored, trust entry, shortcut block, hand-back location, commands, folder), and that the machine is back to pre-CV4, prefilled. The wake word goes away with the block on its own; nothing else to clean.
