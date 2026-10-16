# CV4 - a memory engine for any AI agent
*A folder of plain markdown that remembers. Bring your own agent: Claude Code, opencode, Gemini CLI, anything with file access.*

**Start here: open this folder with your agent and say "read BOOT.md".** BOOT interviews you, creates your agent files, seeds the memory, and hands you a companion that remembers. This README is the map.

---

## How it works

Two movements, forever: **recall** before acting, **record** before leaving.

```ascii
                 ┌────────────────────────────────────────────┐
                 │               YOUR AI AGENT                │
                 │   Claude Code · opencode · Gemini · any    │
                 └───────────┬────────────────────▲───────────┘
                             │                    │
                    RECORD   │                    │   RECALL
                    (save)   ▼                    │   (before acting)
                 ┌────────────────────────────────────────────┐
                 │                YOUR REPO                   │
                 │                                            │
                 │   main/      who the AI is, who you are    │
                 │   memory/    index · decisions · reminders │
                 │   logs/      every session, one file a day │
                 │   library/   books of reusable patterns    │
                 │                                            │
                 │   tools/fts.py   the search index          │
                 │   (derived: delete it, rebuild in seconds) │
                 └────────────────────────────────────────────┘
```

---

## First 5 minutes

```ascii
 git clone/template
       │
       ▼
 open the folder with your agent
       │
       ▼
 say: "read BOOT.md"
       │
       ▼
 5 questions: names, timezone, tone, purpose
       │
       ▼
 AGENTS.md created (yours) + memory seeded + first log written
       │
       ▼
 talk like normal · say "save" when done
```

## A day in the life

```ascii
   SESSION TODAY                        BETWEEN                        NEXT SESSION
 ┌──────────────────┐            ┌──────────────────┐            ┌──────────────────┐
 │  door opens      │            │     logs/        │            │  door opens      │
 │  reads main/     │            │     memory/      │            │  reads main/     │
 │  + memory/       │   save     │     library/     │   recall   │  + memory/       │
 │  works, recalls  │ ─────────► │                  │ ─────────► │  greets you with │
 │  keeps notes     │            │  (plain files,   │            │  what happened   │
 │  SAVES           │            │   versioned)     │            │  last time  ✓    │
 └──────────────────┘            └──────────────────┘            └──────────────────┘
```

## It improves itself

Nothing repeats a third time for free.

```ascii
   work happens ──► repetition noticed?
                     two mistakes ────────┐       THE LADDER (cheapest first)
                    3x pattern ──────────┤
                    "forge this" ────────┘       1. hotlist line     a mistake becomes a rule
                              │                  2. library chapter  a solution becomes reusable
                              ▼                  3. sub-skill        extend an existing skill
                    you approve the upgrade  ◄─┐ 4. new skill        a workflow, with a trigger
                              │               └─┘
                              ▼
                    written + indexed ──► every future session benefits
```

- Corrections become **hotlist** lines: the same mistake cannot return quietly.
- Solved problems become **library chapters**: recall finds them next time.
- Repetitions inside an existing workflow become **sub-skills** (nested under their parent).
- Entire new workflows become **skills**.
- The **soul** (`main/soul.md`) grows through use: real lessons land there during saves, nothing invented.

Details and rules: `skills/forge/`.

## The knowledge base

```ascii
  memory/index.md     the fast layer     tags + one-liners (hot / warm / cold)
  library/            the deep layer     books of chapters, patterns worth keeping
  logs/               the truth          every session, append-only
  main/               the core           identity, soul, relationship, hotlist
        │
        └────────────► tools/fts.py      one query searches all of it
```

Write side: today's work lands in `logs/` and the index at save time. Read side: recall walks hotlist -> index -> fts -> library before acting.

## What's in the box

