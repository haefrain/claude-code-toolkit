#!/usr/bin/env bash
# stop-hook.sh — Stop hook.
# 0. SIEMPRE: verificación de código editado via verify-stop.sh (puede bloquear el stop).
# 1. SIEMPRE: genera handoff de sesión (cualquier repo git) via handoff-create.sh.
# 2. Solo repos haefrain/*: recuerda cerrar issues mencionados en la sesión.
# Input stdin JSON: { "stop_hook_active": true, "transcript_path": "..." }
set -euo pipefail

input=$(cat)
transcript=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null || echo "")

# ── 0. Verificación (Sección 01) — puede bloquear el stop ─────
verify_out=$(echo "$input" | bash "$(dirname "$0")/verify-stop.sh" 2>/dev/null || true)
if [[ -n "$verify_out" ]]; then
  decision=$(echo "$verify_out" | jq -r '.decision // ""' 2>/dev/null || echo "")
  if [[ "$decision" == "block" ]]; then
    # Bloquea: reenviar como ÚNICO stdout y salir. La sesión continúa;
    # el handoff llegará en el stop definitivo.
    echo "$verify_out"
    exit 0
  fi
  # systemMessage (anti-loop agotado): handoff en silencio + advertencia visible
  echo "$input" | "$(dirname "$0")/handoff-create.sh" >/dev/null 2>&1 || true
  echo "$verify_out"
  exit 0
fi

# ── 1. Handoff de sesión (cualquier repo git) ─────────────────
echo "$input" | "$(dirname "$0")/handoff-create.sh" 2>/dev/null || true

# ── 2. Recordatorio de issues (solo haefrain/*) ───────────────
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
