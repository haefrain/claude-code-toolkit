#!/usr/bin/env bash
# gh-cross-ref.sh — valida referencias #NN en el body de un issue.
# Uso: gh-cross-ref.sh <issue-number> [owner/repo]
set -euo pipefail

num="${1:-}"
repo="${2:-}"
if [[ -z "$num" ]]; then
  echo "uso: gh-cross-ref.sh <issue> [owner/repo]" >&2; exit 1
fi
if [[ -z "$repo" ]]; then
  remote=$(git remote get-url origin 2>/dev/null || true)
  if [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
    repo="${BASH_REMATCH[1]}"
  else
    echo "repo no detectado" >&2; exit 1
  fi
fi

body=$(gh issue view "$num" --repo "$repo" --json body -q .body)
refs=$(echo "$body" | grep -oE '#[0-9]+' | sort -u | sed 's/#//')

echo "## Referencias de #$num en $repo"
if [[ -z "$refs" ]]; then
  echo "(ninguna)"; exit 0
fi

for r in $refs; do
  state=$(gh issue view "$r" --repo "$repo" --json state,title -q '"\(.state)\t\(.title)"' 2>/dev/null || echo "NOTFOUND	-")
  printf "#%-5s %s\n" "$r" "$state"
done
