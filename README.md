# CV4 - a memory engine for any AI agent, spec-driven by design
*A folder of plain markdown that remembers. Bring your own agent: Claude Code, opencode, Gemini CLI, anything with file access.*

**Start here:** give your AI agent this link and one instruction:

```
Clone https://github.com/wanshazamirul/CV4 and read BOOT.md.
```

It clones the repo to its home (`CV4` in your home folder), runs the 3-question enrollment, writes the manual into your tool's own file, seeds the memory, and says hello. One card hooks it up: the signpost so any folder wakes with memory, plus clean Claude defaults on Claude Code. From then on, open your agent anywhere. No terminals, no config. This README is the map.

**Spec-driven by design:** pairs with spec-kit (constitution -> specify -> plan -> tasks -> implement -> converge); the bridge ships in `spec-kit/` and the lessons land in `memory/`.

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
                 │   skills/    bank rituals (auto-updated)   │
                 │   my-skills/ your rituals, never touched   │
                 │                                            │
                 │   tools/fts.py   the search index          │
                 │   (derived: delete it, rebuild in seconds) │
                 └────────────────────────────────────────────┘
```

---

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

## Layers: the companion and the work

```ascii
                         ONE DAY AT THE DESK

┌─ CV4 · THE COMPANION LAYER · lives with the person, forever ────────────┐
│                                                                         │
│   save · recall · reminders · decisions · forge · intake                │
│   guardrails: G0 (no blind action) · docs · commits · compaction        │
│                                                                         │
│      ┌─ SPEC-KIT · THE WORK LAYER · lives with the project ────────┐    │
│      │  constitution -> specify -> clarify -> plan -> checklist    │    │
│      │  -> tasks -> analyze -> implement -> converge               │    │
│      └─────────────────────────────────────────────────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

- **spec-kit is opt-in**: without it, `build-protocol` plays the same role, lighter.
- **Who leads**: the project's rules lead for the project's work; the companion still carries this identity and this memory across projects.
- **The bridge**: the house supplies the constitution's behavioral half, and `/speckit-converge` sends lessons home via `spec-kit/converge-to-memory.sh`.

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
- Entire new workflows become **skills**: bank ones upgrade in place; yours land in `my-skills/`.
- Before any new skill, the **gate** checks both registries: bank skills get upgraded, **your** skills win (fold-in offered, never overwritten).
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
├── versions/                    THE UPDATE BACKBONE
│   ├── README.md                  the files + the update contract
│   ├── VERSION                    the current release string
│   └── CHANGELOG.md               what changed, per release
│
├── .claude-plugin/              Claude Code packaging (the repo itself is the plugin)
│   ├── README.md                  the key
│   └── plugin.json                the manifest
│
├── docs/                        TEMPLATE DOCS (about CV4 itself)
│   ├── README.md                  the key
│   └── enterprise-edition.md      the team-edition design
│
├── main/                        THE CORE - small on purpose
│   ├── README.md                  this key: the five files + their disciplines
│   ├── identity-core.md           who the AI is (persona contract)
│   ├── soul.md                    what it is learning (40-line cap)
│   ├── relationship-memory.md     who you are: preferences, world, history
│   ├── current-session.md         rolling state (last 3 sessions)
│   └── hotlist.md                 never-again rules - read every session
│
├── memory/                      WORKING MEMORY
│   ├── README.md                  the key: parts, caps, when to write where
│   ├── index.md                   fast recall layer: one line per durable item
│   ├── decisions.md               append-only decision log
│   ├── reminders.md               forward tasks that survive resets
│   ├── skills.md                  skill usage ledger (ticked at save)
│   └── feedback/                  suggestions about the workflow
│
├── logs/                        SESSION HISTORY
│   ├── README.md                  the key: write, read, rotate
│   ├── protocol.md                append-only, one file per day
│   ├── current/                   this month (YYYY-MM-DD.md)
│   └── archived/                  monthly cold storage
│
├── library/                     THE SHELF - seven books + yours
│   ├── README.md                  the shelf: chapter format + curation rules
│   ├── frontend/ ... design/      the standard books (guardrail README keys inside)
│   ├── _template/                 the kit for a new book (its README is the key)
│   └── (your books)               personal domains: yours, never upstream
│
├── skills/                      THE BANK (auto-updated rituals)
│   ├── README.md                  catalog + how to add skills and sub-skills
│   ├── registry.md                bank roster (the gate reads it)
│   ├── save/                      "save" / goodbye: log + memory + reminders
│   ├── check-reminders/           open items surface at session start
│   ├── decision-log/              context, decision, why (append-only)
│   ├── recall-memory/             hotlist -> index -> fts -> library
│   ├── build-protocol/            restate, recall, plan, gates, verify
│   ├── forge/                     repetition -> rule, chapter, sub-skill, skill
│   └── intake/                    foreign files: fence, assess, merge or reject, log
│
├── my-skills/                   YOURS FOREVER (never overwritten; they win)
│   ├── README.md                  bring your own, or let forge add one
│   └── registry.md                your roster (the gate checks it first)
│
├── personas/                    WHO USES THIS INSTANCE (empty cups; fills stay local)
│   ├── README.md                  role claim (owner / member / just-me), three lanes
│   └── _template.md               the empty cup
│
├── spec-kit/                    OPTIONAL SDD BRIDGE
│   ├── README.md                  wire spec-kit to this repo (per project)
│   ├── constitution-template.md   house clauses; the project fills the stack
│   └── converge-to-memory.sh      distill a converge outcome into memory/decisions.md
│
└── tools/                       THE TOOLBELT
    ├── README.md                  the key: what each tool does
    ├── fts.py                     search index (stdlib only)
    ├── update.sh                  safe auto-update (session start)
    ├── install-skills.sh          wire the bank into your agent (opencode · Claude · .agents)
    ├── scaffold-library.sh        restore any missing standard book
    ├── git-guard.sh               team forks: members push to dev, not main
    └── self-test.sh               prove the engine end to end (scratch integration pass)

