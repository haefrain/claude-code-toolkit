#!/usr/bin/env bash
# gh-backlog.sh — backlog compacto for:claude, ordenado por severidad.
# Uso: gh-backlog.sh [owner/repo]  (default: detecta desde cwd via git remote)
set -euo pipefail

repo="${1:-}"
if [[ -z "$repo" ]]; then
  remote=$(git remote get-url origin 2>/dev/null || true)
  if [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
    repo="${BASH_REMATCH[1]}"
  else
    echo "uso: gh-backlog.sh owner/repo (no se detectó remote)" >&2
    exit 1
  fi
fi

sev_rank() {
  case "$1" in
    *severity:critical*) echo 0 ;;
    *severity:high*)     echo 1 ;;
    *severity:medium*)   echo 2 ;;
    *severity:low*)      echo 3 ;;
    *)                   echo 9 ;;
  esac
}

printf "## Backlog for:claude — %s\n" "$repo"
tmp=$(mktemp)
gh issue list --repo "$repo" --label "for:claude" --state open --limit 50 \
  --json number,title,labels \
  --jq '.[] | "\(.number)\t\(.title)\t\([.labels[].name] | join(","))"' > "$tmp"

if [[ ! -s "$tmp" ]]; then
  echo "(sin issues abiertos)"
  rm -f "$tmp"; exit 0
fi

while IFS=$'\t' read -r num title labels; do
  r=$(sev_rank "$labels")
  sev=$(echo "$labels" | grep -oE 'severity:[a-z]+' | head -1 || echo "severity:?")
  blocked=""
  echo "$labels" | grep -q "blocked:external" && blocked=" [BLOCKED]"
  printf "%d\t#%s\t%s\t%s%s\n" "$r" "$num" "$sev" "$title" "$blocked"
done < "$tmp" | sort -n | cut -f2-

rm -f "$tmp"
echo ""
echo "Total: $(wc -l < <(gh issue list --repo "$repo" --label "for:claude" --state open --limit 50 --json number -q '.[]'))"
