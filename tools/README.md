# tools - the toolbelt

| Tool | What |
|---|---|
| `fts.py` | the search index (stdlib only). Rebuild: `python3 tools/fts.py --build` |
| `update.sh` | session-start safe auto-update; never touches personal zones; re-wires the engine + tops up the shelf after updates |
| `install-skills.sh` | wire the bank into each agent (`.opencode/skills/`, `.claude/skills/`, `.agents/skills/`) and stamp the router block into your agent file (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md`, whichever exist; bare `@...` pointers skipped); `--check` to inspect, `--copy` for filesystems without symlinks |
| `scaffold-library.sh` | top up missing standard books (README keys included); never overwrites filled content |
| `git-guard.sh` | team forks: pre-push hook so member machines push to `dev`, not `main`; `--install` |
| `self-test.sh` | proves the engine end to end: layout, wiring, registries, then an integration pass (installer, scaffold, hook, guard) in a scratch copy; `--quick` skips the pass |

`.fts.db` is derived: delete it and rebuild in seconds. Windows: use `python` where docs say `python3`.
