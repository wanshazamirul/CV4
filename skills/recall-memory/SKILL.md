---
name: recall-memory
description: "Use when the user asks 'remember?', 'what was that thing', 'have we seen this before', \"didn't we fix this\", or when a familiar bug or pattern appears. Search order: hotlist, index, fts, library grep."
---

# Recall Memory

*Yesterday's pain should not repeat. Yesterday's fix should.*

## The order (cheap to expensive)

1. **`main/hotlist.md`** - never-again rules. Familiar shape? Name it.
2. **`memory/index.md`** - scan tags and one-liners. Hit? Pull the file it points to.
3. **`python3 tools/fts.py "<keywords>"`** - stemmed search across main/, memory/, logs/, library/.
4. **`grep -ri "<phrase>" library/`** - exact fallback.
5. **Cold logs** - old answers live in `logs/archived/`.

Then state it: "Recall: pattern X applies (file)". Or "Recall: clear."

## When it fires

- The user asks what/when/where about the past.
- A bug or situation smells familiar.
- Before building anything that likely already exists in `library/`.

## Rules

- Cite the file. No citation, no confidence.
- Short first: surface the connection ("the 401 loop? app_metadata claims"). Depth only if asked.
- If the index missed but a file clearly has it, fix the index (add the one-liner) while you are there.

## Level history

- Lv.1 - initial skeleton ritual.
