# spec-kit bridge (optional)

Spec-kit runs the process (constitution -> specify -> clarify -> plan -> checklist -> tasks -> analyze -> implement -> converge). This repo is the memory, skills, and guardrails around it. Thin seam, no fork: plain markdown plus one small script.

## Install (per project, opt-in)

In YOUR project repo (not this one):

```
uv tool install specify-cli
specify init . --integration opencode     # or: --integration claude
```

Launch your agent in the project and run the `/speckit-*` steps. Spec-kit artifacts live in the project's `.specify/`; the house memory stays in this repo.

## The constitution

`constitution-template.md` carries the house behavioral clauses (security-first, verification, no blind action, evidence before synthesis). The stack section is blank on purpose: the project fills it. Paste it into `/speckit-constitution` or `.specify/memory/constitution.md`.

## The memory hook (converge -> decisions)

After `/speckit-converge` reports Converged (or records gaps), distill the outcome:

```
bash spec-kit/converge-to-memory.sh "<one-line outcome>"
```

That appends one dated line to `memory/decisions.md`, so the next session and every future project inherit the lesson. Idempotent; safe to rerun.

## Pinning

Record your versions when you wire it (`specify --version`, your agent version). Spec-kit evolves fast; this bridge stays plain markdown plus one script so upgrades never break this repo.
