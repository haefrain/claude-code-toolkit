#!/usr/bin/env bash
# session-start-hook.sh — se ejecuta vía hook SessionStart de Claude Code.
# 1. Carga contexto enriquecido (handoff anterior + memorias + codegraph + capacidades)
#    en CUALQUIER repo via load-context.sh.
# 2. Solo en repos haefrain/*: carga el backlog automáticamente.
set -euo pipefail

# ── 1. Contexto enriquecido (todos los proyectos) ─────────────
"$(dirname "$0")/load-context.sh" 2>/dev/null || true

# ── 2. Backlog automático (solo repos haefrain/*) ─────────────
remote=$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" remote get-url origin 2>/dev/null || true)

if [[ ! "$remote" =~ github\.com[:/]haefrain/ ]]; then
  exit 0  # silencio si no es repo de haefrain
fi

repo=""
if [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
  repo="${BASH_REMATCH[1]}"
fi

echo "<!-- SessionStart hook: backlog cargado automáticamente -->"
echo ""
echo "# Contexto auto-cargado para sesión en $repo"
echo ""
"$(dirname "$0")/gh-backlog.sh" "$repo" 2>/dev/null || echo "(gh-backlog falló silenciosamente)"
echo ""
echo "---"
echo "Tip: usa /pick-next para el próximo issue sugerido, o /session-start para refrescar."
