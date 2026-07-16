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
