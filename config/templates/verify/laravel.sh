#!/usr/bin/env bash
# Contrato de verificación — rápido por defecto, FULL=1 corre la suite completa.
# Generado por /verify-setup — AJUSTÁ los comandos a las herramientas reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Rápido (< 5 min): estilo + análisis estático ──
vendor/bin/pint --test
vendor/bin/phpstan analyse --no-progress

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa ──
  php artisan test
fi

if [[ "${MUTATION:-0}" == "1" ]]; then
  # ── Mutation testing (lento): mide que los tests maten mutantes ──
  vendor/bin/infection --min-msi=70 --threads=max
  # Frontend JS/TS del mismo repo (si tiene tests): npx stryker run
fi
