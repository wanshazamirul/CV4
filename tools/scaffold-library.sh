#!/bin/bash
# Library scaffold: add any missing standard book (folder + README key) to library/.
# Never touches filled content: existing books, chapters, and READMEs are left exactly as they are.
# Usage: bash tools/scaffold-library.sh [--root DIR] [--quiet]
set -u

ROOT=""; QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift ;;
    --quiet) QUIET=1 ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "scaffold-library: unknown flag $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$ROOT/library"
TEMPLATE="$LIB/_template/README.md"
BOOKS="frontend backend security infra process ai design"
say() { [ "$QUIET" = 1 ] || echo "$@"; }

[ -d "$LIB" ] || { echo "scaffold-library: no library/ under $ROOT" >&2; exit 1; }

added=0
for b in $BOOKS; do
  if [ -f "$LIB/$b/README.md" ]; then continue; fi
  mkdir -p "$LIB/$b"
  if [ -f "$TEMPLATE" ]; then
    sed "s/<book>/$b/g" "$TEMPLATE" > "$LIB/$b/README.md"
  else
    printf '# %s - book\n\n**Status:** scaffold. See the shelf README (../README.md) for format and rules.\n' "$b" > "$LIB/$b/README.md"
  fi
  added=$((added+1))
done

say "scaffold-library: $added missing book(s) added · standard shelf: $BOOKS"
