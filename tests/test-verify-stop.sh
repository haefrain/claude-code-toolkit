#!/usr/bin/env bash
# Verifica el ciclo completo de verify-stop.sh: pasa, bloquea, anti-loop, fallback.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
TMPDIR="$(mktemp -d)"; export TMPDIR
repo="$(mktemp -d)"; git -C "$repo" init -q
trap 'rm -rf "$TMPDIR" "$repo"' EXIT
fail() { echo "FAIL(verify-stop): $1"; exit 1; }
run() { echo '{"session_id":"v1","stop_hook_active":false}' \
  | (cd "$repo" && CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/verify-stop.sh"); }

# 1. Sin marcador → silencio
out=$(run); [[ -z "$out" ]] || fail "sin marcador debe callar"

# 2. verify.sh que falla → block con output y marcador persistente
mkdir -p "$repo/.claude"
printf '#!/bin/bash\necho boom; exit 1\n' > "$repo/.claude/verify.sh"
touch "$TMPDIR/claude-verify-pending-v1"
out=$(run)
echo "$out" | jq -e '.decision == "block"' >/dev/null || fail "debe bloquear al fallar"
echo "$out" | grep -q "boom" || fail "reason debe incluir el output del fallo"
[[ -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "marcador debe persistir tras fallo"
[[ "$(cat "$TMPDIR/claude-verify-attempts-v1")" == "1" ]] || fail "attempts debe ser 1"

# 3. Segundo fallo → sigue bloqueando
out=$(run)
echo "$out" | jq -e '.decision == "block"' >/dev/null || fail "2do fallo debe bloquear"
[[ "$(cat "$TMPDIR/claude-verify-attempts-v1")" == "2" ]] || fail "attempts debe ser 2"

# 4. Tercer intento → systemMessage y estado limpio (anti-loop)
out=$(run)
echo "$out" | jq -e '.systemMessage' >/dev/null || fail "anti-loop debe emitir systemMessage"
[[ ! -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "marcador limpio tras anti-loop"
[[ ! -f "$TMPDIR/claude-verify-attempts-v1" ]] || fail "attempts limpio tras anti-loop"

# 5. verify.sh que pasa → silencio y estado limpio
printf '#!/bin/bash\nexit 0\n' > "$repo/.claude/verify.sh"
touch "$TMPDIR/claude-verify-pending-v1"
out=$(run); [[ -z "$out" ]] || fail "pase debe callar"
[[ ! -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "marcador limpio tras pase"

# 6. Sin verify.sh y sin package.json/composer.json → pasa silencioso
rm -rf "$repo/.claude"
touch "$TMPDIR/claude-verify-pending-v1"
out=$(run); [[ -z "$out" ]] || fail "fallback sin nada que correr debe callar"
[[ ! -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "marcador limpio en fallback vacío"

# 7. Fallback: package.json con script lint que falla → block con nudge
printf '{"scripts":{"lint":"exit 1"}}\n' > "$repo/package.json"
touch "$TMPDIR/claude-verify-pending-v1"
out=$(run)
echo "$out" | jq -e '.decision == "block"' >/dev/null || fail "fallback lint roto debe bloquear"
echo "$out" | grep -q "verify-setup" || fail "reason del fallback debe incluir nudge /verify-setup"
rm -f "$TMPDIR/claude-verify-pending-v1" "$TMPDIR/claude-verify-attempts-v1"

# 8. attempts_f corrupto (no numérico) → se trata como 0: no crashea, no ensucia stderr
rm -f "$repo/package.json"; rm -rf "$repo/.claude"
mkdir -p "$repo/.claude"
printf '#!/bin/bash\nexit 0\n' > "$repo/.claude/verify.sh"
echo "not-a-number" > "$TMPDIR/claude-verify-attempts-v1"
touch "$TMPDIR/claude-verify-pending-v1"
err=$(echo '{"session_id":"v1","stop_hook_active":false}' \
  | (cd "$repo" && CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/verify-stop.sh" 2>&1 >/dev/null)) || true
[[ -z "$err" ]] || fail "attempts corrupto no debe emitir stderr: $err"
[[ ! -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "attempts corrupto: pase debe limpiar marcador"

echo "OK: verify-stop"
