#!/usr/bin/env python3
"""CV4 behavior spine dispatcher. One policy core, thin harness adapters.

Usage: dispatch.py <harness> <event> [--root DIR] [--doctor] [--brief]
Reads one JSON object from stdin (the harness hook payload).
Writes one JSON object (or nothing) to stdout. --brief prints the boot brief as text.

Non-negotiable: this script never blocks a session by crashing. Any unexpected
error is logged and the process exits 0 with no output. The manual path stays.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import signal
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

HARNESSES = {"claude", "opencode", "gemini", "codex"}

EVENT_ALIASES = {
    "SessionStart": "session-start",
    "session-start": "session-start",
    "UserPromptSubmit": "prompt",
    "BeforeAgent": "prompt",
    "prompt": "prompt",
    "PreToolUse": "pre-tool",
    "BeforeTool": "pre-tool",
    "pre-tool": "pre-tool",
    "tool-before": "pre-tool",
    "PostToolUse": "post-tool",
    "AfterTool": "post-tool",
    "post-tool": "post-tool",
    "tool-after": "post-tool",
    "Stop": "stop",
    "AfterAgent": "stop",
    "stop": "stop",
    "idle": "stop",
    "SessionEnd": "session-end",
    "session-end": "session-end",
    "PreCompact": "pre-compact",
    "PreCompress": "pre-compact",
    "pre-compact": "pre-compact",
    "idle-check": "idle-check",
    "idle-save": "idle-save",
    "idle-clear": "idle-clear",
}

EDIT_TOOLS = {
    "edit", "write", "apply_patch", "write_file", "replace", "edit_file",
    "writefile", "multiedit", "notebookedit",
}

STOPWORDS = set(
    """the and for with that this from have has had was were are is be been being
    you your yours we our ours they them their it its but not can could should would
    will just now then than into onto over under about after before again also
    what when where which who whom why how all any some more most very much many
    i me my mine he she his her hers do does did doing done get got gets getting
    please help need needs want wants make makes made use used using""".split()
)


# ---------------------------------------------------------------- utilities

def home_dir() -> Path:
    env = os.environ.get("HOME")
    if env:
        return Path(env)
    return Path(os.path.expanduser("~"))




def now() -> datetime:
    raw = os.environ.get("CV4_NOW")
    if raw:
        try:
            value = datetime.fromisoformat(raw)
            return value if value.tzinfo else value.astimezone()
        except ValueError:
            pass
    return datetime.now().astimezone()


def iso(dt: datetime) -> str:
    return dt.isoformat(timespec="seconds")


def clip(text: str, cap: int) -> str:
    if not text:
        return ""
    if len(text) <= cap:
        return text
    cut = text.rfind("\n", 0, cap)
    if cut < cap // 2:
        cut = cap
    return text[:cut].rstrip() + "\n[... trimmed ...]"


def read_text(path: Path, cap: int = 0) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    return clip(text, cap) if cap else text


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


def read_json(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return default


def write_json(path: Path, obj) -> None:
    atomic_write(path, json.dumps(obj, ensure_ascii=True, indent=2) + "\n")


def deep_merge(base: dict, extra: dict) -> dict:
    out = dict(base)
    for key, value in (extra or {}).items():
        if isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = value
    return out


def safe_sid(raw: str) -> str:
    raw = str(raw or "unknown")
    return re.sub(r"[^A-Za-z0-9._-]", "_", raw)[:80] or "unknown"


def parse_iso(value: str):
    try:
        return datetime.fromisoformat(value)
    except (TypeError, ValueError):
        return None


def parse_hhmm(value: str):
    match = re.match(r"^(\d{1,2}):(\d{2})$", str(value or "").strip())
    if not match:
        return None
    hour, minute = int(match.group(1)), int(match.group(2))
    if 0 <= hour <= 23 and 0 <= minute <= 59:
        return hour, minute
    return None


def time_bucket(dt: datetime) -> str:
    hour = dt.hour
    if 5 <= hour < 12:
        return "morning"
    if 12 <= hour < 17:
        return "afternoon"
    if 17 <= hour < 22:
        return "evening"
    if 22 <= hour < 24:
        return "getting late"
    return "small hours"


def ago_label(delta: timedelta) -> str:
    seconds = max(0, int(delta.total_seconds()))
    minutes = seconds // 60
    if seconds < 300:
        return "just now"
    if minutes < 60:
        return f"{minutes} minutes ago"
    if minutes < 360:
        return f"{minutes // 60} hours ago"
    if minutes < 1440:
        return "earlier today"
    if minutes < 2880:
        return "yesterday"
    return f"{minutes // 1440} days ago"


def median(values):
    values = sorted(values)
    if not values:
        return None
    mid = len(values) // 2
    if len(values) % 2:
        return values[mid]
    return (values[mid - 1] + values[mid]) / 2.0


def log_event(root: Path, harness: str, event: str, action: str, reason: str,
              ms: int, sid: str) -> None:
    try:
        log = root / "logs" / "hooks.log"
        log.parent.mkdir(parents=True, exist_ok=True)
        line = json.dumps(
            {
                "ts": iso(now()),
                "harness": harness,
                "event": event,
                "action": action,
                "reason": reason,
                "ms": ms,
                "sid": sid,
            },
            ensure_ascii=True,
            separators=(",", ":"),
        )
        with log.open("a", encoding="utf-8") as handle:
            handle.write(line + "\n")
        if log.stat().st_size > 200_000:
            lines = log.read_text(encoding="utf-8", errors="replace").splitlines()
            atomic_write(log, "\n".join(lines[-1000:]) + "\n")
    except OSError:
        pass


# ---------------------------------------------------------------- context

class Ctx:
    def __init__(self, root: Path, harness: str, event_name: str, event: dict):
        self.root = root
        self.harness = harness
        self.event_name = event_name
        self.event = event if isinstance(event, dict) else {}
        self.sid = safe_sid(
            self.event.get("session_id")
            or self.event.get("sessionID")
            or self.event.get("thread_id")
            or self.event.get("id")
        )
        self.state_dir = root / "logs" / ".state"
        self.checkpoint_dir = root / "logs" / "checkpoints"
        self.state_path = self.state_dir / f"{self.sid}.json"
        self.checkpoint_path = self.checkpoint_dir / f"{now():%Y-%m-%d}-{self.sid}.md"
        self.policy = self._load_policy()
        self.mode = str(self.policy.get("mode", "live")).lower()
        self.shadow = self.mode == "shadow"
        self.state = self._load_state()
        self.t0 = datetime.now()
        self._tz_cache = None

    # -- user clock

    def _user_tz(self):
        if self._tz_cache is not None:
            return self._tz_cache
        text = read_text(self.root / "main" / "relationship-memory.md", 6000).lower()
        match = re.search(r"timezone[^\n:]*:\s*(.+)", text)
        value = match.group(1).strip() if match else ""
        table = [
            ("utc+9", 9), ("utc+09", 9), ("jst", 9), ("tokyo", 9), ("japan", 9),
            ("utc+8", 8), ("utc+08", 8), ("myt", 8), ("tst", 8), ("sgt", 8),
            ("kuala lumpur", 8), ("malaysia", 8), ("manila", 8),
            ("utc+7", 7), ("utc+07", 7), ("ict", 7), ("jakarta", 7),
            ("utc+5:30", 5.5), ("utc+05:30", 5.5), ("ist", 5.5),
        ]
        for token, hours in table:
            if token in value:
                self._tz_cache = timezone(timedelta(hours=hours))
                return self._tz_cache
        self._tz_cache = False
        return None

    def user_now(self) -> datetime:
        tz = self._user_tz()
        return now().astimezone(tz) if tz else now()

    # -- loading

    def _load_policy(self) -> dict:
        base = read_json(self.root / "tools" / "hooks" / "policy.json", {})
        user = read_json(self.root / "main" / "behavior.json", {})
        return deep_merge(base if isinstance(base, dict) else {}, user if isinstance(user, dict) else {})

    def _load_state(self) -> dict:
        source = str(self.event.get("source") or "").lower()
        existing = read_json(self.state_path, None)
        if isinstance(existing, dict) and source not in ("startup", "clear"):
            existing["closed"] = False
            return existing
        return {
            "session_id": self.sid,
            "harness": self.harness,
            "cwd": self.event.get("cwd") or str(self.root),
            "started_at": iso(now()),
            "last_event_at": iso(now()),
            "turns": 0,
            "tool_calls": 0,
            "edits": 0,
            "files": [],
            "last_prompt": "",
            "last_assistant": "",
            "flags": {
                "work": False,
                "save_requested": False,
                "save_done": False,
                "recall_required": False,
                "recall_gate_done": False,
                "update_offered": False,
                "update_version": "",
                "compact_seen": False,
                "suggested": False,
            },
            "closed": False,
            "save_requested_at": 0,
            "last_save_at": 0,
            "last_cadence_at": 0,
            "late_done_date": "",
            "blocks": 0,
            "last_block_kind": "",
        }

    def save_state(self) -> None:
        self.state["last_event_at"] = iso(now())
        try:
            write_json(self.state_path, self.state)
        except OSError:
            pass

    def flags(self) -> dict:
        return self.state.setdefault("flags", {})

    def log(self, action: str, reason: str) -> None:
        ms = int((datetime.now() - self.t0).total_seconds() * 1000)
        log_event(self.root, self.harness, self.event_name, action, reason, ms, self.sid)

    # -- brief

    def build_brief(self) -> str:
        if self.shadow:
            self.log("skip", "shadow-brief")
            return ""
        if not self.policy.get("brief", {}).get("enabled", True):
            return ""
        flags = self.flags()
        if flags.get("save_requested") and self._saved_since(int(self.state.get("save_requested_at", 0))):
            self._mark_saved()
            self._clear_pending()
        budget = int(self.policy.get("brief_chars", 9000))
        parts = []
        meta = [
            f"[CV4 boot] {self.user_now():%Y-%m-%d %H:%M %Z} ({time_bucket(self.user_now())})",
            "Loaded by the behavior spine. Do not announce the load. The first words are the greeting.",
            "This brief is the session load. If the manual says to run tools/session-load.sh, skip it; do not double-load.",
            f"home: {self.root}. All companion paths (main/, memory/, logs/, skills/) resolve under home; use absolute paths.",
        ]

        last = self._last_session_label()
        if last:
            meta.append(last)

        update = self._update_check()
        if update:
            self.flags()["update_offered"] = True
            self.flags()["update_version"] = update["new"]
            meta.append(
                f"update: CV4 v{update['old']} -> v{update['new']} ({update['commits']} commits). "
                "Greet with one line: there is a CV4 update, want me to update?"
            )
        if self.shadow:
            meta.append("mode: shadow (no injections, no blocks; log only)")

        pending = self._pending_save()
        if pending:
            meta.append(
                f"unsaved session: {pending.get('at', '?')} ({pending.get('harness', '?')}). "
                f"Checkpoint: {pending.get('checkpoint', '')}. Fold it in after the greeting, or offer to."
            )
        stale = None if pending else self._stale_session()
        if stale:
            meta.append(
                f"stale session: {stale.get('at', '?')} ({stale.get('harness', '?')}). "
                f"Checkpoint: {stale.get('checkpoint', '')}. It never closed cleanly; fold it in or offer to save."
            )

        manual = self._manual_rev_note()
        if manual:
            meta.append(manual)

        doctor = self._doctor_line()
        if doctor:
            meta.append(doctor)

        parts.append("\n".join(meta))

        sections = [
            ("identity", self.root / "main" / "identity-core.md", 1, 1200),
            ("soul", self.root / "main" / "soul.md", 2, 1800),
            ("hotlist", self.root / "main" / "hotlist.md", 3, 2200),
            ("current session", self.root / "main" / "current-session.md", 4, 1800),
        ]
        for name, path, _prio, cap in sections:
            text = read_text(path, cap)
            if text:
                parts.append(f"===== {name} =====\n{text}")

        reminders = self._open_reminders()
        if reminders:
            parts.append("===== open reminders =====\n" + reminders)

        index = self._index_hot()
        if index:
            parts.append("===== index hot =====\n" + index)

        return clip("\n\n".join(parts), budget)

    def _last_session_label(self) -> str:
        text = read_text(self.root / "main" / "current-session.md", 2000)
        match = re.search(r"Last updated:\s*([0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2})", text)
        if not match:
            return ""
        try:
            stamp = datetime.strptime(match.group(1).replace("T", " "), "%Y-%m-%d %H:%M")
            stamp = stamp.replace(tzinfo=self.user_now().tzinfo)
        except ValueError:
            return ""
        return f"last session: {stamp:%Y-%m-%d %H:%M} ({ago_label(self.user_now() - stamp)})"

    def _open_reminders(self) -> str:
        text = read_text(self.root / "memory" / "reminders.md", 20000)
        if not text:
            return ""
        lines = text.splitlines()
        open_lines = []
        in_open = False
        for line in lines:
            if re.match(r"^##\s+Open", line, re.I):
                in_open = True
                continue
            if in_open and re.match(r"^##\s+", line):
                break
            if in_open and re.match(r"^\s*-\s+\[ \]", line):
                open_lines.append(line.rstrip())
        return clip("\n".join(open_lines[:30]), 1400)

    def _index_hot(self) -> str:
        text = read_text(self.root / "memory" / "index.md", 20000)
        if not text:
            return ""
        lines = text.splitlines()
        hot = []
        in_hot = False
        for line in lines:
            if re.match(r"^##\s+.*Hot", line, re.I):
                in_hot = True
                continue
            if in_hot and re.match(r"^##\s+", line):
                break
            if in_hot and line.strip().startswith("|"):
                hot.append(line.rstrip())
        return clip("\n".join(hot[:14]), 1600)

    def _doctor_line(self) -> str:
        problems = []
        try:
            self.state_dir.mkdir(parents=True, exist_ok=True)
            probe = self.state_dir / ".probe"
            probe.write_text("ok", encoding="utf-8")
            probe.unlink()
        except OSError:
            problems.append("state")
        if not (self.root / "tools" / "fts.py").exists():
            problems.append("index")
        if not problems:
            return ""
        return f"hooks: degraded ({', '.join(problems)}). Run bash tools/hooks/doctor.sh."

    def _manual_rev_note(self) -> str:
        boot = read_text(self.root / "BOOT.md", 50000)
        source = re.search(r"Manual rev:\s*([0-9]+\.[0-9]+\.[0-9]+)", boot)
        if not source:
            return ""
        home = home_dir()
        candidates = [
            Path(home) / ".claude" / "CLAUDE.md",
            Path(home) / ".config" / "opencode" / "AGENTS.md",
            Path(home) / ".gemini" / "GEMINI.md",
            Path(home) / ".codex" / "AGENTS.md",
        ]
        installed = ""
        for path in candidates:
            text = read_text(path, 200000)
            if "CV4 companion: start" not in text:
                continue
            block = text.split("CV4 companion: start", 1)[-1].split("CV4 companion: end", 1)[0]
            match = re.search(r"Manual rev:\s*([0-9]+\.[0-9]+\.[0-9]+)", block)
            if match:
                installed = match.group(1)
                break
        if installed and installed != source.group(1):
            return f"manual: installed rev {installed}, engine rev {source.group(1)}. Offer a refresh after any update."
        return ""

    # -- update check

    def _update_check(self):
        try:
            timeout = int(self.policy.get("update", {}).get("timeout_ms", 3000)) / 1000.0
            cache_seconds = int(self.policy.get("update", {}).get("cache_seconds", 600))
            cache_path = self.state_dir / "update-check.json"
            cached = read_json(cache_path, {})
            if isinstance(cached, dict) and cached.get("ts"):
                age = (now() - parse_iso(cached["ts"])).total_seconds() if parse_iso(cached["ts"]) else 10**9
                if age < cache_seconds:
                    return None if self._declined(cached) else (cached if cached.get("commits") else None)
            remote = self._update_remote()
            if not remote:
                return None
            env = dict(os.environ)
            env["GIT_TERMINAL_PROMPT"] = "0"
            subprocess.run(
                ["git", "-C", str(self.root), "fetch", "--quiet", remote, "main"],
                timeout=timeout,
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            count = subprocess.run(
                ["git", "-C", str(self.root), "rev-list", "--count", "HEAD..FETCH_HEAD"],
                timeout=timeout,
                env=env,
                capture_output=True,
                text=True,
                check=False,
            ).stdout.strip()
            commits = int(count or 0)
            if commits <= 0:
                write_json(cache_path, {"ts": iso(now()), "commits": 0})
                return None
            old = (read_text(self.root / "versions" / "VERSION", 32) or "?").strip()
            new = subprocess.run(
                ["git", "-C", str(self.root), "show", "FETCH_HEAD:versions/VERSION"],
                timeout=timeout,
                env=env,
                capture_output=True,
                text=True,
                check=False,
            ).stdout.strip() or old
            result = {"commits": commits, "old": old, "new": new}
            write_json(cache_path, dict(result, ts=iso(now())))
            return None if self._declined(result) else result
        except (OSError, subprocess.SubprocessError, ValueError):
            return None

    def _update_remote(self):
        url = subprocess.run(
            ["git", "-C", str(self.root), "remote", "get-url", "origin"],
            capture_output=True,
            text=True,
            check=False,
        ).stdout.strip()
        if os.environ.get("CV4_UPSTREAM"):
            return "upstream"
        if url and "wanshazamirul/CV4" in url:
            return "upstream"
        return "origin" if url else ""

    def _declined(self, result: dict) -> bool:
        version = result.get("new") or ""
        return bool(version) and (self.state_dir / f"update-declined-{safe_sid(version)}").exists()

    # -- pending save

    def _pending_save(self):
        try:
            files = sorted(self.state_dir.glob("pending-save-*.json"), key=lambda p: p.stat().st_mtime)
        except OSError:
            return None
        for path in reversed(files[-3:]):
            data = read_json(path, None)
            if isinstance(data, dict) and data.get("checkpoint"):
                return data
        return None

    def _stale_session(self):
        cutoff = now().timestamp() - 2 * 3600
        best = None
        try:
            paths = list(self.state_dir.glob("*.json"))
        except OSError:
            return None
        for path in paths:
            if path.name.startswith(("update-", "timing", "pending-save-")):
                continue
            data = read_json(path, None)
            if not isinstance(data, dict):
                continue
            if data.get("closed"):
                continue
            if data.get("session_id") == self.sid:
                continue
            if data.get("flags", {}).get("save_done"):
                continue
            if not (data.get("tool_calls") or data.get("edits") or int(data.get("turns", 0)) > 1):
                continue
            last = parse_iso(data.get("last_event_at", ""))
            if not last or last.timestamp() > cutoff:
                continue
            if best is None or last.timestamp() > best[0].timestamp():
                best = (last, data)
        if not best:
            return None
        data = best[1]
        sid = safe_sid(data.get("session_id", ""))
        checkpoints = []
        try:
            checkpoints = sorted(self.checkpoint_dir.glob(f"*-{sid}.md"), key=lambda p: p.stat().st_mtime)
        except OSError:
            pass
        return {
            "at": data.get("last_event_at", "?"),
            "harness": data.get("harness", "?"),
            "checkpoint": str(checkpoints[-1]) if checkpoints else "",
        }

    # -- idle watcher

    def _idle_minutes(self) -> float:
        env = os.environ.get("CV4_IDLE_MINUTES")
        if env:
            try:
                return max(0.0, float(env))
            except ValueError:
                pass
        try:
            return max(0.0, float(self.policy.get("auto_save", {}).get("idle_minutes", 15)))
        except (TypeError, ValueError):
            return 15.0

    def _idle_pid(self) -> int:
        try:
            return int(self.state.get("idle_pid", 0) or 0)
        except (TypeError, ValueError):
            return 0

    def _schedule_idle(self) -> None:
        if self.shadow or self.flags().get("save_done") or self.state.get("closed"):
            return
        minutes = self._idle_minutes()
        if minutes <= 0 or not self._has_work():
            return
        script = self.root / "tools" / "hooks" / "idle-save.sh"
        if not script.exists():
            return
        bash = shutil.which("bash")
        if not bash:
            return
        started = parse_iso(self.state.get("idle_started", ""))
        if self._idle_pid() and started and (now() - started).total_seconds() < max(300, minutes * 120):
            return
        try:
            kwargs = {"start_new_session": True} if os.name == "posix" else {"creationflags": 0x00000008}
            proc = subprocess.Popen(
                [bash, str(script), self.sid, self.harness, str(self.root), f"{minutes:g}"],
                cwd=str(self.root),
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                **kwargs,
            )
            self.state["idle_pid"] = proc.pid
            self.state["idle_started"] = iso(now())
            self.log("worker", "idle-watch")
            self.save_state()
        except OSError:
            pass

    def _cancel_idle(self) -> None:
        pid = self._idle_pid()
        if pid:
            try:
                os.kill(pid, signal.SIGTERM)
            except OSError:
                pass
        self.state["idle_pid"] = 0
        self.state["idle_started"] = ""

    def idle_check(self) -> str:
        if self.state.get("closed") or self.flags().get("save_done") or not self._has_work():
            return "stop"
        last = parse_iso(self.state.get("last_event_at", "")) or now()
        idle = (now() - last).total_seconds() / 60.0
        return "save" if idle >= self._idle_minutes() else "wait"

    def idle_save(self) -> None:
        flags = self.flags()
        if self.state.get("closed") or flags.get("save_done") or not self._has_work():
            return
        if (self.state_dir / f"pending-save-{self.sid}.json").exists():
            return
        self.checkpoint("idle save")
        try:
            write_json(self.state_dir / f"pending-save-{self.sid}.json", self._pending_payload())
        except OSError:
            pass
        flags["save_requested"] = True
        flags["save_done"] = False
        self.state["save_requested_at"] = now().timestamp()
        self.save_state()
        if self._worker_enabled():
            self._spawn_close_worker()
        self.log("worker", "idle-save")

    def idle_clear(self) -> None:
        try:
            pid = int(self.event.get("pid") or 0)
        except (TypeError, ValueError):
            pid = 0
        if pid and self._idle_pid() == pid:
            self.state["idle_pid"] = 0
            self.state["idle_started"] = ""
            try:
                write_json(self.state_path, self.state)
            except OSError:
                pass

    def _pending_payload(self) -> dict:
        return {
            "at": iso(now()),
            "harness": self.harness,
            "cwd": self.state.get("cwd") or self.event.get("cwd") or str(self.root),
            "checkpoint": str(self.checkpoint_path),
            "last_prompt": self.state.get("last_prompt", ""),
            "last_assistant": self.state.get("last_assistant", ""),
        }

    def _clear_pending(self) -> None:
        try:
            (self.state_dir / f"pending-save-{self.sid}.json").unlink()
        except OSError:
            pass

    # -- checkpoint

    def checkpoint(self, note: str = "") -> None:
        try:
            self.checkpoint_dir.mkdir(parents=True, exist_ok=True)
            existing = read_text(self.checkpoint_path, 50000)
            if not existing:
                existing = (
                    f"# CV4 checkpoint - {self.sid}\n"
                    f"Started: {iso(self.user_now())} | harness: {self.harness} | cwd: {self.event.get('cwd', '')}\n"
                    "Raw material for the save ritual. Append-only.\n\n"
                )
            line = f"- {self.user_now():%H:%M} {note}\n"
            if len(existing) < 40000:
                with self.checkpoint_path.open("a", encoding="utf-8") as handle:
                    handle.write(line)
        except OSError:
            pass

    # -- prompt router

    def route_prompt(self) -> str:
        prompt = str(
            self.event.get("prompt")
            or self.event.get("user_prompt")
            or self.event.get("message")
            or ""
        ).strip()
        if not prompt:
            return ""
        self.state["turns"] = int(self.state.get("turns", 0)) + 1
        self.state["last_prompt"] = clip(prompt, 400)
        if self.shadow:
            self.log("skip", "shadow-router")
            return ""
        low = prompt.lower()
        flags = self.flags()

        if self._yes_no_update(low):
            return self._update_instruction()

        save = re.search(
            r"\b(save|save progress|save session|wrap up|wrap it up|close session|end session|"
            r"goodbye|good night|goodnight|bye|done for today|that'?s all|thats all|"
            r"we'?re done|we are done|stop here)\b",
            low,
        )
        if save and self.policy.get("auto_save", {}).get("goodbye", True):
            flags["save_requested"] = True
            flags["save_done"] = False
            self.state["save_requested_at"] = now().timestamp()
            self.checkpoint(f"save requested ({save.group(0)})")
            return self._skill(
                "save",
                "goodbye detected. This is a full save, not lite. Run the ritual now, then reply with one line: autosaved.",
            )

        debug = re.search(
            r"\b(bug|broken|not working|doesn'?t work|does not work|error|fails?|failing|"
            r"why is|troubleshoot|debug|fix)\b",
            low,
        )
        if debug:
            flags["recall_required"] = True
            flags["recall_gate_done"] = False
            recall = self._auto_recall(prompt)
            skill = self._skill(
                "recall-memory",
                "bug-shaped prompt. Recall evidence is below. Cite a file, or say 'Recall: clear', before the first edit.",
            )
            return (recall + "\n\n" + skill).strip()

        if re.search(r"\b(build|implement|ship|create|add (a )?feature|refactor|rewrite)\b", low):
            return self._skill(
                "build-protocol",
                "build track. G0: freedom words expand what may be built, never which gates run. Follow the protocol.",
            )

        if re.search(r"\b(remind me|don'?t forget|dont forget|check reminders|what'?s open|whats open|add a reminder)\b", low):
            return self._skill("check-reminders", "reminders request.")
        if re.search(r"\b(log (this )?decision|decision made|let'?s go with|we'?ll go with|we will go with|decided)\b", low):
            return self._skill("decision-log", "decision detected.")
        if re.search(r"\b(forge|that keeps happening|happened again|again and again|third time|3rd time)\b", low):
            return self._skill("forge", "repetition detected.")
        if re.search(r"\b(what do you think of this|review this|import this|adopt this|check this (tool|repo|skill|file))\b", low):
            return self._skill("intake", "foreign material detected. Screen it before it lands.")
        return ""

    def _yes_no_update(self, low: str) -> bool:
        if not self.flags().get("update_offered"):
            return False
        if re.match(r"^(yes|yeah|yep|sure|go|update|do it|ok|okay)\b", low):
            self.flags()["update_offered"] = False
            return True
        if re.match(r"^(no|nope|not now|later|skip|don'?t|dont)\b", low):
            version = safe_sid(self.flags().get("update_version", ""))
            if version:
                try:
                    atomic_write(self.state_dir / f"update-declined-{version}", iso(now()) + "\n")
                except OSError:
                    pass
            self.flags()["update_offered"] = False
            return False
        return False

    def _update_instruction(self) -> str:
        flow = self.root / "tools" / "update-flow.sh"
        command = "bash tools/update-flow.sh" if flow.exists() else "bash tools/update.sh && bash tools/repair.sh"
        return (
            "[CV4 update] The user approved the update. Do this now, in order: "
            f"1) `{command}`; "
            "2) run the save ritual (skills/save), full save; "
            "3) if the manual rev changed, refresh the installed block; "
            "4) re-run `bash tools/session-load.sh --no-update`. "
            "Reply with one line when done."
        )

    def _skill(self, name: str, why: str) -> str:
        if not self.policy.get("router", {}).get("enabled", True):
            return ""
        path = self.root / "skills" / name / "SKILL.md"
        body = read_text(path, int(self.policy.get("skill_chars", 6000)))
        home = f"[CV4] Home: {self.root}. Use absolute paths under Home for main/, memory/, logs/, skills/."
        if not body:
            return f"{home}\n[CV4 router] {why} Read skills/{name}/SKILL.md and follow it."
        return f"{home}\n[CV4 router] {why}\n\n{body}"

    # -- auto recall

    def _auto_recall(self, prompt: str) -> str:
        words = []
        for word in re.findall(r"[A-Za-z0-9_][A-Za-z0-9_-]{2,}", prompt.lower()):
            if word not in STOPWORDS and word not in words:
                words.append(word)
        words = words[:6]
        if not words:
            return ""
        fts = self.root / "tools" / "fts.py"
        hits = []
        if fts.exists():
            try:
                result = subprocess.run(
                    [sys.executable, str(fts), " ".join(words)],
                    cwd=str(self.root),
                    capture_output=True,
                    text=True,
                    timeout=2,
                    check=False,
                )
                for line in result.stdout.splitlines():
                    if line.startswith("  [") or line.startswith("Top "):
                        hits.append(line.rstrip())
            except (OSError, subprocess.SubprocessError):
                pass
        hotlist = read_text(self.root / "main" / "hotlist.md", 10000)
        hot_hits = []
        for line in hotlist.splitlines():
            if not line.strip().startswith("- "):
                continue
            score = sum(1 for word in words if word in line.lower())
            if score:
                hot_hits.append((score, line.rstrip()))
        hot_hits.sort(reverse=True)
        lines = ["[CV4 recall] Evidence for this prompt (the hook ran it for you):"]
        lines.extend(hot_hits[:3][i][1] for i in range(min(3, len(hot_hits))))
        lines.extend(hits[:6])
        if len(lines) == 1:
            lines.append("No matching hotlist or index hit. Recall: clear. State it, then proceed.")
        lines.append("Cite the file, or say 'Recall: clear'. Do not start from zero.")
        return clip("\n".join(lines), int(self.policy.get("recall_chars", 2500)))

    # -- tool tracking

    def pre_tool(self):
        flags = self.flags()
        tool = str(self.event.get("tool_name") or self.event.get("tool") or "").lower()
        is_edit = any(name in tool for name in EDIT_TOOLS)
        if is_edit and flags.get("recall_required") and not flags.get("recall_gate_done"):
            if not self.policy.get("recall", {}).get("hard_gate", True):
                return None
            if self.shadow:
                self.log("skip", "shadow-recall-gate")
                return None
            if int(self.state.get("blocks", 0)) >= int(self.policy.get("auto_save", {}).get("max_blocks", 2)):
                return None
            flags["recall_gate_done"] = True
            self.state["blocks"] = int(self.state.get("blocks", 0)) + 1
            self.log("block", "recall-gate")
            return (
                "CV4 recall gate. Before this edit, use the recall evidence above. "
                "Cite the matching pattern or file, or say 'Recall: clear'. "
                "If this is a trivial fix, say 'trivial' and retry the edit."
            )
        return None

    def post_tool(self) -> None:
        tool = str(self.event.get("tool_name") or self.event.get("tool") or "tool")
        self.state["tool_calls"] = int(self.state.get("tool_calls", 0)) + 1
        tool_input = self.event.get("tool_input") or {}
        path = ""
        command = ""
        if isinstance(tool_input, dict):
            path = str(tool_input.get("file_path") or tool_input.get("path") or "")
            command = str(tool_input.get("command") or "")
        if any(name in tool.lower() for name in EDIT_TOOLS):
            self.state["edits"] = int(self.state.get("edits", 0)) + 1
            if path:
                files = self.state.setdefault("files", [])
                if path not in files:
                    files.append(path)
                    if len(files) > 50:
                        del files[: len(files) - 50]
        detail = path or clip(command.replace("\n", " "), 120)
        self.checkpoint(f"tool={tool} {detail}".strip())
        if "fts.py" in command or "recall" in command.lower():
            self.flags()["recall_done"] = True
        self.save_state()

    # -- turn end

    def stop(self):
        last = self.event.get("last_assistant_message") or self.event.get("prompt_response") or ""
        if last:
            self.state["last_assistant"] = clip(str(last), 600)
        self._schedule_idle()
        flags = self.flags()
        if flags.get("save_requested") and self._saved_since(int(self.state.get("save_requested_at", 0))):
            self._mark_saved()
            self._clear_pending()
            self.save_state()
            self.log("skip", "save-detected")
            return None
        if not self._has_work():
            self.save_state()
            return None
        if self.shadow:
            self.save_state()
            return None
        trigger = self._save_trigger()
        if trigger:
            max_blocks = int(self.policy.get("auto_save", {}).get("max_blocks", 2))
            if self.event.get("stop_hook_active"):
                self.save_state()
                return None
            if int(self.state.get("blocks", 0)) >= max_blocks:
                self.save_state()
                return None
            self.state["blocks"] = int(self.state.get("blocks", 0)) + 1
            self.state["last_block_kind"] = trigger
            flags["save_requested"] = True
            flags["save_done"] = False
            self.state["save_requested_at"] = now().timestamp()
            if trigger == "late":
                self.state["late_done_date"] = f"{self.user_now():%Y-%m-%d}"
            if trigger == "cadence":
                self.state["last_cadence_at"] = now().timestamp()
            self.checkpoint(f"autosave trigger: {trigger}")
            self.log("block", f"save-{trigger}")
            self.save_state()
            return (
                f"CV4 autosave ({trigger}). Run the save ritual now: skills/save. "
                "Write the session log, memory/index, decisions, reminders sweep, rotation. "
                "Then reply with one line: autosaved."
            )
        if self._suggest_due() and not flags.get("suggested"):
            flags["suggested"] = True
            self.save_state()
            self.log("inject", "save-suggestion")
            return {"suggest": "This session is long. Offer a save in one line when there is a natural pause."}
        self.save_state()
        return None

    def _save_trigger(self) -> str:
        flags = self.flags()
        if flags.get("save_requested"):
            return "goodbye"
        policy = self.policy.get("auto_save", {})
        if self._late_due(policy):
            return "late"
        if self._cadence_due(policy):
            return "cadence"
        if flags.get("compact_seen"):
            return "pre-compact"
        return ""

    def _late_due(self, policy: dict) -> bool:
        today = f"{self.user_now():%Y-%m-%d}"
        if self.state.get("late_done_date") == today:
            return False
        value = policy.get("late", "adaptive")
        trigger = None
        if isinstance(value, str) and value != "adaptive":
            trigger = parse_hhmm(value)
        if not trigger:
            trigger = self._adaptive_late(policy)
        if not trigger:
            return False
        hour, minute = trigger
        current = self.user_now()
        return (current.hour, current.minute) >= (hour, minute)

    def _adaptive_late(self, policy: dict):
        timing = read_json(self.state_dir / "timing.json", {})
        if isinstance(timing, dict) and timing.get("late"):
            return parse_hhmm(timing["late"])
        return parse_hhmm(policy.get("late_fallback", "23:00"))

    def _cadence_due(self, policy: dict) -> bool:
        cadence = self._cadence_minutes(policy)
        if not cadence:
            return False
        started = parse_iso(self.state.get("started_at", "")) or now()
        active = (now() - started).total_seconds() / 60.0
        if active < cadence:
            return False
        last = max(
            float(self.state.get("last_save_at", 0) or 0),
            float(self.state.get("last_cadence_at", 0) or 0),
        )
        return (now().timestamp() - last) >= cadence * 60

    def _cadence_minutes(self, policy: dict) -> int:
        value = policy.get("cadence", "adaptive")
        if isinstance(value, (int, float)):
            return int(value)
        timing = read_json(self.state_dir / "timing.json", {})
        if isinstance(timing, dict) and timing.get("cadence_min"):
            return int(timing["cadence_min"])
        return int(policy.get("cadence_fallback_min", 90))

    def _suggest_due(self) -> bool:
        minutes = int(self.policy.get("auto_save", {}).get("suggest_minutes", 60))
        started = parse_iso(self.state.get("started_at", "")) or now()
        return (now() - started).total_seconds() / 60.0 >= minutes

    def _has_work(self) -> bool:
        return bool(
            self.state.get("edits")
            or self.state.get("tool_calls")
            or int(self.state.get("turns", 0)) > 1
        )

    def _saved_since(self, epoch: int) -> bool:
        if not epoch:
            return False
        candidates = [
            self.root / "main" / "current-session.md",
            self.root / "logs" / "current" / f"{now():%Y-%m-%d}.md",
        ]
        for path in candidates:
            try:
                if path.exists() and path.stat().st_mtime > epoch:
                    return True
            except OSError:
                continue
        return False

    def _mark_saved(self) -> None:
        self.flags()["save_done"] = True
        self.flags()["save_requested"] = False
        self.flags()["compact_seen"] = False
        self.state["last_save_at"] = now().timestamp()
        self.state["blocks"] = 0
        self.log("skip", "save-complete")

    # -- session end

    def session_end(self) -> None:
        self._cancel_idle()
        self.checkpoint(
            f"session end | turns={self.state.get('turns', 0)} tools={self.state.get('tool_calls', 0)} "
            f"edits={self.state.get('edits', 0)} saved={self.flags().get('save_done', False)}"
        )
        if self._has_work() and not self.flags().get("save_done"):
            try:
                write_json(self.state_dir / f"pending-save-{self.sid}.json", self._pending_payload())
            except OSError:
                pass
            self.log("skip", "pending-save")
            if self._worker_enabled():
                self._spawn_close_worker()
        self.state["closed"] = True
        self._append_usage()
        self.save_state()

    def _worker_enabled(self) -> bool:
        mode = str(self.policy.get("auto_save", {}).get("on_close", "auto")).lower()
        if mode == "checkpoint":
            return False
        if mode == "worker":
            return True
        role = ""
        try:
            for line in (self.root / "personas" / ".machine").read_text(encoding="utf-8", errors="replace").splitlines():
                if line.startswith("role="):
                    role = line.split("=", 1)[1].strip().lower()
                    break
        except OSError:
            role = ""
        return role != "member"

    def _spawn_close_worker(self) -> bool:
        commands = {
            "claude": ["claude", "-p"],
            "opencode": ["opencode", "run"],
            "gemini": ["gemini", "-p"],
            "codex": ["codex", "exec"],
        }
        base = commands.get(self.harness)
        if not base:
            return False
        exe = shutil.which(base[0])
        if not exe and os.name == "nt":
            # shutil.which ignores bare scripts with no PATHEXT extension on Windows.
            for part in os.environ.get("PATH", "").split(os.pathsep):
                candidate = Path(part.strip('"')) / base[0]
                if candidate.is_file():
                    exe = str(candidate)
                    break
        if not exe:
            return False
        cmd = list(base)
        if os.name == "nt":
            lower = exe.lower()
            if lower.endswith((".cmd", ".bat")):
                cmd = ["cmd.exe", "/c", exe] + base[1:]
            elif not lower.endswith((".exe", ".com")):
                bash = shutil.which("bash")
                if not bash:
                    return False
                cmd = [bash, exe] + base[1:]
        pending = self.state_dir / f"pending-save-{self.sid}.json"
        prompt = (
            f"CV4 close-save worker. Home: {self.root}. "
            f"Read the checkpoint at {self.checkpoint_path}. "
            f"Run the save ritual from {self.root / 'skills' / 'save' / 'SKILL.md'} now: "
            f"append today's log under {self.root / 'logs' / 'current'}, "
            f"update {self.root / 'main' / 'current-session.md'}, {self.root / 'memory' / 'index.md'}, "
            f"decisions, reminders, rotation. Use absolute paths. Do not ask questions. Do not commit. "
            f"When done, delete {pending} and write one line to {self.state_dir / 'close-save.log'}."
        )
        env = dict(os.environ)
        env["CV4_HOOKS"] = "0"
        log = self.state_dir / "close-save.log"
        try:
            with log.open("a", encoding="utf-8") as handle:
                kwargs = {"start_new_session": True} if os.name == "posix" else {"creationflags": 0x00000008}
                subprocess.Popen(
                    cmd + [prompt],
                    cwd=str(self.root),
                    env=env,
                    stdin=subprocess.DEVNULL,
                    stdout=handle,
                    stderr=subprocess.STDOUT,
                    **kwargs,
                )
            self.log("worker", "close-save")
            return True
        except OSError:
            return False

    def pre_compact(self) -> None:
        self.flags()["compact_seen"] = True
        self.checkpoint("pre-compact checkpoint")
        self.log("skip", "pre-compact")
        self.save_state()

    def _append_usage(self) -> None:
        started = parse_iso(self.state.get("started_at", "")) or now()
        minutes = max(0, int((now() - started).total_seconds() / 60))
        row = {
            "date": f"{self.user_now():%Y-%m-%d}",
            "harness": self.harness,
            "start": self.state.get("started_at", ""),
            "end": iso(self.user_now()),
            "minutes": minutes,
            "turns": int(self.state.get("turns", 0)),
            "tools": int(self.state.get("tool_calls", 0)),
            "saved": bool(self.flags().get("save_done")),
        }
        try:
            self.state_dir.mkdir(parents=True, exist_ok=True)
            with (self.state_dir / "usage.jsonl").open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(row, ensure_ascii=True) + "\n")
        except OSError:
            pass
        self._recompute_timing()

    def _recompute_timing(self) -> None:
        path = self.state_dir / "usage.jsonl"
        rows = []
        try:
            for line in path.read_text(encoding="utf-8", errors="replace").splitlines()[-60:]:
                data = json.loads(line)
                if isinstance(data, dict):
                    rows.append(data)
        except (OSError, ValueError):
            return
        rows = rows[-30:]
        if len(rows) < 5:
            return
        ends = []
        lengths = []
        for row in rows:
            try:
                end = datetime.fromisoformat(row.get("end", ""))
                ends.append(end.hour * 60 + end.minute)
                lengths.append(max(10, int(row.get("minutes", 0))))
            except (TypeError, ValueError):
                continue
        if len(ends) < 5:
            return
        end_median = int(median(ends))
        len_median = int(median(lengths))
        late_minutes = (end_median - 15) % (24 * 60)
        hour, minute = late_minutes // 60, late_minutes % 60
        cadence = max(30, min(240, int(len_median * 0.8)))
        write_json(
            self.state_dir / "timing.json",
            {"late": f"{hour:02d}:{minute:02d}", "cadence_min": cadence, "samples": len(rows), "ts": iso(now())},
        )


# ---------------------------------------------------------------- output

def shape(harness: str, event: str, payload) -> dict:
    if not payload:
        return {}
    if harness == "claude":
        if event == "session-start":
            return {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": payload}}
        if event == "prompt":
            return {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": payload}}
        if event == "pre-tool":
            return {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": payload}}
        if event == "stop":
            if isinstance(payload, dict) and payload.get("suggest"):
                return {"hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": payload["suggest"]}}
            return {"decision": "block", "reason": payload}
    if harness == "gemini":
        if event == "session-start":
            return {"hookSpecificOutput": {"additionalContext": payload}}
        if event == "prompt":
            return {"hookSpecificOutput": {"additionalContext": payload}}
        if event == "pre-tool":
            return {"decision": "deny", "reason": payload}
        if event == "stop":
            if isinstance(payload, dict) and payload.get("suggest"):
                return {}
            return {"decision": "deny", "reason": payload}
    if harness == "codex":
        if event == "session-start":
            return {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": payload}}
        if event == "prompt":
            return {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": payload}}
        if event == "pre-tool":
            return {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": payload}}
        if event == "stop":
            if isinstance(payload, dict) and payload.get("suggest"):
                return {}
            return {"decision": "block", "reason": payload}
    if harness == "opencode":
        if event == "session-start":
            return {"context": payload}
        if event == "prompt":
            return {"prompt_context": payload}
        if event == "pre-tool":
            return {"block": True, "reason": payload}
        if event == "stop":
            if isinstance(payload, dict) and payload.get("suggest"):
                return {"suggest": payload["suggest"]}
            return {"continue_prompt": payload}
    return {}


def handle(ctx: Ctx):
    event = ctx.event_name
    if event == "session-start":
        brief = ctx.build_brief()
        ctx.save_state()
        if not brief:
            return {}
        ctx.log("inject", "boot-brief")
        return shape(ctx.harness, event, brief)
    if event == "prompt":
        text = ctx.route_prompt()
        ctx.save_state()
        if not text:
            return {}
        ctx.log("inject", "prompt-router")
        return shape(ctx.harness, event, text)
    if event == "pre-tool":
        reason = ctx.pre_tool()
        ctx.save_state()
        if not reason:
            return {}
        return shape(ctx.harness, event, reason)
    if event == "post-tool":
        ctx.post_tool()
        return {}
    if event == "stop":
        result = ctx.stop()
        if not result:
            return {}
        return shape(ctx.harness, event, result)
    if event == "session-end":
        ctx.session_end()
        return {}
    if event == "pre-compact":
        ctx.pre_compact()
        return {}
    if event == "idle-check":
        print(ctx.idle_check())
        return {}
    if event == "idle-save":
        ctx.idle_save()
        return {}
    if event == "idle-clear":
        ctx.idle_clear()
        return {}
    return {}


def doctor(root: Path) -> dict:
    checks = {}
    checks["root"] = str(root)
    checks["policy"] = (root / "tools" / "hooks" / "policy.json").exists()
    checks["fts"] = (root / "tools" / "fts.py").exists()
    try:
        (root / "logs" / ".state").mkdir(parents=True, exist_ok=True)
        probe = root / "logs" / ".state" / ".probe"
        probe.write_text("ok", encoding="utf-8")
        probe.unlink()
        checks["state_writable"] = True
    except OSError:
        checks["state_writable"] = False
    log = root / "logs" / "hooks.log"
    checks["log_lines"] = len(log.read_text(encoding="utf-8", errors="replace").splitlines()) if log.exists() else 0
    return checks


def parse_args(argv):
    harness = argv[1] if len(argv) > 1 else ""
    event = argv[2] if len(argv) > 2 else ""
    root = Path(__file__).resolve().parents[2]
    if "--root" in argv:
        index = argv.index("--root")
        if index + 1 < len(argv):
            root = Path(argv[index + 1]).expanduser().resolve()
    doctor_mode = "--doctor" in argv
    brief_mode = "--brief" in argv
    return harness, event, root, doctor_mode, brief_mode


def main() -> None:
    if os.environ.get("CV4_HOOKS") == "0":
        return
    harness, raw_event, root, doctor_mode, brief_mode = parse_args(sys.argv)
    if doctor_mode:
        print(json.dumps(doctor(root), ensure_ascii=True))
        return
    if brief_mode:
        ctx = Ctx(root, "claude", "session-start", {"session_id": "brief", "source": "startup"})
        text = ctx.build_brief()
        if text:
            print(text)
        return
    if harness not in HARNESSES:
        return
    event_name = EVENT_ALIASES.get(raw_event, raw_event)
    if not event_name:
        return
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except ValueError:
        return
    ctx = Ctx(root, harness, event_name, payload)
    if not ctx.policy.get("enabled", True):
        return
    if not ctx.shadow and str(ctx.policy.get("mode", "live")).lower() == "shadow":
        ctx.shadow = True
    output = handle(ctx)
    if output:
        print(json.dumps(output, ensure_ascii=True))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # noqa: BLE001 - the no-brick rule
        try:
            root = Path(__file__).resolve().parents[2]
            log_event(root, "dispatcher", "error", "error", type(exc).__name__, 0, "unknown")
        except Exception:
            pass
        sys.exit(0)
