#!/usr/bin/env bash
# gdpr-quick-check.sh — triage express de compliance: PII + secrets + auth + prisma.
# Uso: gdpr-quick-check.sh [path]
set -euo pipefail
path="${1:-.}"
SCRIPTS_DIR="$(dirname "$0")"

echo "# GDPR / Compliance Quick Check"
echo "*Path:* $path"
echo "*Fecha:* $(date '+%Y-%m-%d %H:%M')"
echo ""

run_section() {
  local title="$1"
  local script="$2"
  shift 2
  echo "---"
  echo "## $title"
  if [[ -f "$SCRIPTS_DIR/$script" ]]; then
    bash "$SCRIPTS_DIR/$script" "$path" "$@" 2>/dev/null | grep -v '^#\|^$' | head -40
  else
    echo "(script $script no encontrado)"
  fi
  echo ""
}

run_section "PII en logs" "audit-pii.sh"
run_section "Secretos hardcoded" "audit-secrets.sh"
run_section "PII en Prisma sin cifrar" "pii-in-prisma.sh"
run_section "Endpoints sin auth" "auth-routes-audit.sh"
run_section "Endpoints sin rate limit" "rate-limit-audit.sh"

echo "---"
echo "## Resumen"
echo ""
echo "Para crear issues de los hallazgos: delegar al agente \`issue-manager\`."
echo "Prefijo de issues: [GDPR-CRIT-NNN], [GDPR-HIGH-NNN], [SEC-NNN] según severidad."
