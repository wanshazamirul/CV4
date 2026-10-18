# commands - the slash commands

Template-owned command files. The setup copies them into your tool's **global** commands directory, so they work in every session, in any folder, like the companion itself.

## The key

| File | Installs to | Does |
|---|---|---|
| `remove-cv4.md` | Claude Code: `~/.claude/commands/remove-cv4.md` · opencode: `~/.config/opencode/commands/remove-cv4.md` | `/remove-cv4`: the full exit, no prompts. Saves first, blocks off, settings restored from the install backup, memory handed back prefilled (auto-routed), commands and the CV4 folder itself deleted (hand-back must land first) |

`cv4-recap` retired in 0.9.3: Claude Code's built-in `/recap` covers the live session and the session-start load covers everything before it, so the extra command earned its deletion. Leftover copies from older installs get removed at uninstall.

## Rules

- These files are templates: `[HOME]` fills with your Home path at install time.
- Back up an existing copy before overwriting (`<file>.bak-<YYYYMMDD>`), same as any global edit.
- Auto-updated with new versions (`tools/update.sh` pulls this folder); installed copies refresh on your word, like the manual.
- Natural-language uninstall ("uninstall") still works in every tool; the command is the shortcut.
- Gemini CLI / Codex: no command copy is installed (different command formats); say "uninstall" there.
