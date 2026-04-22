#!/usr/bin/env bash
# ci-status.sh — estado compacto de los últimos workflows de GitHub Actions.
# Uso: ci-status.sh [owner/repo]
set -euo pipefail
repo="${1:-}"
if [[ -z "$repo" ]]; then
  remote=$(git remote get-url origin 2>/dev/null || true)
  [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]] && repo="${BASH_REMATCH[1]}" || { echo "repo no detectado" >&2; exit 1; }
fi

echo "## CI Status — $repo"
echo ""

echo "### Últimos runs"
gh run list --repo "$repo" --limit 10 \
  --json status,conclusion,name,headBranch,createdAt,databaseId \
  --jq '.[] | "\(.conclusion // .status)\t\(.name)\t\(.headBranch)\t\(.createdAt[:10])\t#\(.databaseId)"' \
  2>/dev/null | column -t -s $'\t' || echo "(sin runs)"
echo ""

echo "### Fallos recientes"
gh run list --repo "$repo" --status failure --limit 5 \
  --json status,conclusion,name,headBranch,databaseId \
  --jq '.[] | "❌ \(.name) [\(.headBranch)] — id \(.databaseId)"' \
  2>/dev/null || echo "(sin fallos recientes)"
echo ""

echo "### En progreso"
gh run list --repo "$repo" --status in_progress --limit 5 \
  --json name,headBranch,databaseId \
  --jq '.[] | "🔄 \(.name) [\(.headBranch)]"' \
  2>/dev/null || echo "(ninguno)"
