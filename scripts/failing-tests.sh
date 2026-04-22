#!/usr/bin/env bash
# failing-tests.sh — extrae solo los tests fallidos del último run de CI.
# Uso: failing-tests.sh [run-id] [owner/repo]
set -euo pipefail
run_id="${1:-}"
repo="${2:-}"
if [[ -z "$repo" ]]; then
  remote=$(git remote get-url origin 2>/dev/null || true)
  [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]] && repo="${BASH_REMATCH[1]}" || { echo "repo no detectado" >&2; exit 1; }
fi

echo "## Failing Tests — $repo"
echo ""

if [[ -z "$run_id" ]]; then
  run_id=$(gh run list --repo "$repo" --status failure --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
  [[ -z "$run_id" ]] && { echo "(sin runs fallidos recientes)"; exit 0; }
  echo "Último run fallido: #$run_id"
fi
echo ""

echo "### Jobs fallidos"
gh run view "$run_id" --repo "$repo" --json jobs \
  --jq '.jobs[] | select(.conclusion == "failure") | "❌ \(.name)\n   Steps fallidos: \([.steps[] | select(.conclusion == "failure") | .name] | join(", "))"' \
  2>/dev/null || echo "(no se pudo obtener detalle)"
echo ""

echo "### Log de errores (primeras líneas útiles)"
gh run view "$run_id" --repo "$repo" --log-failed 2>/dev/null | \
  grep -E '(FAIL|Error|error|failed|●|✕|FAILED)' | \
  grep -v 'node_modules' | head -30 || echo "(sin log disponible)"
