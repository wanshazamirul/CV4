# commands - the slash commands

Template-owned command files. The setup copies them into your tool's **global** commands directory, so they work in every session, in any folder, like the companion itself.

## The key

| File | Installs to | Does |
|---|---|---|
| `remove-cv4.md` | Claude Code: `~/.claude/commands/remove-cv4.md` · opencode: `~/.config/opencode/commands/remove-cv4.md` | `/remove-cv4`: the full uninstall. Blocks off, settings offered back (keep or restore the install backup), persona marker off, and the command removes its own copies |
| `cv4-recap.md` | Claude Code: `~/.claude/commands/cv4-recap.md` · opencode: `~/.config/opencode/commands/cv4-recap.md` | `/cv4-recap`: the cross-session recap from CV4's files (`main/current-session.md`, reminders, newest log). Claude Code's built-in `/recap` covers the live session; this one covers everything before it |

## Rules

- These files are templates: `[HOME]` fills with your Home path at install time.
- Back up an existing copy before overwriting (`<file>.bak-<YYYYMMDD>`), same as any global edit.
- Auto-updated with new versions (`tools/update.sh` pulls this folder); installed copies refresh on your word, like the manual.
- Natural-language uninstall ("uninstall") still works in every tool; the command is the shortcut.
- Gemini CLI / Codex: no command copy is installed (different command formats); say "uninstall" there.
