#!/usr/bin/env bash
# Verifica que load-context.sh inyecte el tooling.md del repo (sincronizado del hub)
# resolviendo el nombre por el remote origin, y calle cuando no hay tooling.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
HOME_FAKE="$(mktemp -d)"; repo="$(mktemp -d)"
trap 'rm -rf "$HOME_FAKE" "$repo"' EXIT
fail() { echo "FAIL(load-context-tooling): $1"; exit 1; }

git -C "$repo" init -q
git -C "$repo" remote add origin https://github.com/bukhr/tstrepo.git
mkdir -p "$HOME_FAKE/.claude/tooling"
printf '# Herramientas — tstrepo\n\nMARCADOR_TOOLING_XYZ\n' > "$HOME_FAKE/.claude/tooling/tstrepo.md"

# 1. Repo con tooling sincronizado → se inyecta con su contenido
out=$(HOME="$HOME_FAKE" CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/load-context.sh" "$repo" 2>/dev/null || true)
echo "$out" | grep -q "Tooling del repo" || fail "debe inyectar la sección de tooling"
echo "$out" | grep -q "MARCADOR_TOOLING_XYZ" || fail "debe incluir el contenido del tooling"

# 2. Repo sin tooling → sin sección
rm "$HOME_FAKE/.claude/tooling/tstrepo.md"
out=$(HOME="$HOME_FAKE" CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/load-context.sh" "$repo" 2>/dev/null || true)
echo "$out" | grep -q "Tooling del repo" && fail "sin tooling no debe haber sección"

# 3. Resolución por nombre de carpeta cuando no hay remote
repo2="$(mktemp -d -t tstrepo2)"; git -C "$repo2" init -q
name2=$(basename "$repo2")
printf 'MARCADOR_DIR_ABC\n' > "$HOME_FAKE/.claude/tooling/${name2}.md"
out=$(HOME="$HOME_FAKE" CLAUDE_PROJECT_DIR="$repo2" bash "$SCRIPTS/load-context.sh" "$repo2" 2>/dev/null || true)
echo "$out" | grep -q "MARCADOR_DIR_ABC" || fail "sin remote debe resolver por nombre de carpeta"
rm -rf "$repo2"

echo "OK: load-context-tooling"
