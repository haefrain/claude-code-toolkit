#!/usr/bin/env bash
# find-usages.sh — callers, imports y tests de un símbolo. Complementa verify-root-cause.
# Uso: find-usages.sh <símbolo> [path]
set -euo pipefail
symbol="${1:-}"
path="${2:-.}"
[[ -z "$symbol" ]] && { echo "uso: find-usages.sh <símbolo> [path]" >&2; exit 1; }
cd "$path"

echo "## Find Usages — \`$symbol\`"
echo ""

exts='--include=*.ts --include=*.tsx --include=*.js --include=*.jsx --include=*.py --include=*.php --include=*.dart'
exclude='--exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=build --exclude-dir=vendor --exclude-dir=.git'

section() {
  local title="$1" pat="$2"
  echo "### $title"
  out=$(grep -rn $exts $exclude -E "$pat" . 2>/dev/null | head -20 || true)
  [[ -z "$out" ]] && echo "(ninguno)" || echo "$out"
  echo ""
}

section "Llamadas directas" "${symbol}\s*\("
section "Imports" "(import|require).*['\"].*${symbol}|import\s+.*${symbol}"
section "Exports" "export\s+(const|function|class|default|type|interface)\s+${symbol}"
section "Definición" "(function|const|class|type|interface|def|fn)\s+${symbol}[\s(<]"
section "Tests" "${symbol}"  # en archivos de test

echo "### Archivos de test que mencionan el símbolo"
grep -rn $exclude -E "${symbol}" \
  --include='*.test.ts' --include='*.spec.ts' --include='*.test.tsx' --include='*.spec.tsx' \
  --include='*.test.js' --include='*.spec.js' --include='*_test.py' --include='*_test.dart' \
  . 2>/dev/null | head -15 || echo "(ninguno)"
