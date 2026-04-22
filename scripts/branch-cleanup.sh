#!/usr/bin/env bash
# branch-cleanup.sh — detecta ramas locales ya mergeadas en main/master/develop.
# Uso: branch-cleanup.sh [base-branch] [path]
set -euo pipefail
path="${2:-.}"
cd "$path"

base="${1:-}"
if [[ -z "$base" ]]; then
  base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||' || echo "main")
fi

echo "## Branch Cleanup — base: $base"
echo ""

current=$(git rev-parse --abbrev-ref HEAD)
echo "Rama actual: $current"
echo ""

echo "### Ramas locales ya mergeadas en $base"
merged=$(git branch --merged "$base" 2>/dev/null | grep -vE "^\*|^  $base$|^  main$|^  master$|^  develop$" | sed 's/^\s*//')
if [[ -z "$merged" ]]; then
  echo "(ninguna — todo limpio)"
else
  echo "$merged" | sed 's/^/- /'
  echo ""
  echo "Para borrarlas: \`git branch -d $(echo "$merged" | tr '\n' ' ')\`"
fi
echo ""

echo "### Ramas locales NO mergeadas (revisar antes de borrar)"
git branch --no-merged "$base" 2>/dev/null | grep -v "^\*" | sed 's/^\s*/- /' | head -20
echo ""

echo "### Ramas remotas stale (sin actividad reciente en origin)"
git branch -r --merged "origin/$base" 2>/dev/null \
  | grep -vE 'origin/(HEAD|main|master|develop)' \
  | sed 's|^\s*origin/|- |' | head -20 || echo "(ninguna)"
