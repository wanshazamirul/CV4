# tools - the toolbelt

| Tool | What |
|---|---|
| `fts.py` | the search index (stdlib only). Rebuild: `python3 tools/fts.py --build` |
| `update.sh` | session-start safe auto-update: pulls engine files from your fork's main when cloned from a team fork, else from the original (`CV4_UPSTREAM` overrides); never touches personal zones; re-wires the engine (project + global skill folders) + tops up the shelf; silent unless the version actually changed |
| `install-skills.sh` | wire the bank into each agent (project `.opencode/skills/`, `.claude/skills/`, `.agents/skills/`; `--global` adds the harness's global skill folder, e.g. `~/.claude/skills/`) and refresh the router block in repo agent files that carry its markers (bare `@...` pointers and marker-less files are left alone); `--check` to inspect, `--copy` for filesystems without symlinks; wired copies carry a `.cv4-wired` marker and refresh on every run, real folders you made yourself stay untouched |
| `session-load.sh` | the session-start load in one call: surfaces the last update's one-line note, fires the updater in the background, then prints `main/` + `memory/` files with headers; `--no-update` to skip the updater |
| `trust-home.sh` | user-run once: marks this CV4 folder as trusted in Claude Code (the documented fix for the repeating "do you trust this folder?" prompt). Run it yourself in a terminal; the trust flag is consent-shaped, so agents do not set it |
| `trust-home.cmd` | Windows wrapper for cmd/PowerShell: finds Git Bash and runs `trust-home.sh` for you |
| `scaffold-library.sh` | top up missing standard books (README keys included); never overwrites filled content |
| `git-guard.sh` | team forks: pre-push hook so member machines push to `dev`, not `main`; `--install` |
| `self-test.sh` | proves the engine end to end: layout, wiring, registries, then an integration pass (installer, scaffold, hook, guard) in a scratch copy; `--quick` skips the pass |

`.fts.db` is derived: delete it and rebuild in seconds. Windows: use `python` where docs say `python3`.
