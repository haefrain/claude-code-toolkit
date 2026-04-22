#!/usr/bin/env bash
# pr-context.sh — resumen compacto de un PR: descripción + archivos + comentarios.
# Uso: pr-context.sh [pr-number] [owner/repo]
set -euo pipefail
pr="${1:-}"
repo="${2:-}"
if [[ -z "$repo" ]]; then
  remote=$(git remote get-url origin 2>/dev/null || true)
  [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]] && repo="${BASH_REMATCH[1]}" || { echo "repo no detectado" >&2; exit 1; }
fi

if [[ -z "$pr" ]]; then
  # usar el PR de la rama actual
  pr=$(gh pr view --repo "$repo" --json number -q .number 2>/dev/null || true)
  [[ -z "$pr" ]] && { echo "Especificá un número de PR o estar en una rama con PR abierto." >&2; exit 1; }
fi

echo "## PR #$pr — $repo"
echo ""

gh pr view "$pr" --repo "$repo" \
  --json title,state,author,headRefName,baseRefName,additions,deletions,body,reviewDecision \
  --jq '"### \(.title)
Estado: \(.state) | Review: \(.reviewDecision // "PENDING")
Autor: \(.author.login) | \(.headRefName) → \(.baseRefName)
+\(.additions) / -\(.deletions)

**Descripción:**
\(.body // "(sin descripción)")"' 2>/dev/null
echo ""

echo "### Archivos modificados"
gh pr diff "$pr" --repo "$repo" --name-only 2>/dev/null | head -30 | sed 's/^/- /'
echo ""

echo "### Comentarios sin resolver"
gh api "repos/$repo/pulls/$pr/comments" \
  --jq '.[] | select(.position != null) | "- \(.path):\(.line // "?") — \(.user.login): \(.body[:120])"' \
  2>/dev/null | head -15 || echo "(sin comentarios inline)"
echo ""

echo "### Reviews"
gh pr view "$pr" --repo "$repo" --json reviews \
  --jq '.reviews[] | "\(.author.login): \(.state)"' 2>/dev/null | sort -u | head -10 || echo "(sin reviews)"
