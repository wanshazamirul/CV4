#!/usr/bin/env python3
"""CV4 behavior spine installer. Merges hook adapters into each harness config.

Usage: install.py [--root DIR] [--quiet] <claude|opencode|all> <install|remove|check>

Rules: one rolling <file>.cv4bak per file (written only when missing), atomic
writes, validate JSON before replacing, remove only CV4 entries, never touch
another tool's hooks.
"""
from __future__ import annotations

import json
import os
import shutil
import sys
from pathlib import Path

EVENTS = [
    ("SessionStart", None, 10),
    ("UserPromptSubmit", None, 10),
    ("PreToolUse", "Edit|Write", 10),
    ("PostToolUse", None, 10),
    ("Stop", None, 10),
    ("SessionEnd", None, 10),
    ("PreCompact", None, 10),
]


class InstallError(Exception):
    pass


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}
    except (OSError, ValueError) as exc:
        raise InstallError(f"cannot parse {path}: {exc}") from exc


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


def backup(path: Path) -> None:
    if not path.exists():
        return
    bak = path.with_name(path.name + ".cv4bak")
    if not bak.exists():
        shutil.copy2(path, bak)


def is_template(root: Path) -> bool:
    text = ""
    try:
        text = (root / "main" / "identity-core.md").read_text(encoding="utf-8", errors="replace")
    except OSError:
        return True
    return "[AI_NAME]" in text or "[USER_NAME]" in text


def dispatch_path(root: Path) -> str:
    return (root / "tools" / "hooks" / "dispatch.sh").as_posix()


def claude_command(root: Path, event: str) -> str:
    return f'bash "{dispatch_path(root)}" claude {event}'


def is_cv4_handler(handler: dict) -> bool:
    command = str((handler or {}).get("command", ""))
    return "tools/hooks/dispatch.sh" in command


def claude_install(root: Path, quiet: bool) -> str:
    path = Path(os.path.expanduser("~")) / ".claude" / "settings.json"
    if not path.parent.exists():
        return "claude: not installed, skipped"
    data = read_json(path)
    if not isinstance(data, dict):
        raise InstallError(f"{path} is not a JSON object")
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        hooks = {}
    for event, matcher, timeout in EVENTS:
        groups = hooks.get(event)
        if not isinstance(groups, list):
            groups = []
        cleaned = []
        for group in groups:
            if not isinstance(group, dict):
                continue
            inner = group.get("hooks")
            if not isinstance(inner, list):
                cleaned.append(group)
                continue
            kept = [h for h in inner if not is_cv4_handler(h)]
            if kept:
                group = dict(group)
                group["hooks"] = kept
                cleaned.append(group)
        handler = {"type": "command", "command": claude_command(root, event), "timeout": timeout}
        group = {"hooks": [handler]}
        if matcher:
            group["matcher"] = matcher
        cleaned.append(group)
        hooks[event] = cleaned
    data["hooks"] = hooks
    backup(path)
    atomic_write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return f"claude: hooks installed ({len(EVENTS)} events) at {path}"


def claude_remove(root: Path, quiet: bool) -> str:
    path = Path(os.path.expanduser("~")) / ".claude" / "settings.json"
    if not path.exists():
        return "claude: no settings.json, nothing to remove"
    data = read_json(path)
    if not isinstance(data, dict):
        raise InstallError(f"{path} is not a JSON object")
    hooks = data.get("hooks")
    removed = 0
    if isinstance(hooks, dict):
        for event in list(hooks.keys()):
            groups = hooks.get(event)
            if not isinstance(groups, list):
                continue
            cleaned = []
            for group in groups:
                if not isinstance(group, dict):
                    continue
                inner = group.get("hooks")
                if not isinstance(inner, list):
                    cleaned.append(group)
                    continue
                kept = [h for h in inner if not is_cv4_handler(h)]
                removed += len(inner) - len(kept)
                if kept:
                    group = dict(group)
                    group["hooks"] = kept
                    cleaned.append(group)
            if cleaned:
                hooks[event] = cleaned
            else:
                del hooks[event]
        if not hooks:
            data.pop("hooks", None)
    backup(path)
    atomic_write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return f"claude: removed {removed} CV4 hook handler(s)"


