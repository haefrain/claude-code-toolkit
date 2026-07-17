#!/usr/bin/env bash
# sync-buk-tooling.sh — trae los tooling.md de bukhr/buk-agentic-hub a ~/.claude/tooling/
# para que load-context.sh los inyecte al abrir cada repo Buk.
# Los datos son internos de Buk: viven SOLO en esta máquina, JAMÁS se comitean al toolkit.
set -euo pipefail

DEST="$HOME/.claude/tooling"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 --quiet https://github.com/bukhr/buk-agentic-hub.git "$TMP/hub" \
  || { echo "⚠️  No se pudo clonar bukhr/buk-agentic-hub (¿auth de gh/git?)"; exit 1; }

mkdir -p "$DEST"
n=0

# Genérico (hereda entre repos, si existe)
if [[ -f "$TMP/hub/.claude_repos/tooling.md" ]]; then
  cp "$TMP/hub/.claude_repos/tooling.md" "$DEST/_generic.md"
  n=$((n+1))
fi

# Por repo
for d in "$TMP/hub/.claude_repos"/*/; do
  [[ -d "$d" ]] || continue
  repo=$(basename "$d")
  if [[ -f "${d}tooling.md" ]]; then
    cp "${d}tooling.md" "$DEST/$repo.md"
    n=$((n+1))
  fi
done

echo "✅ $n tooling.md sincronizados en $DEST (fuente: bukhr/buk-agentic-hub)"
