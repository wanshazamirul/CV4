# Live harness gate (release checklist)

The fixture suite proves the dispatcher and the configs. This checklist proves the real harness fires them. Run it on a machine that has the harness, with a filled CV4 instance (identity is not `[AI_NAME]`).

## Before each harness

```bash
bash tools/hooks/doctor.sh          # adapters, fixtures, state, kill switch
bash tools/hooks/install.sh all install
bash tools/hooks/install.sh all check
```

Expected: each installed harness reports its CV4 handlers; `doctor` is PASS after install.

## The checks (repeat per harness)

1. **Boot brief.** Start a new session in a project folder, outside Home. First message: `hi`.
   - Expected: a greeting from memory, no "loading memory" text, no double load.
   - Evidence: `logs/hooks.log` has a `session-start` inject for that harness.

2. **Skill router.**
   - Say: `save and wrap up`.
   - Expected: the model follows `skills/save` and replies with one line (`autosaved`), then a real log lands under `logs/current/`.
   - Evidence: `prompt` inject in `logs/hooks.log`; the log file exists.

3. **Bug prompt + recall gate.**
   - Say: `this is broken, the login fails`.
   - Expected: a `[CV4 recall]` block with hotlist/fts hits; the first edit is blocked once with the recall reason, the retry passes.
   - Evidence: `prompt` inject; `pre-tool` block (once) in `logs/hooks.log`.

4. **Close without a goodbye.**
   - Do a small edit, then close the terminal without saving.
   - Expected: `logs/.state/pending-save-<sid>.json` or a stale state, plus `logs/.state/close-save.log` when the worker runs.
   - Reopen a session: the boot brief says `unsaved session` or `stale session`, with the checkpoint path.

5. **Idle save (optional, 1 minute for the test).**
   - Set `main/behavior.json` -> `{"auto_save": {"idle_minutes": 1}}`.
   - Do a small edit, let the turn finish, then leave the session alone.
   - Expected: after about a minute with no new prompt or tool call, `logs/.state/close-save.log` appears, or a pending marker if the worker is unavailable.
   - Send a prompt before the minute is up on a second run: the save must not fire. Restore `idle_minutes` to 15 after the check.

6. **Uninstall.**
   - `bash tools/hooks/install.sh <harness> remove`
   - Expected: zero CV4 handlers in that harness config; the user's own hooks stay; opencode plugin folder gone.
   - Reinstall with `install` and confirm idempotency (no duplicates).

## Harness notes

- **Claude Code**: hooks are user-level settings; no trust prompt. The `SessionEnd` hook has a raised timeout so the close worker can spawn.
- **opencode**: already live-tested on the server (brief + save). Close recovery relies on `session.deleted` or the stale-state scan on the next boot.
- **Gemini CLI**: hooks live in `~/.gemini/settings.json`. Gemini fingerprints project hooks; user hooks are the supported path here. Check `/hooks` if a hook is not firing.
- **Codex**: run `/hooks` once and approve the CV4 handlers. Until then, Codex skips them. `SessionEnd` runs on close or after 30 minutes idle.

## Evidence to keep

- `logs/hooks.log` lines for the run (harness, event, action).
- The session log under `logs/current/`.
- `logs/.state/close-save.log` or the pending/stale marker.
- `bash tools/hooks/doctor.sh` output after the run.

If any check fails: `CV4_HOOKS=0` silences the spine, `main/behavior.json` sets `{"mode": "shadow"}`, and the manual path is unchanged.
