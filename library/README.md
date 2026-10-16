# Library - books of patterns

A bigger book with smaller chapters: **shelf -> books -> chapters.**

```
library/
├── README.md          this shelf: the books
└── workflow/          a book (its README is its cover + table of chapters)
    ├── README.md
    └── recall-order/    a chapter (one pattern per chapter)
        └── recall-order.md
```

**Books** are broad areas, each with a `README.md` that says what belongs in it and lists its chapters. Current books: `workflow` (how we work).

**Chapters** are single patterns, named by slug:

```md
# <Pattern name>

**Problem:** the situation that keeps happening
**Solution:** what to do, concretely
**Sources:** where it was learned (log date, decision, incident)
```

**When to file a chapter:** when a solution generalizes beyond one incident (forge rung 2). One-offs stay in the log.

**Adding a book:** create `library/<book>/README.md` describing the area, then add it to this shelf list.

Personal zone: never auto-updated.
