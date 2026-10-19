---
description: Full CV4 removal - everything back to pre-CV4, memory handed back prefilled, no prompts
---

# Remove CV4 from this machine

Home: [HOME]. You are running the full uninstall. Full means full: everything ends back as it was before CV4, prefilled with what was learned. Run the steps in order, sequentially, never in parallel: the edits overlap (the hand-back may write into the same global file the blocks came from), and the folder delete must stay last. Backup rule throughout: one rolling `<file>.cv4bak` per file, written only when missing (it holds the pre-CV4 original); no dated copies, no seconds; consumed ones get deleted as you go. No questions; one message back at the end.

1. Final save: run the "save" ritual now (session log + memory + reminders sweep), quietly, then continue.
2. Blocks off: in each file below that carries the marker pair `<!-- CV4 companion: start -->` ... `<!-- CV4 companion: end -->`, delete the block between the markers, markers included. Rolling backup per the rule (`.cv4bak`, only when missing) before each edit.
   - `~/.claude/CLAUDE.md`
   - `~/.config/opencode/AGENTS.md`
   - `~/.gemini/GEMINI.md`
   - `~/.codex/AGENTS.md`
   - fallback files under [HOME]: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
   A file left with no substantive content (whitespace only) gets deleted; it existed only for the install.
3. Settings, restored: an install backup exists (`~/.claude/settings.json.cv4bak`)? Copy it back over the file, verify it parses and the CV4 keys are gone, then delete the consumed backup. No backup? Remove only the keys CV4 added (`"attribution"`, `"autoMemoryEnabled"`; older setups may say `"includeCoAuthoredBy"`), keep everything else, and delete the file if nothing else remains.
4. Legacy: if `instructions` in `~/.config/opencode/opencode.json` carries an entry that is exactly `[HOME]/AGENTS.md` (or its backslash variant), remove that entry and nothing else.
5. Trust, best effort: in `~/.claude.json`, delete `hasTrustDialogAccepted` from the `projects["<HOME>"]` entry if one exists (rolling `.cv4bak` rule, done by `trust-home.sh` at setup time); drop the entry itself if it empties. If tooling blocks the write, say so in the confirm line; a stale flag is harmless once the folder is gone.
6. Persona: delete `[HOME]/personas/.machine`.
7. Hand back, prefilled, work only: write a short dated distillation of what CV4 learned about the work: current project context, working-preference notes (how the user likes things done), and the never-again rules from `[HOME]/main/hotlist.md`, top five each, as a "From CV4 (<date>)" section. Leave the persona out (its name, voice, emoji habits) and leave personal details out (people's names, private facts); work-shaped preferences count, personal life does not. Route it to match the restored setup:
   - auto memory is on after the restore (`autoMemoryEnabled` true or absent) and a memory file exists (`~/.claude/projects/*/memory/MEMORY.md`)? Append to the most recently modified one.
   - otherwise: append it to the global config file (`~/.claude/CLAUDE.md`, or the tool's global file) if it exists; create that file with just the section if it does not.
8. Commands: delete the installed copies.
   - `~/.claude/commands/remove-cv4.md`
   - `~/.config/opencode/commands/remove-cv4.md`
   Older installs may also carry a `cv4-recap.md` in either commands directory (retired in 0.9.3); delete it if present.
   **Skills, un-wired:** remove the CV4 skill folders from the global skill directories where they were wired: `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/`. Delete a folder only when it is a symlink into [HOME], or a real folder carrying CV4's `.cv4-wired` marker; a folder without that marker belongs to the user (or another tool) and stays. Same rule for the project copies inside [HOME]: they go with the folder in step 11. If a global folder also holds the user's own skills, delete only the CV4 names from the list in `[HOME]/skills/` and `[HOME]/my-skills/`.
9. Launch shortcut: remove the marked CV4 block from `~/.bashrc` / `~/.zshrc` / the PowerShell `$PROFILE` if one was added (rolling `.cv4bak` rule; if the machine blocks the write, note it in the confirm line).
10. Cleanup: with every restore verified, delete the remaining `.cv4bak` files on the managed files (blocks, settings, profiles, command files). No backup confetti left behind.
11. The folder: after step 7 landed, try once: `cd ~` first (the session may be running inside it), then delete it the platform way: `rm -rf "[HOME]"` (macOS/Linux), `rmdir /s /q "[HOME]"` (cmd), `Remove-Item -Recurse -Force "[HOME]"` (PowerShell), or Explorer. Whole-folder deletion is gated on many machines, and rightly so: if the harness, the permission layer, or a file lock stops it, do not fight it. End with the exact one-liner for them (the same command for their platform) and one honest line: everything else is already off the machine. If it did delete, verify with `ls` (or `dir`) and say so.
12. Confirm in one line: what was removed (blocks, settings restored, trust entry, shortcut block, global skills un-wired, hand-back location, commands, folder or the one-liner), and that the machine is back to pre-CV4, prefilled. The wake word goes away with the block on its own; nothing else to clean.
