#!/usr/bin/env bash
# Contrato de verificación — gate por defecto en cada Stop.
# FULL=1 corre la suite completa: SOLO a solicitud explícita de Efraín.
# Generado por /verify-setup — AJUSTÁ los comandos a los scripts reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PM="npm run"   # npm run | pnpm | yarn | bun run — según lockfile

# ── Gate rápido: lint + typecheck ──
$PM lint
$PM typecheck

# ── Archivos afectados (working tree + rama vs base) ──
BASE="${VERIFY_BASE:-main}"
changed=$( (git diff --name-only --diff-filter=AM HEAD 2>/dev/null; git diff --name-only --diff-filter=AM "$BASE"...HEAD 2>/dev/null) \
  | sort -u | grep -E '\.(ts|tsx|js|jsx|mjs|cjs)$' | grep -vE '\.(test|spec)\.' || true)

if [[ -n "$changed" ]]; then
  # Tests enfocados de lo tocado (jest; con vitest: vitest related --run <archivos>)
  $PM test -- --findRelatedTests $changed

  # Mutación SOLO de los afectados — siempre, salvo exceder el presupuesto
  n=$(printf '%s\n' "$changed" | grep -c . || true)
  if [[ "$n" -le "${MUTATE_MAX_FILES:-10}" ]]; then
    npx stryker run --incremental --mutate "$(printf '%s' "$changed" | tr '\n' ',')"
  else
    echo "⏭️  Mutación diferida: $n archivos afectados (> ${MUTATE_MAX_FILES:-10}) — corréla al cierre de la tarjeta."
  fi
fi

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa + build — SOLO pedido explícito ──
  $PM test
  $PM build
fi
