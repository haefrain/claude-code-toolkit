#!/usr/bin/env bash
# session-start-hook.sh — se ejecuta vía hook SessionStart de Claude Code.
# Solo actúa si el cwd es un repo github.com/haefrain/*.
# Output va al contexto de Claude.
set -euo pipefail

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
