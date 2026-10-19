#!/bin/bash
# Skills engine: wire the skill packs into each harness's native discovery path,
# and refresh the skills router block (G0 + trigger table) in repo agent files that carry its markers.
#
# Works in both repos: CV3 (bank = plugins/cv3-skills/skills) and CV4 (bank = skills/).
# Personal zone (my-skills/) is wired too and wins name overlaps.
#
# Project targets always wire. --global also wires the harness's global skill folder
# (~/.config/opencode/skills, ~/.claude/skills, ~/.agents/skills), but only where that
# harness actually exists on the machine. CV4 boots with --global so its rituals (save,
# recall, reminders) resolve from any folder, not just inside Home.
#
# Usage: bash tools/install-skills.sh [--root DIR] [--check] [--copy] [--global] [--quiet]
#   --check   report wiring status only; change nothing
#   --copy    copy instead of symlink (filesystems without symlinks, e.g. Windows without dev mode)
#   --global  also wire the global per-harness skill folders
#   --quiet   one-line summary
set -u

ROOT=""; CHECK=0; COPY=0; QUIET=0; GLOBAL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift ;;
    --check) CHECK=1 ;;
    --copy) COPY=1 ;;
    --global) GLOBAL=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "install-skills: unknown flag $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -d "$ROOT" ] || { echo "install-skills: root not found: $ROOT" >&2; exit 1; }

BANK=""
[ -d "$ROOT/skills" ] && BANK="$ROOT/skills"
[ -d "$ROOT/plugins/cv3-skills/skills" ] && BANK="$ROOT/plugins/cv3-skills/skills"
[ -n "$BANK" ] || { echo "install-skills: no skill bank under $ROOT (expected skills/ or plugins/cv3-skills/skills)" >&2; exit 1; }
PERSONAL=""; [ -d "$ROOT/my-skills" ] && PERSONAL="$ROOT/my-skills"

# Project-local targets (relative to ROOT; relative symlinks).
TARGETS=".opencode/skills .claude/skills .agents/skills"

# Global targets: absolute, and only where that harness already lives on this machine.
global_targets() {
  [ "$GLOBAL" = 1 ] || return 0
  [ -d "$HOME/.config/opencode" ] && printf '%s\n' "$HOME/.config/opencode/skills"
  [ -d "$HOME/.claude" ] && printf '%s\n' "$HOME/.claude/skills"
  [ -d "$HOME/.agents" ] && printf '%s\n' "$HOME/.agents/skills"
  return 0
}

say() { [ "$QUIET" = 1 ] || echo "$@"; }
count() { printf '%s' "$1" | grep -c '[^[:space:]]'; }

# ---- collect names (personal wins; bank skips any name personal owns) --------
personal_names=""
[ -n "$PERSONAL" ] && personal_names="$(ls -1 "$PERSONAL" 2>/dev/null | while read -r n; do [ -f "$PERSONAL/$n/SKILL.md" ] && echo "$n"; done)"
bank_names=""
for d in "$BANK"/*/; do
  [ -f "${d}SKILL.md" ] || continue
  n="$(basename "$d")"
  printf '%s\n' "$personal_names" | grep -qx "$n" && continue
  bank_names="$bank_names$n
"
done
# real (non-symlink) dirs already living in the opencode target: CV3's dedicated zone
real_names=""
for d in "$ROOT/.opencode/skills"/*/; do
  [ -d "$d" ] || continue
  [ -L "${d%/}" ] && continue
  n="$(basename "$d")"
  printf '%s\n' "$personal_names" | grep -qx "$n" && continue
  printf '%s\n' "$bank_names" | grep -qx "$n" && continue
  [ -f "$ROOT/.opencode/skills/$n/SKILL.md" ] || continue
  real_names="$real_names$n
"
done

# A wired copy we own carries .cv4-wired (written by the copy fallback). Refreshed on
# every run; a real folder without the marker is the user's and is never touched.
WIRE_MARK=".cv4-wired"

wire_name() { # wire_name <src_dir> <name> <target_abs_dir> <absolute_symlink 0|1>
  src="$1"; n="$2"; tdir="$3"; abs="${4:-0}"
  dest="$tdir/$n"
  if [ "$CHECK" = 1 ]; then
    if [ -L "$dest" ]; then say "ok       $tdir/$n -> $(readlink "$dest")"
    elif [ -f "$dest/$WIRE_MARK" ]; then say "ok       $tdir/$n (wired copy)"
    elif [ -d "$dest" ]; then say "present  $tdir/$n (real dir, left alone)"
    else say "missing  $tdir/$n"; fi
    return 0
  fi
  mkdir -p "$tdir"
  if [ -L "$dest" ]; then
    rm -f "$dest"                                   # ours: refresh the link
  elif [ -d "$dest" ]; then
    if [ -f "$dest/$WIRE_MARK" ]; then
      rm -rf "$dest"                                # ours: refresh the copy
    elif [ -f "$dest/SKILL.md" ] && cmp -s "$src/SKILL.md" "$dest/SKILL.md"; then
      rm -rf "$dest"                                # an unmarked copy of ours (hand-copied install): adopt it
    else
      return 0                                      # the user's own folder: never clobber
    fi
  elif [ -e "$dest" ]; then
    return 0
  fi
  if [ "$COPY" = 1 ]; then
    cp -R "$src" "$dest" && : > "$dest/$WIRE_MARK"
    return 0
  fi
  if [ "$abs" = 1 ]; then
    ln -sfn "$src" "$dest" 2>/dev/null
  else
    rel="$(realpath --relative-to="$tdir" "$src" 2>/dev/null || printf '%s' "$src")"
    ln -sfn "$rel" "$dest" 2>/dev/null
  fi
  # ln -s on Git Bash may "succeed" by copying; only a real symlink counts.
  [ -L "$dest" ] || { rm -rf "$dest"; cp -R "$src" "$dest" && : > "$dest/$WIRE_MARK"; }
}