Created locally at first boot (yours forever):
    Your tool's agent file (AGENTS.md, CLAUDE.md, or GEMINI.md) carrying the full manual
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
| foreign file arrives, "what do you think?" | `intake` | Fence, assess (card), merge or reject with reasons, log every verdict |

Your own rituals live in `my-skills/`: never overwritten, and on overlapping triggers yours win.

## Staying updated

```ascii
  upstream (this repo)  ──►  tools/update.sh  ──►  your copy
                              (session start)       (personal zone untouched)
```

- **Auto-updated**: `skills/` `tools/` `versions/` `BOOT.md` `README.md` `.claude-plugin/` `personas/` `spec-kit/`
- **Yours forever**: `main/` `memory/` `logs/` `library/` `my-skills/` `AGENTS.md` `CLAUDE.md` `GEMINI.md`
- After an update, `update.sh` also re-wires the skills engine and tops up any missing standard book.
- `my-skills/` is seeded once, then never touched: bring your skills and they stay yours.
- Version lives in `versions/VERSION`; changes in `versions/CHANGELOG.md`.
- Offline or no git remote: silent skip. Memory always works.

## Uninstalling

Almost everything lives inside this folder. The machine-level traces: the signpost block, the `instructions` entry, and the agent settings applied at setup (if any). The repo itself never installs globally: memory stays a plain versioned folder on purpose; only the signpost points at it. A clean exit is small:

1. **Remove the signpost** (if installed): delete the block between `<!-- CV4 companion: start -->` and `<!-- CV4 companion: end -->` in whichever global files have it (`~/.config/opencode/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.codex/AGENTS.md`), and remove the `<HOME>/AGENTS.md` entry from `instructions` in `~/.config/opencode/opencode.json` if you added it. If that config file only existed for this, deleting the file is fine too.
2. **Settings** (if applied at setup): every global file edited at setup was backed up to `<file>.bak-<YYYYMMDD>` first. Keep the clean defaults, or restore the backup: `cp ~/.claude/settings.json.bak-20261018 ~/.claude/settings.json`.
3. **Delete this folder.** Memory, logs, skills, and history all live inside it.

Want it handled for you? In a session inside this folder, say "uninstall": your companion removes the signpost, offers keep-or-restore for the settings it applied, says what remains, and you delete the folder when you are done. Just want to detach (keep the memory, stop the auto-load)? Do step 1 only.

## Roadmap

- **Solo (this)**: zero services, one session per brain at a time.
- **Daemon tier (next)**: a small local service adds presence, handoffs, and a shared board for parallel sessions. Ships as an install guide when ready.
- **Fleet tier (later)**: many machines, one brain.

## FAQ

**Where does my data live?** In this folder. Plain markdown. No server, no account, no lock-in. `git log` is your full history. Nothing installs globally: the only trace outside the folder is the signpost reference.