```
CV4/
├── BOOT.md                      START HERE: orientation + interview + manual
├── README.md                    this map
├── versions/                    VERSION + CHANGELOG.md (the update backbone)
│
├── main/                        THE CORE - small on purpose
│   ├── identity-core.md           who the AI is (persona contract)
│   ├── soul.md                    what it is learning (40-line cap)
│   ├── relationship-memory.md     who you are: preferences, world, history
│   ├── current-session.md         rolling state (last 3 sessions)
│   └── hotlist.md                 never-again rules - read every session
│
├── memory/                      WORKING MEMORY
│   ├── index.md                   fast recall layer: one line per durable item
│   ├── decisions.md               append-only decision log
│   ├── reminders.md               forward tasks that survive resets
│   └── feedback/                  suggestions about the workflow
│
├── logs/                        SESSION HISTORY
│   ├── protocol.md                append-only, one file per day
│   ├── current/                   this month (YYYY-MM-DD.md)
│   └── archived/                  monthly cold storage
│
├── library/                     BOOKS OF PATTERNS
│   ├── README.md                  the shelf: books + chapter format
│   └── workflow/                  a book (its README lists its chapters)
│       └── recall-order/          a chapter
│
├── skills/                      THE RITUALS (load the file when triggered)
│   ├── README.md                  catalog + how to add skills and sub-skills
│   ├── save/                      "save" / goodbye: log + memory + reminders
│   ├── check-reminders/           open items surface at session start
│   ├── decision-log/              context, decision, why (append-only)
│   ├── recall-memory/             hotlist -> index -> fts -> library
│   ├── build-protocol/            restate, recall, plan, gates, verify
│   └── forge/                     repetition -> rule, chapter, sub-skill, skill
│
└── tools/                       THE TOOLBELT
    ├── fts.py                     search index (stdlib only)
    └── update.sh                  safe auto-update (session start)

Created locally at first boot (yours forever):
    AGENTS.md (the manual) · CLAUDE.md / GEMINI.md (one-line pointers, if needed)
```

## The rituals (skills)

| Trigger | Skill | What happens |
|---|---|---|
| "save" / goodbye | `save` | Session log + memory update + reminders sweep + rotation |
| session start / "remind me" | `check-reminders` | Open items surface; new ones logged one line each |
| a decision got made | `decision-log` | Context, decision, why. Append-only |
| "remember?", familiar bug | `recall-memory` | The recall order: hotlist, index, fts, library |
| "build X", multi-step work | `build-protocol` | Restate, recall, plan, build in gates, verify |
| "that keeps happening", 3x repeat | `forge` | The ladder: rule, chapter, sub-skill, or new skill |

## Staying updated

```ascii
  upstream (this repo)  ──►  tools/update.sh  ──►  your copy
                              (session start)       (personal zone untouched)
```

- **Auto-updated**: `skills/` `tools/` `versions/` `BOOT.md` `README.md`
- **Yours forever**: `main/` `memory/` `logs/` `library/` `AGENTS.md` `CLAUDE.md` `GEMINI.md`
- Version lives in `versions/VERSION`; changes in `versions/CHANGELOG.md`.
- Offline or no git remote: silent skip. Memory always works.

## Roadmap

- **Solo (this)**: zero services, one session per brain at a time.
- **Daemon tier (next)**: a small local service adds presence, handoffs, and a shared board for parallel sessions. Ships as an install guide when ready.
- **Fleet tier (later)**: many machines, one brain.

## FAQ

**Where does my data live?** In this folder. Plain markdown. No server, no account, no lock-in. `git log` is your full history.

**Which agents work?** Anything that reads files. BOOT creates `AGENTS.md` plus a `CLAUDE.md` / `GEMINI.md` pointer when needed, so every tool reads the same manual.

**Can I use it on two machines?** Yes: put the folder in a git repo, push and pull. One session per copy at a time (the daemon tier will lift this).

**What if I delete `tools/.fts.db`?** Nothing. It rebuilds with one command. Files are the truth; the index is a cache.

**How do I add my own ritual?** Create `skills/<name>/SKILL.md` with a `name` and a `description` (the trigger), add it to `skills/README.md`. Sub-skills nest under their parent. That is the entire SDK.

**Why is there a `versions/` folder?** So the root stays clean and the update system has one obvious home for its state.
