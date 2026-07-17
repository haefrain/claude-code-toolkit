#!/usr/bin/env bash
# Contrato de verificación — gate por defecto en cada Stop.
# FULL=1 corre la suite completa: SOLO a solicitud explícita de Efraín.
# Generado por /verify-setup — AJUSTÁ los comandos a las herramientas reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Gate rápido: estilo + análisis estático ──
vendor/bin/pint --test
vendor/bin/phpstan analyse --no-progress

# ── Mutación SOLO de los archivos PHP afectados ──
# El conteo usa el MISMO diff 2-dot que Infection (--git-diff-base): worktree + rama vs BASE.
BASE="${VERIFY_BASE:-main}"
if git rev-parse --verify -q "$BASE" >/dev/null 2>&1; then
  changed_php=$(git diff --name-only --diff-filter=AM "$BASE" 2>/dev/null | grep -E '\.php$' | grep -v 'Test\.php$' || true)
  if [[ -n "$changed_php" ]]; then
    # Tests enfocados de lo tocado (fail-fast barato, opcional — ajustar al repo):
    # vendor/bin/phpunit <tests de los archivos afectados>
    n=$(printf '%s\n' "$changed_php" | grep -c . || true)
    if [[ "$n" -le "${MUTATE_MAX_FILES:-10}" ]]; then
      # --min-covered-msi hace que el gate BLOQUEE con mutantes sobrevivientes en lo cambiado
      vendor/bin/infection --git-diff-base="$BASE" --git-diff-filter=AM --only-covered \
        --min-covered-msi="${MIN_MSI:-80}" --threads=max
    else
      echo "⏭️  Mutación diferida: $n archivos PHP afectados (> ${MUTATE_MAX_FILES:-10}) — corréla al cierre de la tarjeta."
    fi
    # Frontend JS/TS del mismo repo (si tiene tests): stryker scoped — ver plantilla node.sh
  fi
else
  echo "ℹ️  VERIFY_BASE='$BASE' no existe en este repo — ajustalo en el contrato; mutación omitida."
fi

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa — SOLO pedido explícito ──
  php artisan test
fi