**Where do I start my agent from now on?** Anywhere, once the setup applied the signpost: that is its whole point. Without the signpost, start inside this folder (or any folder within it), where the manual loads on its own. No signpost and started elsewhere? It greets you like a stranger.

**What is the signpost, and how do I remove it?** One marked block, offered at onboarding, in your agent's global rules (`~/.config/opencode/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, or `~/.codex/AGENTS.md`): it points every session back to this repo. It is the block between `<!-- CV4 companion: start -->` and `<!-- CV4 companion: end -->`. Delete the block to detach; nothing else is touched.

**How do I uninstall CV4 completely?** See [Uninstalling](#uninstalling): remove the signpost, delete the folder. Nothing else on the machine is touched.

**Which agents work?** Anything that reads files. BOOT writes the manual into your tool's own file (`AGENTS.md`, `CLAUDE.md`, or `GEMINI.md`), so every tool reads it natively: no imports, no pointers. One template in BOOT serves all three, and refreshes regenerate whichever files your machine carries.

**Can I use it on two machines?** Yes: put the folder in a git repo, push and pull. One session per copy at a time (the daemon tier will lift this).

**What if I delete `tools/.fts.db`?** Nothing. It rebuilds with one command. Files are the truth; the index is a cache.

**Anything Windows-specific?** Where docs say `python3`, use `python` (`python tools/fts.py --build`). And if `tools/update.sh` ever throws `$'\r'` errors, that checkout has CRLF endings: heal once with `sed -i 's/\r$//' tools/update.sh`. Fresh clones ship LF.

**Can I bring my own skills?** Yes: drop them in `my-skills/` and register them in `my-skills/registry.md`. They are never overwritten, and they win when triggers overlap the bank. `forge` checks them before generating anything new.

**How do I keep commits clean (no "Generated with AI" trailers)?** The manual instructs the companion to commit in your name with no AI attribution, and opencode respects those repo rules. Claude Code adds attribution by default; make it mechanical with one setting in `~/.claude/settings.json`:

```json
{ "attribution": false }
```

That hides the commit trailer, the PR attribution line, and the session link. Older versions read `"includeCoAuthoredBy": false` instead. At setup the companion bundles it with the one-memory-store default in a single recommended card, backs your settings file up first, and merges the keys with your approval.

**Why are all illustrations ASCII?** Docs live in git and get read by agents; ASCII diffs cleanly, never breaks, and renders everywhere. House rule: every diagram in every README is ASCII, no images.

**What happens when the context fills up (compaction)?** Your agent compacts natively: opencode summarizes automatically (`compaction` in its config, `keep.tokens` tunes how much detail survives, and the manual is re-read as the session baseline afterwards), Claude Code has `autoCompactEnabled` / `autoCompactWindow`. Compaction is lossy by nature. This repo's design makes it survivable: the truth lives in files, never only in the context, and the manual instructs the companion to reload `main/` + `memory/` after any compaction, and to save before stopping. Worst case, start a fresh session: the load is exactly the same.

```ascii
 before  [ rules + manual ][ old conversation ..................... ][ recent ]
 compact          replaces the verbatim old conversation with a summary
 after   [ rules + manual ][ summary ][ recent ][ next work ]
          rules auto-reload; memory files reload via the manual's rule
```

**What about Claude Code's own auto memory?** Claude Code keeps a separate `MEMORY.md` of its own outside this repo (`autoMemoryEnabled` in `~/.claude/settings.json`, on by default). If you want one memory store, as this repo intends, set it to `false`: everything your companion learns then lives here, where you can read it, diff it, and back it up. Another agent with a built-in memory store? Same idea: switch it off, or make this repo the place the lessons land. At setup both keys ride one recommended card; the companion backs the file up first (`.bak-<date>`) and merges with your approval.

**How do I know my setup is healthy?** Run `bash tools/self-test.sh`: it checks the layout and README keys, the engine wiring and router, the registries, then runs the integration pass (installer, scaffold, converge hook, git-guard) in a scratch copy. `RESULT: PASS` means the engine is sound; `--quick` skips the scratch pass.

**How do I add my own ritual?** Create `my-skills/<name>/SKILL.md` with a `name` and a `description` (the trigger), add a row to `my-skills/registry.md`. Sub-skills nest under their parent. That is the entire SDK.

**Which skills actually get used?** `memory/skills.md`: save ticks the `uses` count and last-used date for whatever fired.

**Why is there a `versions/` folder?** So the root stays clean and the update system has one obvious home for its state.
