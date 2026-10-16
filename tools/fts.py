#!/usr/bin/env python3
# CV3 Skeleton FTS recall - SQLite FTS5 (porter stemming) over the memory files.
# Zero dependencies (stdlib only). The DB is derived data, gitignored.
# Usage:
#   python3 tools/fts.py --build                 # (re)build the index
#   python3 tools/fts.py "hydration mismatch" [--max=10] [--json]
import json
import os
import sqlite3
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # repo root
DB = os.path.join(BASE, "tools", ".fts.db")

STORES = [
    ("main", None, 2.0),
    ("memory", None, 2.0),
    ("library", None, 1.5),
    ("logs/current", None, 1.2),
    ("logs/archived", None, 0.5),
]


def collect():
    out = []
    for sub, files, boost in STORES:
        d = os.path.join(BASE, sub)
        if files:
            for f in files:
                p = os.path.join(d, f)
                if os.path.isfile(p):
                    out.append((p, boost))
            continue
        if not os.path.isdir(d):
            continue
        for root, dirs, names in os.walk(d):
            dirs[:] = [x for x in dirs if x not in ("node_modules", ".git")]
            for n in names:
                if n.endswith(".md"):
                    out.append((os.path.join(root, n), boost))
    return out


def title_of(path, text):
    for line in text.split("\n"):
        s = line.strip()
        if s.startswith("#"):
            return s.lstrip("#").strip()[:120]
    return os.path.basename(path)


def build():
    con = sqlite3.connect(DB)
    con.execute("DROP TABLE IF EXISTS f")
    try:
        con.execute("CREATE VIRTUAL TABLE f USING fts5(title, body, tokenize='porter')")
    except sqlite3.OperationalError:
        con.execute("CREATE VIRTUAL TABLE f USING fts5(title, body)")
    con.execute("CREATE TABLE IF NOT EXISTS m(path TEXT PRIMARY KEY, boost REAL)")
    con.execute("DELETE FROM f")
    con.execute("DELETE FROM m")
    n = skipped = 0
    for path, boost in collect():
        try:
            if os.path.getsize(path) > 500 * 1024:
                skipped += 1
                continue
            with open(path, encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError:
            skipped += 1
            continue
        rel = os.path.relpath(path, BASE)
        rowid = con.execute("INSERT INTO f(title, body) VALUES (?, ?)",
                            (title_of(path, text), text)).lastrowid
        con.execute("INSERT OR REPLACE INTO m(rowid, path, boost) VALUES (?, ?, ?)",
                    (rowid, rel, boost))
        n += 1
    con.commit()
    print(f"indexed {n} files ({skipped} skipped), db {os.path.getsize(DB)//1024}K")
    con.close()


def esc(q):
    return q.replace('"', '""')


def search(raw, maxn=10, as_json=False):
    con = sqlite3.connect(DB)
    try:
        terms = [t for t in raw.replace('"', " ").split() if t]
        if not terms:
            print("No search terms.", file=sys.stderr)
            sys.exit(1)
        match = " OR ".join(f'{{title body}} : "{esc(t)}"*' for t in terms)
        q = ("SELECT m.path, m.boost, snippet(f, 1, '[', ']', '...', 18) AS snip, rank "
             "FROM f JOIN m ON m.rowid = f.rowid WHERE f MATCH ? ORDER BY rank LIMIT ?")
        rows = con.execute(q, (match, maxn * 3)).fetchall()
    except sqlite3.OperationalError as e:
        print(f"FTS error ({e}) - run: python3 tools/fts.py --build", file=sys.stderr)
        sys.exit(1)
    out = []
    for path, boost, snip, rank in rows:
        out.append({"file": path, "score": round(-rank * boost, 2),
                    "text": " ".join(snip.split())[:240]})
        if len(out) >= maxn:
            break
    if as_json:
        print(json.dumps({"query": raw, "count": len(out), "results": out}, indent=2))
    elif not out:
        print(f'No hits for "{raw}". Try fewer or different words, or grep the library.')
    else:
        print(f'Top {len(out)} for "{raw}":')
        for r in out:
            print(f"  [{r['score']}] {r['file']}\n      {r['text']}")
    con.close()


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args or "--help" in args or "-h" in args:
        print('Usage: python3 tools/fts.py --build | python3 tools/fts.py "terms" [--max=10] [--json]')
        sys.exit(0)
    if "--build" in args:
        build()
        sys.exit(0)
    maxn, as_json, parts = 10, False, []
    for a in args:
        if a.startswith("--max="):
            maxn = max(1, int(a[6:]) or 10)
        elif a == "--json":
            as_json = True
        elif not a.startswith("--"):
            parts.append(a)
    search(" ".join(parts), maxn, as_json)
