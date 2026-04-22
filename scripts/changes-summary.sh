#!/usr/bin/env bash
# changes-summary.sh — resumen compacto de git status + diff --stat + últimos commits.
# Uso: changes-summary.sh [path]
set -euo pipefail
path="${1:-.}"
cd "$path"

echo "## Changes Summary — $(basename "$(pwd)")"
echo ""

echo "### Status"
git status --short 2>/dev/null || echo "(no es repo git)"
echo ""

echo "### Diff stat (staged + unstaged)"
git diff --stat HEAD 2>/dev/null | tail -5 || echo "(sin cambios)"
echo ""

echo "### Últimos 10 commits"
git log --oneline -10 2>/dev/null || echo "(sin commits)"
echo ""

echo "### Archivos staged"
git diff --cached --name-status 2>/dev/null | head -20 || echo "(ninguno)"
echo ""

echo "### Archivos unstaged"
git diff --name-status 2>/dev/null | head -20 || echo "(ninguno)"
