#!/bin/bash
# Self-test: prove this instance's engine, end to end.
# Read-only on the live repo; the integration pass runs in a scratch copy.
# Usage: bash tools/self-test.sh [--root DIR] [--quick] [--quiet] [--canonical]
#   --quick      layout + engine checks only (skip the scratch integration pass)
#   --quiet      print only findings and the result
#   --canonical  release gate: fail if the template's personal zones are filled
# Exit: 0 = PASS, 1 = FAIL
set -u

ROOT=""; QUICK=0; QUIET=0; CANONICAL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift ;;
    --quick) QUICK=1 ;;
    --quiet) QUIET=1 ;;
    --canonical) CANONICAL=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "self-test: unknown flag $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

passes=0; fails=0
ok()   { passes=$((passes+1)); [ "$QUIET" = 1 ] || echo "  ok    $1"; }
info() { [ "$QUIET" = 1 ] || echo "  info  $1"; }
fail() { fails=$((fails+1)); echo "  FAIL  $1"; }
have() { command -v "$1" >/dev/null 2>&1; }
md5of() { # portable content hash: GNU md5sum, else BSD md5
  if command -v md5sum >/dev/null 2>&1; then md5sum "$1" 2>/dev/null | cut -d' ' -f1
  else md5 -q "$1" 2>/dev/null; fi
}

echo "== self-test: $ROOT =="

# --- 1. layout: every browsing folder carries a README key -------------------
missing_rd=0
for d in "$ROOT"/*/; do
  b="$(basename "$d")"
  case "$b" in
    .claude-plugin) ;;                     # a browsing folder despite the dot
    .*|node_modules) continue ;;
  esac
  [ -f "$d/README.md" ] || { fail "missing README: $b/"; missing_rd=1; }
done
[ "$missing_rd" = 0 ] && ok "every top-level folder carries a README key"
if [ -d "$ROOT/library" ]; then
  missing_book=0
  for d in "$ROOT"/library/*/; do
    [ -f "$d/README.md" ] || { fail "missing book README: library/$(basename "$d")/"; missing_book=1; }
  done
  [ "$missing_book" = 0 ] && ok "every library book carries a README key"
fi
if [ -d "$ROOT/commands" ]; then
  [ -f "$ROOT/commands/remove-cv4.md" ] && ok "remove-cv4 command template present" || fail "commands/remove-cv4.md missing"
fi
[ -f "$ROOT/LICENSE" ] && ok "license present" || fail "LICENSE missing"

# --- 1b. canonical release gate: personal zones stay empty ------------------
if [ "$CANONICAL" = 1 ] && [ -f "$ROOT/tools/check-personal.sh" ]; then
  if bash "$ROOT/tools/check-personal.sh" --root "$ROOT" --quiet >/dev/null 2>&1; then
    ok "canonical personal zones clean"
  else
    fail "canonical personal zones are filled (keep instance memory off main)"
  fi
fi

# --- 2. skills engine: router current, wiring complete -----------------------
if [ -f "$ROOT/tools/install-skills.sh" ]; then
  if [ -f "$ROOT/AGENTS.md" ] || [ -f "$ROOT/CLAUDE.md" ] || [ -f "$ROOT/GEMINI.md" ]; then
    out="$(bash "$ROOT/tools/install-skills.sh" --check 2>&1)"
    case "$out" in
      *"router   differs"*) fail "router block stale (markers present; run: bash tools/install-skills.sh)" ;;
      *"router   up to date"*|*"router   nothing to stamp"*) ok "router state clean (marker files refreshed; plain files left alone)" ;;
      *) fail "router check unexpected output" ;;
    esac
    if [ -d "$ROOT/.opencode/skills" ]; then
      miss="$(printf '%s\n' "$out" | grep -c '^missing' || true)"
      [ "$miss" = 0 ] && ok "skills wired in every target" || fail "$miss skill(s) not wired (run: bash tools/install-skills.sh)"
    else
      info "skills not wired yet (run: bash tools/install-skills.sh)"
    fi
  else
    info "no agent file yet (fresh clone: run BOOT first)"
  fi
fi