def claude_check(root: Path, quiet: bool) -> str:
    path = Path(os.path.expanduser("~")) / ".claude" / "settings.json"
    if not path.exists():
        return "claude: settings.json absent"
    try:
        data = read_json(path)
    except InstallError as exc:
        return f"claude: unreadable ({exc})"
    hooks = data.get("hooks") if isinstance(data, dict) else {}
    found = 0
    if isinstance(hooks, dict):
        for groups in hooks.values():
            if not isinstance(groups, list):
                continue
            for group in groups:
                inner = group.get("hooks") if isinstance(group, dict) else None
                if isinstance(inner, list):
                    found += sum(1 for h in inner if is_cv4_handler(h))
    return f"claude: {found} CV4 hook handler(s) installed"


def opencode_paths():
    home = Path(os.path.expanduser("~"))
    base = home / ".config" / "opencode"
    return base, base / "opencode.json", base / "plugins" / "cv4-hooks"


def opencode_install(root: Path, quiet: bool) -> str:
    base, config, plugin_dir = opencode_paths()
    if not base.exists():
        return "opencode: not installed, skipped"
    template = root / "tools" / "hooks" / "adapters" / "opencode" / "index.ts"
    if not template.exists():
        raise InstallError("opencode adapter template missing")
    data = read_json(config)
    if not isinstance(data, dict):
        raise InstallError(f"{config} is not a JSON object")
    data.setdefault("$schema", "https://opencode.ai/config.json")
    plugins = data.get("plugins")
    if not isinstance(plugins, list):
        plugins = []
    entry = plugin_dir.as_posix()
    plugins = [p for p in plugins if not (isinstance(p, str) and "cv4-hooks" in p)]
    plugins.append(entry)
    data["plugins"] = plugins
    text = template.read_text(encoding="utf-8").replace("__CV4_HOME__", root.as_posix())
    atomic_write(plugin_dir / "index.ts", text)
    backup(config)
    atomic_write(config, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return f"opencode: plugin installed at {plugin_dir}"


def opencode_remove(root: Path, quiet: bool) -> str:
    base, config, plugin_dir = opencode_paths()
    if not config.exists():
        shutil.rmtree(plugin_dir, ignore_errors=True)
        return "opencode: no config, plugin removed if present"
    data = read_json(config)
    if not isinstance(data, dict):
        raise InstallError(f"{config} is not a JSON object")
    plugins = data.get("plugins")
    removed = 0
    if isinstance(plugins, list):
        kept = [p for p in plugins if not (isinstance(p, str) and "cv4-hooks" in p)]
        removed = len(plugins) - len(kept)
        if kept:
            data["plugins"] = kept
        else:
            data.pop("plugins", None)
    backup(config)
    atomic_write(config, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    shutil.rmtree(plugin_dir, ignore_errors=True)
    return f"opencode: removed {removed} plugin entry(ies)"


def opencode_check(root: Path, quiet: bool) -> str:
    base, config, plugin_dir = opencode_paths()
    if not config.exists():
        return "opencode: config absent"
    try:
        data = read_json(config)
    except InstallError as exc:
        return f"opencode: unreadable ({exc})"
    plugins = data.get("plugins") if isinstance(data, dict) else []
    found = len([p for p in plugins if isinstance(p, str) and "cv4-hooks" in p]) if isinstance(plugins, list) else 0
    installed = (plugin_dir / "index.ts").exists()
    return f"opencode: {found} config entry(ies), plugin file {'present' if installed else 'missing'}"


# ---------------------------------------------------------------- gemini

GEMINI_EVENTS = [
    ("SessionStart", "startup|resume|clear", 10000),
    ("SessionEnd", None, 10000),
    ("BeforeAgent", None, 10000),
    ("AfterAgent", None, 10000),
    ("BeforeTool", "write_file|replace|edit_file|apply_patch", 10000),
    ("AfterTool", None, 10000),
    ("PreCompress", None, 10000),
]


def gemini_path() -> Path:
    return Path(os.path.expanduser("~")) / ".gemini" / "settings.json"


def gemini_command(root: Path, event: str) -> str:
    return f'bash "{dispatch_path(root)}" gemini {event}'


def gemini_install(root: Path, quiet: bool) -> str:
    path = gemini_path()
    if not path.parent.exists():
        return "gemini: not installed, skipped"
    data = read_json(path)
    if not isinstance(data, dict):
        raise InstallError(f"{path} is not a JSON object")
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        hooks = {}
    for event, matcher, timeout in GEMINI_EVENTS:
        groups = hooks.get(event)
        if not isinstance(groups, list):
            groups = []
        cleaned = []
        for group in groups:
            if not isinstance(group, dict):
                continue
            inner = group.get("hooks")
            if not isinstance(inner, list):
                cleaned.append(group)
                continue
            kept = [h for h in inner if not is_cv4_handler(h)]
            if kept:
                group = dict(group)
                group["hooks"] = kept
                cleaned.append(group)
        handler = {
            "name": "cv4-behavior-spine",
            "type": "command",
            "command": gemini_command(root, event),
            "timeout": timeout,
        }
        group = {"hooks": [handler]}
        if matcher:
            group["matcher"] = matcher
        cleaned.append(group)
        hooks[event] = cleaned
    data["hooks"] = hooks
    backup(path)
    atomic_write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return f"gemini: hooks installed ({len(GEMINI_EVENTS)} events)"


def gemini_remove(root: Path, quiet: bool) -> str:
    path = gemini_path()
    if not path.exists():
        return "gemini: no settings.json, nothing to remove"
    data = read_json(path)
    if not isinstance(data, dict):
        raise InstallError(f"{path} is not a JSON object")
    hooks = data.get("hooks")
    removed = 0
    if isinstance(hooks, dict):
        for event in list(hooks.keys()):
            groups = hooks.get(event)
            if not isinstance(groups, list):
                continue
            cleaned = []
            for group in groups:
                if not isinstance(group, dict):
                    continue
                inner = group.get("hooks")
                if not isinstance(inner, list):
                    cleaned.append(group)
                    continue
                kept = [h for h in inner if not is_cv4_handler(h)]
                removed += len(inner) - len(kept)
                if kept:
                    group = dict(group)
                    group["hooks"] = kept
                    cleaned.append(group)
            if cleaned:
                hooks[event] = cleaned
            else:
                del hooks[event]
        if not hooks:
            data.pop("hooks", None)
    backup(path)
    atomic_write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return f"gemini: removed {removed} CV4 hook handler(s)"


def gemini_check(root: Path, quiet: bool) -> str:
    path = gemini_path()
    if not path.exists():
        return "gemini: settings.json absent"
    try:
        data = read_json(path)
    except InstallError as exc:
        return f"gemini: unreadable ({exc})"
    hooks = data.get("hooks") if isinstance(data, dict) else {}
    found = 0
    if isinstance(hooks, dict):
        for groups in hooks.values():
            if not isinstance(groups, list):
                continue
            for group in groups:
                inner = group.get("hooks") if isinstance(group, dict) else None
                if isinstance(inner, list):
                    found += sum(1 for h in inner if is_cv4_handler(h))
    return f"gemini: {found} CV4 hook handler(s) installed"


# ---------------------------------------------------------------- codex

CODEX_EVENTS = [
    ("SessionStart", "startup|resume|clear|compact|fork", 10),
    ("UserPromptSubmit", None, 10),
    ("PreToolUse", "Edit|Write|apply_patch", 10),
    ("PostToolUse", None, 10),
    ("Stop", None, 10),
    ("SessionEnd", None, 3),
    ("PreCompact", "manual|auto", 10),
]


def codex_path() -> Path:
    return Path(os.path.expanduser("~")) / ".codex" / "hooks.json"


def codex_command(root: Path, event: str) -> str:
    return f'bash "{dispatch_path(root)}" codex {event}'


def codex_install(root: Path, quiet: bool) -> str:
    path = codex_path()
    if not path.parent.exists():
        return "codex: not installed, skipped"
    data = read_json(path)
    if not isinstance(data, dict):
        raise InstallError(f"{path} is not a JSON object")
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        hooks = {}
    for event, matcher, timeout in CODEX_EVENTS:
        groups = hooks.get(event)
        if not isinstance(groups, list):
            groups = []
        cleaned = []
        for group in groups:
            if not isinstance(group, dict):
                continue
            inner = group.get("hooks")
            if not isinstance(inner, list):
                cleaned.append(group)
                continue
            kept = [h for h in inner if not is_cv4_handler(h)]
            if kept:
                group = dict(group)
                group["hooks"] = kept
                cleaned.append(group)
        handler = {
            "type": "command",
            "command": codex_command(root, event),
            "timeout": timeout,
            "additionalContextLimit": 6000,
        }
        group = {"hooks": [handler]}
        if matcher:
            group["matcher"] = matcher
        cleaned.append(group)
        hooks[event] = cleaned
    data["hooks"] = hooks
    backup(path)
    atomic_write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return "codex: hooks installed (7 events); approve once in /hooks"


def codex_remove(root: Path, quiet: bool) -> str:
    path = codex_path()
    if not path.exists():
        return "codex: no hooks.json, nothing to remove"
    data = read_json(path)
    if not isinstance(data, dict):
        raise InstallError(f"{path} is not a JSON object")
    hooks = data.get("hooks")
    removed = 0
    if isinstance(hooks, dict):
        for event in list(hooks.keys()):
            groups = hooks.get(event)
            if not isinstance(groups, list):
                continue
            cleaned = []
            for group in groups:
                if not isinstance(group, dict):
                    continue
                inner = group.get("hooks")
                if not isinstance(inner, list):
                    cleaned.append(group)
                    continue
                kept = [h for h in inner if not is_cv4_handler(h)]
                removed += len(inner) - len(kept)
                if kept:
                    group = dict(group)
                    group["hooks"] = kept
                    cleaned.append(group)
            if cleaned:
                hooks[event] = cleaned
            else:
                del hooks[event]
        if not hooks:
            data.pop("hooks", None)
    backup(path)
    if data:
        atomic_write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    else:
        path.unlink(missing_ok=True)
    return f"codex: removed {removed} CV4 hook handler(s)"


def codex_check(root: Path, quiet: bool) -> str:
    path = codex_path()
    if not path.exists():
        return "codex: hooks.json absent"
    try:
        data = read_json(path)
    except InstallError as exc:
        return f"codex: unreadable ({exc})"
    hooks = data.get("hooks") if isinstance(data, dict) else {}
    found = 0
    if isinstance(hooks, dict):
        for groups in hooks.values():
            if not isinstance(groups, list):
                continue
            for group in groups:
                inner = group.get("hooks") if isinstance(group, dict) else None
                if isinstance(inner, list):
                    found += sum(1 for h in inner if is_cv4_handler(h))
    return f"codex: {found} CV4 hook handler(s) installed"


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    root = Path(__file__).resolve().parents[2]
    if "--root" in sys.argv:
        index = sys.argv.index("--root")
        if index + 1 < len(sys.argv):
            root = Path(sys.argv[index + 1]).expanduser().resolve()
    quiet = "--quiet" in sys.argv
    force = "--force" in sys.argv
    target = args[0] if args else "all"
    action = args[1] if len(args) > 1 else "install"
    if action == "install" and not force and is_template(root):
        if not quiet:
            print("cv4-hooks: template clone, adapters skipped (run BOOT first, or --force)")
        return 0
    actions = {
        "claude": {"install": claude_install, "remove": claude_remove, "check": claude_check},
        "opencode": {"install": opencode_install, "remove": opencode_remove, "check": opencode_check},
        "gemini": {"install": gemini_install, "remove": gemini_remove, "check": gemini_check},
        "codex": {"install": codex_install, "remove": codex_remove, "check": codex_check},
    }
    if target == "all":
        targets = ["claude", "opencode", "gemini", "codex"]
    else:
        targets = [target]
    try:
        for name in targets:
            if name not in actions:
                raise InstallError(f"unknown target: {name}")
            if action not in actions[name]:
                raise InstallError(f"unknown action: {action}")
            line = actions[name][action](root, quiet)
            if not quiet:
                print(line)
        return 0
    except InstallError as exc:
        if not quiet:
            print(f"cv4-hooks: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"cv4-hooks: {type(exc).__name__}: {exc}", file=sys.stderr)
        sys.exit(1)
