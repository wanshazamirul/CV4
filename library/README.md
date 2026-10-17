# library - the shelf

Knowledge lives here as **books** (domains). The shelf is standard and shared: every instance has the same seven books; what differs is only how full they are.

| Book | Covers |
|---|---|
| `frontend/` | build and ship UI: rendering, state, styling, components, performance |
| `backend/` | APIs, databases, auth implementation, data, integrations |
| `security/` | trust boundaries: hardening, guards, sessions, access control |
| `infra/` | deploy, hosts, containers, cron, backups, tooling environments |
| `process/` | how we work: audits, reviews, gates, publishing, planning |
| `ai/` | agents, prompts, models, chat lanes, memory and skill systems |
| `design/` | what it should look and feel like: tokens, typography, references, visual QA |

**Personal books**: add your own next to these (`trading/`, `flutter/`, whatever your domain is). They are yours: never auto-updated, never upstream. Generalizable lessons graduate into the standard books.

## Chapter format (one shape everywhere)

```
<book>/
├── README.md                    the key: purpose, belongs/does-not, chapter index, status
└── chapter-slug/                a chapter
    ├── chapter-slug.md          the chapter: Problem / Solution / Sources
    └── sub-topic.md             a subsection, when one file is not enough
```

- **Problem**: the situation that keeps happening. **Solution**: what to do, concretely. **Sources**: where it was learned.
- A chapter earns its place when a solution generalizes beyond one incident; one-offs stay in the log.
- One pattern per chapter. If a chapter outgrows one file, add subsections inside its folder.
- Retire by moving a chapter to `archive/`, never by deleting.

## Curating

- Each book README is its key: purpose, belongs/does-not, chapter index, status. Update the index when chapters land or retire.
- Missing standard books restore themselves: `bash tools/scaffold-library.sh` (adds only what is missing, never touches filled content).

Personal zone: never auto-updated.
