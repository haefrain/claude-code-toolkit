#!/usr/bin/env bash
# Contrato de verificación — gate por defecto en cada Stop.
# FULL=1 corre la suite completa: SOLO a solicitud explícita de Efraín.
# Generado por /verify-setup — COMPLETÁ con los comandos del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Gate rápido: lint + typecheck + tests enfocados de lo tocado ──
# <comando de lint del repo>
# <comando de typecheck del repo>
# <tests enfocados de los archivos afectados>

# ── Mutación SOLO de archivos afectados (siempre que exista herramienta) ──
# Infection (PHP): vendor/bin/infection --git-diff-base=main --git-diff-filter=AM --only-covered --min-covered-msi=80
# Stryker (JS/TS): npx stryker run --mutate <archivos-afectados>  (bloquea solo con thresholds.break en stryker.conf)
# mutant (Ruby):   bundle exec mutant run --since main  (estricto por defecto)

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa + build — SOLO pedido explícito de Efraín ──
  # <comando de tests del repo>
  # <comando de build del repo>
  :
fi
