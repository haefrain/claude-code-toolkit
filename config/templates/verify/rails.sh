#!/usr/bin/env bash
# Contrato de verificación — rápido por defecto, FULL=1 corre la suite completa.
# Generado por /verify-setup — AJUSTÁ los comandos a las herramientas reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Rápido (< 5 min): estilo ──
bundle exec rubocop --no-color

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa ──
  bundle exec rspec
fi

if [[ "${MUTATION:-0}" == "1" ]]; then
  # ── Mutation testing (lento): mide que los tests maten mutantes ──
  bundle exec mutant run
  # Frontend JS/TS del mismo repo (si tiene tests): npx stryker run
fi
