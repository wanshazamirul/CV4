#!/usr/bin/env python3
"""Refresh the installed CV4 companion block from BOOT.md.

Usage: refresh-manual.py [--check|--write] [--root DIR]

--check  print installed vs engine manual rev for every companion block (default)
--write  replace the block body, preserving AI name, user name, and Home;
         one rolling <file>.cv4bak per file, written only when missing.

The block is replaced only between its markers; everything outside stays.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import sys
from pathlib import Path

START_RE = re.compile(r"<!-- CV4 companion: start.*?-->")
END_RE = re.compile(r"<!-- CV4 companion: end -->")
MANUAL_RE = re.compile(r"````md\n(.*?)\n````", re.S)


def home_dir() -> Path:
    env = os.environ.get("HOME")
    return Path(env) if env else Path(os.path.expanduser("~"))


def manual_from_boot(root: Path):
    text = (root / "BOOT.md").read_text(encoding="utf-8", errors="replace")
    marker = "# The manual (what the companion install writes into the global config)"
    if marker not in text:
        raise SystemExit("refresh-manual: manual section not found in BOOT.md")
    match = MANUAL_RE.search(text.split(marker, 1)[1])
    if not match:
        raise SystemExit("refresh-manual: manual block not found in BOOT.md")
    body = match.group(1)
    rev = re.search(r"Manual rev:\s*([0-9]+\.[0-9]+\.[0-9]+)", body)
    if not rev:
        raise SystemExit("refresh-manual: manual rev not found")
    return body, rev.group(1)


def candidates():
    home = home_dir()
    files = [
        home / ".claude" / "CLAUDE.md",
        home / ".config" / "opencode" / "AGENTS.md",
        home / ".gemini" / "GEMINI.md",
        home / ".codex" / "AGENTS.md",
        home / "CLAUDE.md",
        home / "AGENTS.md",
        home / "GEMINI.md",
    ]
    seen = set()
    out = []
    for path in files:
        if path in seen:
            continue
        seen.add(path)
        out.append(path)
    return out


def find_block(text: str):
    start = START_RE.search(text)
    end = END_RE.search(text, start.end()) if start else None
    return (start, end) if start and end else (None, None)


def parse_names(body: str):
    ai = re.search(r"I am (.+?), (.+?)'s AI companion", body)
    home = re.search(r"Home:\s*(.+?)\. All paths", body)
    if not ai or not home:
        return None
    return ai.group(1).strip(), ai.group(2).strip(), home.group(1).strip()


def atomic_write(path: Path, text: str) -> None:
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


def main() -> int:
    args = sys.argv[1:]
    write = "--write" in args
    root = Path(__file__).resolve().parents[1]
    if "--root" in args:
        index = args.index("--root")
        if index + 1 < len(args):
            root = Path(args[index + 1]).expanduser().resolve()
    body, engine_rev = manual_from_boot(root)
    found = 0
    for path in candidates():
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        start, end = find_block(text)
        if not start or not end:
            continue
        found += 1
        current = text[start.end():end.start()]
        rev_match = re.search(r"Manual rev:\s*([0-9]+\.[0-9]+\.[0-9]+)", current)
        installed = rev_match.group(1) if rev_match else "?"
        state = "current" if installed == engine_rev else "stale"
        if write and installed != engine_rev:
            names = parse_names(current)
            if not names:
                print(f"skip {path}: could not parse the AI/user names; merge by hand")
                continue
            ai, user, home = names
            new_body = body.replace("[AI_NAME]", ai).replace("[USER_NAME]", user).replace("[HOME]", home)
            new_block = start.group(0) + "\n" + new_body + "\n" + end.group(0)
            backup = path.with_name(path.name + ".cv4bak")
            if not backup.exists():
                shutil.copy2(path, backup)
            atomic_write(path, text[:start.start()] + new_block + text[end.end():])
            print(f"refreshed {path}: {installed} -> {engine_rev}")
        else:
            print(f"{path}: installed {installed}, engine {engine_rev} ({state})")
    if found == 0:
        print("refresh-manual: no companion block found")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"refresh-manual: {type(exc).__name__}: {exc}", file=sys.stderr)
        sys.exit(1)
