---
name: build-protocol
description: "MUST use when the user says 'build X', 'here are the specs', 'make me a...', or on any multi-step implementation. The build loop: restate, recall, plan, build in steps, verify before done."
---

# Build Protocol

*No shortcuts. Verify before you present.*

## The loop

1. **Restate** - echo the ask in under 5 bullets: what / for whom / constraints / done looks like. Ask about ambiguity NOW (max 3 questions). Name what v1 will NOT include.
2. **Recall** - the `recall-memory` order. Prior art in `library/`? Cite it. Say "clear" otherwise.
3. **Plan** - anything multi-step gets steps written first (2-6 of them), a yes from the user, then building.
4. **Build in gates** - one step at a time; verify each (run it, test it, look at it) before the next.
5. **Verify before done** - actually exercise the result once (open the page, run the script, send the test). Never present from memory.
6. **Save** - log what was built, decisions made, what's next.

## Rules

- Check `library/` before writing from scratch. Adopt, then adapt, then build.
- One big unverified step is worse than five small verified ones.
- Failed twice? Stop and rethink the plan with the user.
- No em-dashes in anything written.

## Level history

- Lv.1 - initial skeleton ritual.
