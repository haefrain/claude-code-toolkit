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

# ── Marcador de verificación (Sección 01) ─────────────────────
# Si se editó código, registrarlo para que verify-stop.sh verifique al Stop.
sid=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null || echo "")
ext="${file##*.}"
case "$ext" in
  ts|tsx|js|jsx|mjs|cjs|vue|svelte|py|rb|php|go|rs|java|kt|swift|c|cpp|h|cs|sql|prisma|sh)
    if [[ -n "$sid" ]]; then
      tmp="${TMPDIR:-/tmp}"; tmp="${tmp%/}"
      marker="$tmp/claude-verify-pending-$sid"
      { grep -qxF -- "$file" "$marker" 2>/dev/null || echo "$file" >> "$marker"; } 2>/dev/null || true
    fi
    ;;
esac

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
