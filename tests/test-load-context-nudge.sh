#!/usr/bin/env bash
# Verifica el nudge de /verify-setup en load-context.sh según exista o no el contrato.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
repo="$(mktemp -d)"; git -C "$repo" init -q
fail() { echo "FAIL(load-context-nudge): $1"; exit 1; }

# 1. Repo sin contrato → el output menciona /verify-setup
out=$(CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/load-context.sh" "$repo" 2>/dev/null || true)
echo "$out" | grep -q "verify-setup" || fail "sin contrato debe sugerir /verify-setup"

# 2. Repo con contrato → sin nudge
mkdir -p "$repo/.claude"
printf '#!/bin/bash\nexit 0\n' > "$repo/.claude/verify.sh"
out=$(CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/load-context.sh" "$repo" 2>/dev/null || true)
echo "$out" | grep -q "verify-setup" && fail "con contrato no debe haber nudge"

echo "OK: load-context-nudge"
