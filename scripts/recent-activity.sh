#!/usr/bin/env bash
# recent-activity.sh — archivos modificados recientemente + quién los tocó.
# Uso: recent-activity.sh [days=7] [path]
set -euo pipefail
days="${1:-7}"
path="${2:-.}"
cd "$path"

echo "## Recent Activity — últimos ${days} días"
echo ""

echo "### Commits"
git log --since="${days} days ago" --format="%h %ad %an — %s" --date=short 2>/dev/null | head -20 || echo "(sin commits)"
echo ""

echo "### Archivos más tocados (últimos ${days} días)"
git log --since="${days} days ago" --pretty=format: --name-only 2>/dev/null \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -20 \
  | awk '{printf "%3d\t%s\n", $1, $2}' || echo "(ninguno)"
echo ""

echo "### Archivos modificados en disco (mtime)"
find . -maxdepth 4 -type f -newer <(date -d "${days} days ago" +%Y%m%d 2>/dev/null || date -v-${days}d +%Y%m%d 2>/dev/null || echo "19700101") \
  -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.next/*' \
  -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/vendor/*' \
  2>/dev/null | head -30 | sed 's|^\./||'
