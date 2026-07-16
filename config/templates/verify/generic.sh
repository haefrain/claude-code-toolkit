#!/usr/bin/env bash
# Contrato de verificación — rápido por defecto, FULL=1 corre la suite completa.
# Generado por /verify-setup — COMPLETÁ con los comandos del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Rápido (< 5 min): lint + typecheck + tests enfocados ──
# <comando de lint del repo>
# <comando de typecheck del repo>

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa + build ──
  # <comando de tests del repo>
  # <comando de build del repo>
  :
fi
