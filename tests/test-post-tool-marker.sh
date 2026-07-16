#!/usr/bin/env bash
# Verifica que post-tool-hook.sh registre archivos de código en el marcador de sesión.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
TMPDIR="$(mktemp -d)"; export TMPDIR
trap 'rm -rf "$TMPDIR"' EXIT
fail() { echo "FAIL(post-tool-marker): $1"; exit 1; }

# 1. Edit de .ts crea marcador con la ruta
echo '{"session_id":"t1","tool_name":"Edit","tool_input":{"file_path":"/x/a.ts"}}' \
  | bash "$SCRIPTS/post-tool-hook.sh" >/dev/null 2>&1
grep -qxF "/x/a.ts" "$TMPDIR/claude-verify-pending-t1" 2>/dev/null || fail "Edit .ts debe crear marcador"

# 2. Edit de .md NO crea marcador
echo '{"session_id":"t2","tool_name":"Edit","tool_input":{"file_path":"/x/a.md"}}' \
  | bash "$SCRIPTS/post-tool-hook.sh" >/dev/null 2>&1
[[ ! -f "$TMPDIR/claude-verify-pending-t2" ]] || fail ".md no debe marcar"

# 3. Mismo archivo dos veces → una sola línea
echo '{"session_id":"t1","tool_name":"Write","tool_input":{"file_path":"/x/a.ts"}}' \
  | bash "$SCRIPTS/post-tool-hook.sh" >/dev/null 2>&1
[[ "$(grep -c . "$TMPDIR/claude-verify-pending-t1")" -eq 1 ]] || fail "sin duplicados"

# 4. Tool distinto de Edit/Write no marca
echo '{"session_id":"t3","tool_name":"Read","tool_input":{"file_path":"/x/b.ts"}}' \
  | bash "$SCRIPTS/post-tool-hook.sh" >/dev/null 2>&1
[[ ! -f "$TMPDIR/claude-verify-pending-t3" ]] || fail "Read no debe marcar"

# 5. TMPDIR roto → el hook NO revienta (exit 0, sin ruido)
rc=0
out=$(TMPDIR="/nonexistent-dir-xyz" bash "$SCRIPTS/post-tool-hook.sh" 2>&1 \
  <<< '{"session_id":"t9","tool_name":"Edit","tool_input":{"file_path":"/x/a.ts"}}') || rc=$?
[[ "$rc" -eq 0 ]] || fail "TMPDIR roto no debe romper el hook (exit $rc)"

echo "OK: post-tool-marker"
