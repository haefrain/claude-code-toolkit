#!/usr/bin/env bash
# Contrato de verificación — rápido por defecto, FULL=1 corre la suite completa.
# Generado por /verify-setup — AJUSTÁ los comandos a los scripts reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PM="npm run"   # npm run | pnpm | yarn | bun run — según lockfile

# ── Rápido (< 5 min): lint + typecheck ──
$PM lint
$PM typecheck

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa + build ──
  $PM test
  $PM build
fi

if [[ "${MUTATION:-0}" == "1" ]]; then
  # ── Mutation testing (lento): mide que los tests maten mutantes ──
  npx stryker run
fi
