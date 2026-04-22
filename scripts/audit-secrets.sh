#!/usr/bin/env bash
# audit-secrets.sh — detecta claves/tokens hardcoded.
# Uso: audit-secrets.sh [path]
set -euo pipefail
path="${1:-.}"

echo "## Audit Secrets — $path"
echo ""

# Patrones de secretos comunes
declare -A pats=(
  ["API keys genéricas"]='(api[_-]?key|apikey)\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{20,}["'"'"']'
  ["AWS access key"]='AKIA[0-9A-Z]{16}'
  ["Stripe live"]='sk_live_[0-9a-zA-Z]{24,}'
  ["OpenAI key"]='sk-[A-Za-z0-9]{32,}'
  ["Anthropic key"]='sk-ant-[A-Za-z0-9\-_]{20,}'
  ["GitHub token"]='gh[pous]_[A-Za-z0-9]{36,}'
  ["JWT hardcoded"]='eyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}'
  ["Bearer hardcoded"]='Bearer\s+[A-Za-z0-9_\-]{30,}'
  ["Password string"]='(password|passwd|pwd)\s*[:=]\s*["'"'"'][^"'"'"'\$\{]{8,}["'"'"']'
  ["Private key"]='-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
)

total=0
for label in "${!pats[@]}"; do
  echo "### $label"
  out=$(grep -rnE "${pats[$label]}" "$path" \
    --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
    --include='*.py' --include='*.php' --include='*.dart' \
    --include='*.json' --include='*.yml' --include='*.yaml' \
    --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist \
    --exclude-dir=build --exclude-dir=vendor --exclude-dir=.git \
    --exclude='*.lock' --exclude='package-lock.json' 2>/dev/null | head -10 || true)
  if [[ -z "$out" ]]; then
    echo "(sin hits)"
  else
    echo "$out"
    total=$((total + $(echo "$out" | wc -l)))
  fi
  echo ""
done

echo "---"
echo "Total hits: $total"
[[ $total -gt 0 ]] && echo "ACCIÓN: rotar secretos expuestos y mover a variables de entorno."
