#!/usr/bin/env bash
# dep-triage.sh — audit de dependencias clasificado en patch-safe vs major-breaking.
# Detecta gestor: npm/pnpm/yarn/composer/pip.
# Uso: dep-triage.sh [path]
set -euo pipefail
path="${1:-.}"
cd "$path"

echo "## Dep Triage — $path"

if [[ -f package.json ]]; then
  mgr="npm"
  [[ -f pnpm-lock.yaml ]] && mgr="pnpm"
  [[ -f yarn.lock ]] && mgr="yarn"
  echo "Gestor: $mgr"
  echo ""

  if [[ "$mgr" == "npm" ]]; then
    audit=$(npm audit --json 2>/dev/null || true)
  elif [[ "$mgr" == "pnpm" ]]; then
    audit=$(pnpm audit --json 2>/dev/null || true)
  else
    audit=$(yarn npm audit --json 2>/dev/null || npm audit --json 2>/dev/null || true)
  fi

  if [[ -z "$audit" ]]; then
    echo "(no se pudo correr audit)"; exit 0
  fi

  crit=$(echo "$audit" | jq -r '.metadata.vulnerabilities.critical // 0' 2>/dev/null || echo 0)
  high=$(echo "$audit" | jq -r '.metadata.vulnerabilities.high // 0' 2>/dev/null || echo 0)
  mod=$(echo  "$audit" | jq -r '.metadata.vulnerabilities.moderate // 0' 2>/dev/null || echo 0)
  low=$(echo  "$audit" | jq -r '.metadata.vulnerabilities.low // 0' 2>/dev/null || echo 0)

  echo "critical=$crit high=$high moderate=$mod low=$low"
  echo ""

  echo "### Accionables (critical + high)"
  echo "$audit" | jq -r '
    (.vulnerabilities // {}) | to_entries[] |
    select(.value.severity == "critical" or .value.severity == "high") |
    "\(.value.severity)\t\(.key)\t\(.value.via | if type=="array" then (map(if type=="string" then . else .title end) | join(",")) else tostring end)\tfix: \(.value.fixAvailable | if type=="boolean" then (if . then "auto" else "manual" end) else (.name // "manual") end)"
  ' 2>/dev/null | head -30

elif [[ -f composer.json ]]; then
  echo "Gestor: composer"
  composer audit --format=plain 2>&1 | head -40

elif [[ -f pubspec.yaml ]]; then
  echo "Gestor: pub (dart/flutter)"
  dart pub outdated --mode=security 2>&1 | head -40

elif [[ -f requirements.txt || -f pyproject.toml ]]; then
  echo "Gestor: pip"
  if command -v pip-audit >/dev/null; then
    pip-audit 2>&1 | head -40
  else
    echo "(instalar pip-audit: pip install pip-audit)"
  fi
else
  echo "(no se detectó gestor conocido)"
fi
