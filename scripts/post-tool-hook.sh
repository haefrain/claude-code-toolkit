#!/usr/bin/env bash
# post-tool-hook.sh — PostToolUse hook para Edit/Write.
# Si el archivo editado tiene tests relacionados, recuerda correrlos.
# Input stdin JSON: { "tool_name": "Edit", "tool_input": { "file_path": "..." }, ... }
set -euo pipefail

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null || echo "")

# Solo actuar en Edit y Write
[[ "$tool" == "Edit" || "$tool" == "Write" ]] || exit 0

file=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
[[ -z "$file" ]] && exit 0

# Detectar si existe archivo de test relacionado
base=$(basename "$file" | sed 's/\.[^.]*$//')
dir=$(dirname "$file")

found_tests=""

# Patrones de test relacionados
for pat in \
  "${dir}/${base}.test.ts" \
  "${dir}/${base}.spec.ts" \
  "${dir}/${base}.test.tsx" \
  "${dir}/${base}.spec.tsx" \
  "${dir}/__tests__/${base}.test.ts" \
  "${dir}/__tests__/${base}.spec.ts" \
  "tests/${base}.test.ts" \
  "__tests__/${base}.test.ts"
do
  [[ -f "$pat" ]] && found_tests="$pat" && break
done

# También buscar por grep en archivos de test
if [[ -z "$found_tests" ]]; then
  found_tests=$(grep -rln "$base" \
    --include='*.test.ts' --include='*.spec.ts' \
    --include='*.test.tsx' --include='*.spec.tsx' \
    --include='*.test.js' --include='*.spec.js' \
    --exclude-dir=node_modules --exclude-dir=.git \
    . 2>/dev/null | head -1 || true)
fi

if [[ -n "$found_tests" ]]; then
  echo "<!-- post-tool-hook: tests detectados -->"
  echo ""
  echo "⚠️ **Tests relacionados encontrados:** \`$found_tests\`"
  echo "Corré \`/test-focus $file\` o \`~/.claude/scripts/test-focus.sh $file\` antes de continuar."
fi

exit 0
