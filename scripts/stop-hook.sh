#!/usr/bin/env bash
# stop-hook.sh — Stop hook. Recuerda cerrar issues si hay criterios marcados en la sesión.
# Input stdin JSON: { "stop_hook_active": true, "transcript_path": "..." }
# Claude Code pasa el transcript; lo parseamos para detectar issues mencionados.
set -euo pipefail

input=$(cat)
transcript=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null || echo "")

# Detectar si estamos en repo haefrain/*
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
remote=$(git -C "$cwd" remote get-url origin 2>/dev/null || true)
[[ "$remote" =~ github\.com[:/]haefrain/ ]] || exit 0

repo=""
[[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]] && repo="${BASH_REMATCH[1]}"

# Buscar issues mencionados en el transcript (si está disponible)
mentioned_issues=""
if [[ -n "$transcript" && -f "$transcript" ]]; then
  mentioned_issues=$(grep -oE '#[0-9]{2,4}' "$transcript" 2>/dev/null | sort -u | sed 's/#//' | head -10 || true)
fi

if [[ -z "$mentioned_issues" ]]; then
  exit 0
fi

# Verificar cuáles siguen abiertos
open_mentioned=""
for n in $mentioned_issues; do
  state=$(gh issue view "$n" --repo "$repo" --json state -q .state 2>/dev/null || echo "")
  [[ "$state" == "OPEN" ]] && open_mentioned="$open_mentioned #$n"
done

open_mentioned=$(echo "$open_mentioned" | xargs)
[[ -z "$open_mentioned" ]] && exit 0

echo "<!-- stop-hook: issues abiertos detectados en sesión -->"
echo ""
echo "📋 **Issues mencionados en la sesión que siguen abiertos:** $open_mentioned"
echo "Si completaste el trabajo, cerrá con: \`gh issue close N --repo $repo --reason completed --comment \"...\"\`"
echo "Si no terminaste: agregá un comentario de estado en el issue."

exit 0
