#!/usr/bin/env bash
# search-docs.sh — busca un término solo en archivos de documentación.
# Uso: search-docs.sh <término> [path]
set -euo pipefail
term="${1:-}"
path="${2:-.}"
[[ -z "$term" ]] && { echo "uso: search-docs.sh <término> [path]" >&2; exit 1; }
cd "$path"

echo "## Search Docs — \"$term\""
echo ""

echo "### En docs/ y *.md"
grep -rn -i --include='*.md' --include='*.mdx' --include='*.txt' \
  --exclude-dir=node_modules --exclude-dir=.git \
  -E "$term" . 2>/dev/null | head -30 || echo "(sin resultados)"
echo ""

echo "### En comentarios de código (JSDoc / docstrings)"
grep -rn -i \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.py' --include='*.php' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=.git \
  -E "(/\*\*|#|//|'''|\"\"\").*$term" . 2>/dev/null | head -15 || echo "(sin resultados)"
echo ""

echo "### Archivos .md disponibles (índice)"
find . -name '*.md' -o -name '*.mdx' 2>/dev/null \
  | grep -v node_modules | grep -v '.git' | sort | head -30 | sed 's|^\./||'
