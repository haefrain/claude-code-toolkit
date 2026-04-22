#!/usr/bin/env bash
# audit-pii.sh — busca patrones de PII en logs/errores sin sanitizar.
# Uso: audit-pii.sh [path]  (default: .)
set -euo pipefail
path="${1:-.}"

echo "## Audit PII — $path"
echo ""

patterns_log='console\.(log|error|warn|info)\s*\([^)]*(email|password|phone|document|cedula|dni|nombre|apellido|rut|cuil|address|card)'
patterns_logger='logger\.(info|error|warn|debug)\s*\([^)]*(email|password|phone|document|cedula|dni)'
patterns_err='throw\s+new\s+Error\s*\([^)]*(token|password|secret|api_key)'

hits=0
section() {
  local title="$1" pat="$2"
  echo "### $title"
  local out
  out=$(grep -rnE "$pat" "$path" \
    --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
    --include='*.py' --include='*.php' --include='*.dart' \
    --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=build \
    --exclude-dir=vendor --exclude-dir=.git 2>/dev/null | head -30 || true)
  if [[ -z "$out" ]]; then
    echo "(sin hits)"
  else
    echo "$out"
    hits=$((hits + $(echo "$out" | wc -l)))
  fi
  echo ""
}

section "console.* con PII" "$patterns_log"
section "logger.* con PII" "$patterns_logger"
section "Errores con secrets" "$patterns_err"

echo "---"
echo "Total hits: $hits"
[[ $hits -gt 0 ]] && echo "Revisar manualmente: los matches pueden ser falsos positivos (keys de traducción, etc.)"
