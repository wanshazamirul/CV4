# versions - the update backbone

| File | What |
|---|---|
| `VERSION` | the current release string; `update.sh` reports it after pulling |
| `CHANGELOG.md` | what changed per release, newest first |

**Update contract:** template-owned files are pulled from upstream (`BOOT.md README.md skills/ tools/ versions/ .claude-plugin/ personas/ spec-kit/`); personal zones (`main/ memory/ logs/ library/ my-skills/ AGENTS.md CLAUDE.md GEMINI.md`) are never touched. Releases are cut from staging with one curated commit per version.