for t in $TARGETS; do
  for n in $personal_names; do [ -n "$n" ] && wire_name "$PERSONAL/$n" "$n" "$ROOT/$t" 0; done
  for n in $bank_names; do [ -n "$n" ] && wire_name "$BANK/$n" "$n" "$ROOT/$t" 0; done
  if [ "$t" != ".opencode/skills" ]; then
    for n in $real_names; do [ -n "$n" ] && wire_name "$ROOT/.opencode/skills/$n" "$n" "$ROOT/$t" 0; done
  fi
done

GTARGETS="$(global_targets)"
for t in $GTARGETS; do
  for n in $personal_names; do [ -n "$n" ] && wire_name "$PERSONAL/$n" "$n" "$t" 1; done
  for n in $bank_names; do [ -n "$n" ] && wire_name "$BANK/$n" "$n" "$t" 1; done
  for n in $real_names; do [ -n "$n" ] && wire_name "$ROOT/.opencode/skills/$n" "$n" "$t" 1; done
done

# ---- router stamp: G0 + trigger table between SKILLS-ROUTER markers ----------
desc_of() {
  awk '
    /^description:/ {
      line=$0; sub(/^description:[ \t]*/, "", line)
      if (line != "" && line != ">" && line != "|" && line != ">-" && line != "|-") { print line; exit }
      while ((getline l) > 0) {
        if (l ~ /^[ \t]+/) { gsub(/^[ \t]+/, "", l); printf "%s ", l } else break
      }
      exit
    }
  ' "$1" | sed 's/^"//; s/"$//' | cut -c1-110
}

apply_router() { # $1 = file, $2 = block file
  awk -v block="$(cat "$2")" '
    /SKILLS-ROUTER:BEGIN/ { print block; skip=1; next }
    /SKILLS-ROUTER:END/ { skip=0; next }
    !skip { print }
  ' "$1" > "$1.new" && mv "$1.new" "$1"
}

stamp_router() {
  targets="$(agent_files)"
  if [ -z "$targets" ]; then
    if [ "$CHECK" = 1 ]; then say "router   nothing to stamp (0 files with markers)"; else say "router   skipped (no agent files present)"; fi
    return 0
  fi
  TMP="$(mktemp)"
  {
    echo '<!-- SKILLS-ROUTER:BEGIN (generated by tools/install-skills.sh; do not edit inside) -->'
    echo '**G0 - no blind action**: freedom words ("you cook", "full send", "just do it", "surprise me") expand WHAT may be built, never WHICH gates run. Any of them activates the full gate path: recon -> spec where required -> preflight -> verify -> report.'
    echo
    echo '| skill | trigger |'
    echo '|---|---|'
    for n in $personal_names $bank_names $real_names; do
      [ -n "$n" ] || continue
      for base in "$PERSONAL" "$ROOT/.opencode/skills" "$BANK"; do
        [ -n "$base" ] && [ -f "$base/$n/SKILL.md" ] && { echo "| $n | $(desc_of "$base/$n/SKILL.md") |"; break; }
      done
    done
    echo '<!-- SKILLS-ROUTER:END -->'
  } > "$TMP"
  if [ "$CHECK" = 1 ]; then
    stale=0; n=0
    for AG in $targets; do
      base_n="$(basename "$AG")"
      if ! grep -q 'SKILLS-ROUTER:BEGIN' "$AG"; then say "router   plain $base_n (no markers; left alone)"
      else
        n=$((n+1))
        cp "$AG" "$TMP.ag"
        apply_router "$TMP.ag" "$TMP"
        if cmp -s "$AG" "$TMP.ag"; then :; else say "router   differs in $base_n (re-run without --check)"; stale=1; fi
        rm -f "$TMP.ag"
      fi
    done
    [ "$stale" = 0 ] && say "router   up to date ($n file(s))"
    rm -f "$TMP"; return 0
  fi
  for AG in $targets; do
    base_n="$(basename "$AG")"
    if grep -q 'SKILLS-ROUTER:BEGIN' "$AG"; then
      apply_router "$AG" "$TMP"; say "router   updated in $base_n"
    else
      say "router   plain $base_n (no markers; left alone)"
    fi
  done
  rm -f "$TMP"
}

is_pointer() { # $1 = file; true when it is a one-line @-import (older pointer setups)
  [ "$(grep -c '' "$1" 2>/dev/null)" = 1 ] && grep -Eq '^@[A-Za-z0-9_./-]+\.md[[:space:]]*$' "$1"
}

agent_files() { # present agent files that carry the manual (bare pointers never qualify)
  for f in "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$ROOT/GEMINI.md"; do
    [ -f "$f" ] || continue
    is_pointer "$f" && continue
    printf '%s\n' "$f"
  done
}

if [ "$CHECK" = 1 ]; then
  say "install-skills --check: root=$ROOT  bank=$(count "$bank_names")  personal=$(count "$personal_names")  dedicated=$(count "$real_names")  global=$([ "$GLOBAL" = 1 ] && echo yes || echo no)"
  stamp_router
  exit 0
fi

say "install-skills: wired $(count "$bank_names") bank + $(count "$personal_names") personal + $(count "$real_names") dedicated skill(s)"
say "    targets: $TARGETS   mode: $([ "$COPY" = 1 ] && echo copy || echo symlink-first)"
[ -n "$GTARGETS" ] && say "    global:  $GTARGETS"
stamp_router
