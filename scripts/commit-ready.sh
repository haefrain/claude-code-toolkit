#!/usr/bin/env bash
# commit-ready.sh — pre-commit checklist: lint, typecheck, diff summary, mensaje sugerido.
# Uso: commit-ready.sh [path]
set -euo pipefail
path="${1:-.}"
cd "$path"

echo "## Commit Ready — $(basename "$(pwd)")"
echo ""

# ---- Staged files ----
staged=$(git diff --cached --name-only 2>/dev/null)
if [[ -z "$staged" ]]; then
  echo "⚠️  No hay archivos staged. Corre \`git add <archivos>\` primero."
  exit 1
fi
echo "### Staged ($(echo "$staged" | wc -l) archivos)"
echo "$staged" | sed 's/^/- /'
echo ""

# ---- Diff stat ----
echo "### Diff stat"
git diff --cached --stat 2>/dev/null | tail -3
echo ""

# ---- Lint ----
echo "### Lint"
if [[ -f package.json ]]; then
  mgr="npx"; [[ -f pnpm-lock.yaml ]] && mgr="pnpm"; [[ -f yarn.lock ]] && mgr="yarn"
  if jq -e '.scripts.lint' package.json >/dev/null 2>&1; then
    $mgr run lint --max-warnings 0 2>&1 | tail -10 && echo "✅ lint OK" || echo "❌ lint falló"
  else
    echo "(sin script lint en package.json)"
  fi
elif [[ -f artisan ]]; then
  php artisan lint 2>&1 | tail -5 || echo "(sin lint configurado)"
else
  echo "(lint no detectado)"
fi
echo ""

# ---- Type check ----
echo "### Type check"
if [[ -f tsconfig.json ]]; then
  mgr="npx"; [[ -f pnpm-lock.yaml ]] && mgr="pnpm"
  $mgr tsc --noEmit 2>&1 | tail -10 && echo "✅ tipos OK" || echo "❌ errores de tipos"
else
  echo "(tsconfig no encontrado)"
fi
echo ""

# ---- Tests relacionados ----
echo "### Tests relacionados (dry-run)"
if [[ -f jest.config.ts || -f jest.config.js ]]; then
  mgr="npx"; [[ -f pnpm-lock.yaml ]] && mgr="pnpm"
  files=$(echo "$staged" | tr '\n' ' ')
  $mgr jest --passWithNoTests --listTests --findRelatedTests $files 2>/dev/null | head -10 \
    && echo "(corré test-focus.sh para ejecutarlos)" || echo "(sin tests relacionados)"
fi
echo ""

# ---- Convención de commits del repo ----
echo "### Últimos 5 mensajes de commit (convención)"
git log --oneline -5 2>/dev/null
echo ""

# ---- Sugerencia de mensaje ----
echo "### Sugerencia de mensaje"
echo "Basado en los archivos staged, el mensaje debería seguir el patrón del repo."
echo "Archivos clave staged:"
echo "$staged" | head -5 | sed 's/^/  /'
echo ""
echo "(Claude generará la sugerencia final con contexto del diff)"
