# Project constitution (house template)

> Behavioral clauses from the house. Fill the Stack section yourself. Paste into `/speckit-constitution` or `.specify/memory/constitution.md`.

## Principles (house)

1. **Security-first**: validate input, least privilege, secrets never in code.
2. **Verification before completion**: never claim done without running the check (test, build, or an explicit repro).
3. **No blind action**: freedom words ("cook", "full send") expand WHAT may be built, never WHICH gates run. Gates: recon -> spec where required -> preflight -> verify.
4. **Evidence before synthesis**: scary claims get live data before conclusions.
5. **Append-only history**: decisions and logs are added to, never rewritten.
6. **Recall before rebuild**: check the knowledge base (`library/`) before building anything new.
7. **One rule, one place**: no duplicated requirements across docs.

## Stack (the project fills this)

- Language / framework:
- Styling / UI:
- Validation / data:
- Testing / gates:
- Deploy target:

## Workflow

- Run the spec-kit steps in order; repeat `/speckit-converge` until it reports Converged.
- After converge, distill the outcome: `bash spec-kit/converge-to-memory.sh "<one-line outcome>"`.
