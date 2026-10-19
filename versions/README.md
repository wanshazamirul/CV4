# versions - the update backbone

| File | What |
|---|---|
| `VERSION` | the current release string; `update.sh` reports it after pulling |
| `CHANGELOG.md` | what changed per release, newest first |

**Update contract:** template-owned files are pulled from upstream (`BOOT.md README.md LICENSE skills/ tools/ versions/ .claude-plugin/ personas/ spec-kit/`); personal zones (`main/ memory/ logs/ library/ my-skills/ AGENTS.md CLAUDE.md GEMINI.md`) are never touched, and the updater never commits them. Releases are cut from staging with one curated commit per version.

**Repair contract:** when a release changes install state (what lives outside the folder, a file the updater must create, a wiring step), add an idempotent fix to `tools/repair.sh`. Every machine runs it after each successful pull, so a clone that skipped several releases heals in one boot instead of needing a manual reset. Repair steps must be safe to run on any version, any number of times.
