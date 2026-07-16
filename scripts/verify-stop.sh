#!/usr/bin/env bash
# verify-stop.sh — Verificación al Stop (Sección 01, guía 2026).
# Invocado desde stop-hook.sh ANTES de handoff/issues.
# Input stdin JSON: { "session_id": "...", "stop_hook_active": bool, ... }
# Contrato de salida (stdout):
#   vacío                     → pasó o no aplica
#   {"decision":"block",...}  → verificación falló: bloquear el stop
#   {"systemMessage":"..."}   → anti-loop agotado: dejar parar con advertencia
# SIEMPRE exit 0 — este hook jamás rompe la sesión.
set -uo pipefail

MAX_ATTEMPTS=2

input=$(cat)
sid=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null) || sid=""
[[ -z "$sid" ]] && exit 0

tmp="${TMPDIR:-/tmp}"; tmp="${tmp%/}"
marker="$tmp/claude-verify-pending-$sid"
attempts_f="$tmp/claude-verify-attempts-$sid"

# 1. Sin marcador → sesión sin ediciones de código
[[ -f "$marker" ]] || exit 0

# 2. Raíz del repo (sin repo git no hay contrato posible)
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || { rm -f "$marker" "$attempts_f"; exit 0; }

# 3. Anti-loop: al agotar los reintentos se permite parar con advertencia
attempts=$(cat "$attempts_f" 2>/dev/null || echo 0)
if [[ "$attempts" -ge "$MAX_ATTEMPTS" ]]; then
  rm -f "$marker" "$attempts_f"
  jq -cn --arg m "⚠️ verify-stop: la verificación falló $MAX_ATTEMPTS veces — se permite parar. Verificá manualmente antes de entregar." \
    '{systemMessage:$m}'
  exit 0
fi

# 4. Correr la verificación
out=""; rc=0; ran=""; nudge=""
if [[ -f "$root/.claude/verify.sh" ]]; then
  ran=".claude/verify.sh"
  out=$(cd "$root" && bash .claude/verify.sh 2>&1) || rc=$?
else
  # Fallback barato: SOLO lint/typecheck detectados. Nunca tests ni build.
  nudge=" ℹ️ Este repo no tiene .claude/verify.sh — corré /verify-setup para crear el contrato."
  if [[ -f "$root/package.json" ]]; then
    pm="npm run"
    [[ -f "$root/pnpm-lock.yaml" ]] && pm="pnpm"
    [[ -f "$root/yarn.lock" ]] && pm="yarn"
    [[ -f "$root/bun.lockb" || -f "$root/bun.lock" ]] && pm="bun run"
    for s in lint typecheck; do
      if jq -e --arg s "$s" '.scripts[$s] // empty' "$root/package.json" >/dev/null 2>&1; then
        ran="${ran}${pm} ${s}; "
        step_out=$(cd "$root" && $pm "$s" 2>&1) || rc=$?
        out="${out}${step_out}
"
      fi
    done
  elif [[ -f "$root/composer.json" ]]; then
    for s in lint phpstan; do
      if jq -e --arg s "$s" '.scripts[$s] // empty' "$root/composer.json" >/dev/null 2>&1; then
        ran="${ran}composer run ${s}; "
        step_out=$(cd "$root" && composer run "$s" 2>&1) || rc=$?
        out="${out}${step_out}
"
      fi
    done
  fi
  # Nada que correr → pasa (el nudge llega vía load-context al inicio de sesión)
  if [[ -z "$ran" ]]; then rm -f "$marker" "$attempts_f"; exit 0; fi
fi

# 5. Resultado
if [[ "$rc" -eq 0 ]]; then
  rm -f "$marker" "$attempts_f"
  exit 0
fi

echo $((attempts + 1)) > "$attempts_f"
tail_out=$(printf '%s' "$out" | tail -50)
reason="❌ Verificación falló (${ran}).${nudge} Arreglá los errores; al volver a entregar, la verificación correrá de nuevo.

${tail_out}"
jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
