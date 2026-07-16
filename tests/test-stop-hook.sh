#!/usr/bin/env bash
# Verifica que stop-hook.sh reenvíe el block de verify-stop.sh y no genere handoff al bloquear.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
TMPDIR="$(mktemp -d)"; export TMPDIR
repo="$(mktemp -d)"; git -C "$repo" init -q
fail() { echo "FAIL(stop-hook): $1"; exit 1; }
inp='{"session_id":"s1","stop_hook_active":false,"transcript_path":""}'

# 1. Verificación rota → stop-hook emite el block y NO genera handoff
mkdir -p "$repo/.claude"
printf '#!/bin/bash\nexit 1\n' > "$repo/.claude/verify.sh"
touch "$TMPDIR/claude-verify-pending-s1"
out=$(echo "$inp" | (cd "$repo" && CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/stop-hook.sh"))
echo "$out" | jq -e '.decision == "block"' >/dev/null || fail "debe reenviar el block"
[[ ! -d "$repo/.claude/handoff" ]] || fail "no debe generar handoff al bloquear"

# 2. Verificación sana → sin JSON de bloqueo en stdout (flujo normal)
printf '#!/bin/bash\nexit 0\n' > "$repo/.claude/verify.sh"
touch "$TMPDIR/claude-verify-pending-s1"
rm -f "$TMPDIR/claude-verify-attempts-s1"
out=$(echo "$inp" | (cd "$repo" && CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/stop-hook.sh"))
echo "$out" | jq -e '.decision? // empty' >/dev/null 2>&1 && fail "pase no debe emitir decision"

echo "OK: stop-hook"
