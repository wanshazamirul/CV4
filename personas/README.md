# personas - the empty cups

Every person gets their own cup (persona), but the repo ships it EMPTY. Fills live on machines, never here.

```
personas/
├── README.md      this file: the rules
├── _template.md   the empty cup: copy it to start yours
└── .machine       written once by BOOT: this machine's role (gitignored)
```

## The role claim (once per machine)

The first boot on a fresh clone asks one question, then never again:

| Role | Means | Engine paths (skills, tools, library) | Project paths |
|---|---|---|---|
| `personal` | your own machine: a solo instance, or the team's owner machine | full: commit/merge to main | normal |
| `member` | an engineer on a team fork | dev branch only; PR, owner reviews/edits/merges | whatever the monorepo allows |

Older machines may carry `role=owner` or `role=just-me`; both behave exactly like `personal` (only `member` activates the guard).

The claim lives in `personas/.machine` (gitignored). The persona reads it and behaves accordingly: a member's companion says the rule in plain words when a change crosses it ("not verified to push here; this goes to dev for review").

## Powers and lanes

- **DOWN (engine)**: updates flow from the fork's main via `tools/update.sh`.
- **UP (knowledge, team mode)**: memory and library changes flow up via PRs; the companion drafts a memory-sync digest the owner can review in minutes.
- **NEVER (personal)**: filled cups, scratch files, `personas/.machine` stay local; they never travel and never conflict.

## Guardrail

`bash tools/git-guard.sh --install` adds a pre-push hook: a member machine cannot push engine/skills/library changes to `main` directly; it points at dev + PR instead. The hook is the courtesy layer; the real gate is branch protection plus the owner's review.

## One machine, one person

Shared workstation? Run the claim for the second person in a separate clone, or flip `personas/.machine` when handing over. Attribution is handled by git identity; the role claim only shapes the guardrail behavior.
