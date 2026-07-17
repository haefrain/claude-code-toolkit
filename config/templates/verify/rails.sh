#!/usr/bin/env bash
# Contrato de verificación — gate por defecto en cada Stop.
# FULL=1 corre la suite completa: SOLO a solicitud explícita de Efraín.
# Generado por /verify-setup — AJUSTÁ los comandos a las herramientas reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Gate rápido: estilo ──
bundle exec rubocop --no-color

# ── Mutación SOLO del código Ruby afectado ──
BASE="${VERIFY_BASE:-main}"
changed_rb=$( (git diff --name-only --diff-filter=AM HEAD 2>/dev/null; git diff --name-only --diff-filter=AM "$BASE"...HEAD 2>/dev/null) \
  | sort -u | grep -E '\.rb$' | grep -vE '_(spec|test)\.rb$' || true)

if [[ -n "$changed_rb" ]]; then
  n=$(printf '%s\n' "$changed_rb" | grep -c . || true)
  if [[ "$n" -le "${MUTATE_MAX_FILES:-10}" ]]; then
    bundle exec mutant run --since "$BASE"
  else
    echo "⏭️  Mutación diferida: $n archivos Ruby afectados (> ${MUTATE_MAX_FILES:-10}) — corréla al cierre de la tarjeta."
  fi
  # Frontend JS/TS del mismo repo (si tiene tests): stryker scoped — ver plantilla node.sh
fi

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa — SOLO pedido explícito ──
  bundle exec rspec
fi