# --- 3. registries: rows and folders agree ----------------------------------
if [ -f "$ROOT/skills/registry.md" ]; then
  rows="$(awk -F'|' '/^\|/ {gsub(/ /,"",$2); if ($2!="skill" && $2 !~ /^-+$/ && $2!="") print $2}' "$ROOT/skills/registry.md")"
  bad=0
  for n in $rows; do [ -d "$ROOT/skills/$n" ] || { fail "registry row '$n' has no folder"; bad=1; }; done
  for d in "$ROOT"/skills/*/; do b="$(basename "$d")"; printf '%s\n' "$rows" | grep -qx "$b" || { fail "skill '$b' has no registry row"; bad=1; }; done
  [ "$bad" = 0 ] && ok "bank registry matches folders"
fi

# --- 4. the search indexer is present ---------------------------------------
if [ -f "$ROOT/tools/fts.py" ] || [ -f "$ROOT/tools/memory/fts.py" ]; then ok "search indexer present"; else fail "fts.py missing"; fi

# --- 4b. session load serves the manual's files (when shipped) ---------------
if [ -f "$ROOT/tools/session-load.sh" ]; then
  out="$(bash "$ROOT/tools/session-load.sh" --no-update 2>&1 || true)"
  n="$(printf '%s\n' "$out" | grep -c '^===== ' || true)"
  [ "$n" -ge 6 ] && ok "session-load serves $n files" || fail "session-load served only $n file(s)"
fi

# --- 5. spec-kit hook syntax (when shipped) ----------------------------------
if [ -f "$ROOT/spec-kit/converge-to-memory.sh" ]; then
  bash -n "$ROOT/spec-kit/converge-to-memory.sh" && ok "converge hook syntax ok" || fail "converge hook syntax error"
fi
if [ -f "$ROOT/tools/trust-home.sh" ]; then
  bash -n "$ROOT/tools/trust-home.sh" && ok "trust-home syntax ok" || fail "trust-home syntax error"
fi
if [ -f "$ROOT/tools/repair.sh" ]; then
  bash -n "$ROOT/tools/repair.sh" && ok "repair syntax ok" || fail "repair syntax error"
fi
if [ -f "$ROOT/tools/check-personal.sh" ]; then
  bash -n "$ROOT/tools/check-personal.sh" && ok "check-personal syntax ok" || fail "check-personal syntax error"
fi
if [ -f "$ROOT/tools/hooks/dispatch.sh" ]; then
  bash -n "$ROOT/tools/hooks/dispatch.sh" && ok "hook dispatcher syntax ok" || fail "hook dispatcher syntax error"
fi
if [ -f "$ROOT/tools/hooks/install.sh" ]; then
  bash -n "$ROOT/tools/hooks/install.sh" && ok "hook installer syntax ok" || fail "hook installer syntax error"
fi
if [ -f "$ROOT/tools/hooks/doctor.sh" ]; then
  bash -n "$ROOT/tools/hooks/doctor.sh" && ok "hook doctor syntax ok" || fail "hook doctor syntax error"
fi
if [ -f "$ROOT/tools/hooks/test.sh" ]; then
  bash -n "$ROOT/tools/hooks/test.sh" && ok "hook test syntax ok" || fail "hook test syntax error"
  if bash "$ROOT/tools/hooks/test.sh" --quiet >/dev/null 2>&1; then
    ok "hook fixtures pass"
  else
    fail "hook fixtures failed (run: bash tools/hooks/test.sh)"
  fi
fi

# --- 6. integration pass in a scratch copy ----------------------------------
if [ "$QUICK" = 0 ]; then
  SB="$(mktemp -d "${TMPDIR:-/tmp}/cv-selftest.XXXXXX" 2>/dev/null)" || SB=""
  if [ -z "$SB" ]; then
    fail "cannot create scratch dir (set TMPDIR)"
  else
    mkdir -p "$SB/repo" && cp -a "$ROOT/." "$SB/repo/" 2>/dev/null
    SCR="$SB/repo"
    rm -rf "$SCR/.git" "$SCR/node_modules"

    # stub manual if this clone never booted
    if [ ! -f "$SCR/AGENTS.md" ] && [ -f "$SCR/BOOT.md" ]; then
      printf '# AGENTS.md: how I operate\n\n<!-- SKILLS-ROUTER:BEGIN (generated by tools/install-skills.sh; do not edit inside) -->\n<!-- SKILLS-ROUTER:END -->\n' > "$SCR/AGENTS.md"
    fi

    if [ -f "$SCR/tools/install-skills.sh" ] && [ -f "$SCR/AGENTS.md" ]; then
      pz1="$(md5of "$SCR/main/soul.md")"
      bash "$SCR/tools/install-skills.sh" --quiet >/dev/null 2>&1
      md1="$(md5of "$SCR/AGENTS.md")"
      bash "$SCR/tools/install-skills.sh" --quiet >/dev/null 2>&1
      md2="$(md5of "$SCR/AGENTS.md")"
      pz2="$(md5of "$SCR/main/soul.md")"
      [ "$md1" = "$md2" ] && ok "installer idempotent (router byte-stable)" || fail "installer not idempotent"
      wired="$(ls "$SCR/.opencode/skills" 2>/dev/null | wc -l)"
      [ "$wired" -gt 0 ] && ok "wired $wired skills in the scratch" || fail "no skills wired in the scratch"
      grep -q "G0" "$SCR/AGENTS.md" && ok "G0 present in the router" || fail "G0 missing from the router"
      cp "$SCR/AGENTS.md" "$SCR/CLAUDE.md"
      out2="$(bash "$SCR/tools/install-skills.sh" --check 2>&1)"
      case "$out2" in
        *"up to date (2 file(s))"*) ok "router spans every agent file present" ;;
        *) fail "router check missed a present agent file: $out2" ;;
      esac
      printf '@AGENTS.md\n' > "$SCR/GEMINI.md"
      out3="$(bash "$SCR/tools/install-skills.sh" --check 2>&1)"
      case "$out3" in
        *"up to date (2 file(s))"*) ok "bare pointer files stay untouched" ;;
        *) fail "pointer file disturbed the router check: $out3" ;;
      esac
      printf '# plain notes\nno markers here\n' > "$SCR/GEMINI.md"
      before="$(md5of "$SCR/GEMINI.md")"
      out4="$(bash "$SCR/tools/install-skills.sh" 2>&1 || true)"
      after="$(md5of "$SCR/GEMINI.md")"
      case "$out4" in
        *"plain GEMINI.md"*)
          [ "$before" = "$after" ] && ok "marker-less agent files stay untouched" || fail "installer grew a marker-less file" ;;
        *) fail "installer did not report the plain-file skip: $out4" ;;
      esac
      [ "$pz1" = "$pz2" ] && ok "personal zones untouched by the engine" || fail "engine touched a personal zone"

      # --global: wires the harness folders that exist, refreshes what it owns, leaves real dirs
      GH="$SB/fakehome"; mkdir -p "$GH/.claude" "$GH/.config/opencode"
      outg="$(HOME="$GH" bash "$SCR/tools/install-skills.sh" --global --quiet 2>&1 || true)"
      nglob="$(ls "$GH/.claude/skills" 2>/dev/null | wc -l)"
      [ "$nglob" -gt 0 ] && ok "global wiring fills ~/.claude/skills ($nglob)" || fail "global wiring wrote nothing to ~/.claude/skills"
      [ -d "$GH/.agents/skills" ] && fail "global wiring created a harness folder that did not exist" || ok "global wiring skips harnesses not installed"
      if [ -e "$GH/.claude/skills/save" ]; then
        if [ -L "$GH/.claude/skills/save" ]; then
          ok "global copy is a symlink into Home"
        else
          [ -f "$GH/.claude/skills/save/.cv4-wired" ] && ok "global copy is marked for refresh" || fail "global copy has no owner marker"
        fi
        printf 'mine\n' > "$GH/.claude/skills/mine.md" 2>/dev/null || true
        mkdir -p "$GH/.claude/skills/user-own"; printf 'x\n' > "$GH/.claude/skills/user-own/SKILL.md"
        HOME="$GH" bash "$SCR/tools/install-skills.sh" --global --quiet >/dev/null 2>&1 || true
        [ -f "$GH/.claude/skills/user-own/SKILL.md" ] && ok "re-wire leaves the user's own skill folder alone" || fail "re-wire deleted a user skill folder"
        # unmarked hand-copied install (the work-pc case): adopted and refreshed, not left stale
        GH2="$SB/fakehome2"; mkdir -p "$GH2/.claude/skills/save"
        cp "$SCR/skills/save/SKILL.md" "$GH2/.claude/skills/save/SKILL.md"
        printf 'stale extra\n' > "$GH2/.claude/skills/save/extra.txt"
        HOME="$GH2" bash "$SCR/tools/install-skills.sh" --global --quiet >/dev/null 2>&1 || true
        { [ -L "$GH2/.claude/skills/save" ] || [ -f "$GH2/.claude/skills/save/.cv4-wired" ]; } && ok "unmarked copy of ours is adopted and re-wired" || fail "hand-copied skill was left stale"
        [ -f "$GH2/.claude/skills/save/extra.txt" ] && fail "adopted copy kept stale extra files" || ok "adopted copy is clean"
        GH3="$SB/fakehome3"; mkdir -p "$GH3/.claude/skills/save"
        printf 'my own variant\n' > "$GH3/.claude/skills/save/SKILL.md"
        HOME="$GH3" bash "$SCR/tools/install-skills.sh" --global --quiet >/dev/null 2>&1 || true
        grep -q "my own variant" "$GH3/.claude/skills/save/SKILL.md" && ok "edited copy of ours is respected, never clobbered" || fail "installer clobbered an edited user skill"
      fi
    fi

    # scaffold restores a missing book key
    if [ -f "$SCR/tools/scaffold-library.sh" ] && [ -d "$SCR/library" ]; then
      bash "$SCR/tools/scaffold-library.sh" --quiet >/dev/null 2>&1
      book=""
      for d in "$SCR"/library/*/; do
        b="$(basename "$d")"
        case "$b" in _*) ;; *) book="$b"; break ;; esac
      done
      if [ -n "$book" ]; then
        rm -rf "$SCR/library/$book"
        bash "$SCR/tools/scaffold-library.sh" --quiet >/dev/null 2>&1
        [ -f "$SCR/library/$book/README.md" ] && ok "scaffold restores a missing book key" || fail "scaffold did not restore $book"
      fi
    fi

    # converge hook: records once, then no-ops
    if [ -f "$SCR/spec-kit/converge-to-memory.sh" ] && [ -f "$SCR/memory/decisions.md" ]; then
      bash "$SCR/spec-kit/converge-to-memory.sh" "self-test: probe" >/dev/null 2>&1
      bash "$SCR/spec-kit/converge-to-memory.sh" "self-test: probe" >/dev/null 2>&1
      n="$(grep -c "self-test: probe" "$SCR/memory/decisions.md" 2>/dev/null || true)"
      [ "$n" = 1 ] && ok "converge hook records once (idempotent)" || fail "converge hook recorded $n time(s), expected 1"
      grep -v "self-test: probe" "$SCR/memory/decisions.md" > "$SCR/memory/decisions.md.tmp" 2>/dev/null && mv "$SCR/memory/decisions.md.tmp" "$SCR/memory/decisions.md"
    fi

    # repair: heals install-state gaps from earlier releases, idempotently
    if [ -f "$SCR/tools/repair.sh" ]; then
      rm -rf "$SCR/logs/current"
      printf 'legacy note\n' > "$SCR/logs/.pending-update"
      : > "$SCR/logs/pending-update.tmp"
      if grep -qx '\*\.tmp' "$SCR/.gitignore" 2>/dev/null; then
        grep -v '^\*\.tmp$' "$SCR/.gitignore" > "$SCR/.gitignore.tmpx" && mv "$SCR/.gitignore.tmpx" "$SCR/.gitignore"
      fi
      mkdir -p "$SB/rhome/.claude"
      HOME="$SB/rhome" bash "$SCR/tools/repair.sh" --quiet >/dev/null 2>&1
      [ -d "$SCR/logs/current" ] && ok "repair restores logs/current" || fail "repair did not restore logs/current"
      [ -f "$SCR/logs/.pending-update" ] && fail "repair left the legacy pending note" || ok "repair cleared the legacy pending note"
      grep -qx '\*\.tmp' "$SCR/.gitignore" && ok "repair restores the *.tmp ignore rule" || fail "repair did not restore *.tmp"
      [ -s "$SCR/logs/pending-update.tmp" ] && ok "repair folds the legacy note into the pending file" || fail "repair dropped the legacy note content"
    fi

    # git-guard: member blocked on engine paths, personal passes
    if [ -f "$SCR/tools/git-guard.sh" ] && have git; then
      cd "$SCR" || true
      git init -q 2>/dev/null
      git config user.email "selftest@local"; git config user.name "selftest"
      git add -A >/dev/null 2>&1; git commit -qm init >/dev/null 2>&1
      git branch -M main >/dev/null 2>&1
      git init -q --bare "$SB/origin"
      git remote add origin "$SB/origin" >/dev/null 2>&1
      bash tools/git-guard.sh --install >/dev/null 2>&1
      mkdir -p personas; printf 'role=member\n' > personas/.machine
      if git push -q origin main >/dev/null 2>&1; then
        ok "guard: initial push allowed"
        echo probe > tools/selftest-probe
        git add tools/selftest-probe >/dev/null 2>&1; git commit -qm "engine probe" >/dev/null 2>&1
        out2="$(git push origin main 2>&1 || true)"
        case "$out2" in
          *BLOCKED*) ok "guard blocks member engine pushes" ;;
          *) fail "guard did not block a member engine push" ;;
        esac
        printf 'role=personal\n' > personas/.machine
        out3="$(git push origin main 2>&1 || true)"
        case "$out3" in
          *BLOCKED*) fail "guard blocked the personal machine" ;;
          *) ok "guard allows personal machines" ;;
        esac
      else
        fail "guard blocked the initial push"
      fi
      cd "$ROOT" >/dev/null 2>&1 || cd / >/dev/null 2>&1 || true
    fi

    rm -rf "$SB"
  fi
fi

echo
if [ "$fails" = 0 ]; then
  echo "RESULT: PASS ($passes checks)"
  exit 0
else
  echo "RESULT: FAIL ($fails finding(s), $passes passed)"
  exit 1
fi
