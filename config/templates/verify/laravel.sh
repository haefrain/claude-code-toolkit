#!/usr/bin/env bash
# Contrato de verificación — gate por defecto en cada Stop.
# FULL=1 corre la suite completa: SOLO a solicitud explícita de Efraín.
# Generado por /verify-setup — AJUSTÁ los comandos a las herramientas reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Gate rápido: estilo + análisis estático ──
vendor/bin/pint --test
vendor/bin/phpstan analyse --no-progress

# ── Mutación SOLO de los archivos PHP afectados (Infection trabaja sobre el diff) ──
BASE="${VERIFY_BASE:-main}"
changed_php=$( (git diff --name-only --diff-filter=AM HEAD 2>/dev/null; git diff --name-only --diff-filter=AM "$BASE"...HEAD 2>/dev/null) \
  | sort -u | grep -E '\.php$' | grep -v 'Test\.php$' || true)

if [[ -n "$changed_php" ]]; then
  n=$(printf '%s\n' "$changed_php" | grep -c . || true)
  if [[ "$n" -le "${MUTATE_MAX_FILES:-10}" ]]; then
    vendor/bin/infection --git-diff-base="$BASE" --git-diff-filter=AM --only-covered --threads=max
  else
    echo "⏭️  Mutación diferida: $n archivos PHP afectados (> ${MUTATE_MAX_FILES:-10}) — corréla al cierre de la tarjeta."
  fi
  # Frontend JS/TS del mismo repo (si tiene tests): stryker scoped — ver plantilla node.sh
fi

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa — SOLO pedido explícito ──
  php artisan test
fi
