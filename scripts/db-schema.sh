#!/usr/bin/env bash
# db-schema.sh — resumen del schema de base de datos (Prisma, Laravel, Drizzle).
# Uso: db-schema.sh [path]
set -euo pipefail
path="${1:-.}"
cd "$path"

echo "## DB Schema Summary"
echo ""

# ---- Prisma ----
if [[ -f prisma/schema.prisma ]]; then
  echo "### Prisma"
  echo ""

  echo "**Proveedor:**"
  grep -E 'provider\s*=' prisma/schema.prisma | head -3 | sed 's/^\s*//'
  echo ""

  echo "**Modelos y campos:**"
  current_model=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^model[[:space:]]+([A-Za-z]+) ]]; then
      current_model="${BASH_REMATCH[1]}"
      echo ""
      echo "#### $current_model"
    elif [[ -n "$current_model" && "$line" =~ ^[[:space:]]+([a-zA-Z_]+)[[:space:]] ]]; then
      field="${BASH_REMATCH[1]}"
      [[ "$field" =~ ^(@@|}) ]] && continue
      type=$(echo "$line" | awk '{print $2}')
      # marcar PII probable y campos cifrados
      note=""
      echo "$field" | grep -qiE '(email|phone|tel|password|document|cedula|dni|nombre|name|address|direccion|rut|cuil|nit)' && note=" ⚠️PII"
      echo "$line" | grep -qi 'encrypt' && note=" 🔒"
      printf "  - %s: %s%s\n" "$field" "$type" "$note"
    elif [[ "$line" =~ ^\} ]]; then
      current_model=""
    fi
  done < prisma/schema.prisma
  echo ""

  echo "**Enums:**"
  grep -A 50 '^enum ' prisma/schema.prisma | grep -E '^(enum |  [A-Z_]+$|}$)' | head -30
  echo ""

  echo "**Migrations:**"
  mig_count=$(find prisma/migrations -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
  last_mig=$(find prisma/migrations -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1 | xargs basename 2>/dev/null || echo "ninguna")
  echo "- Total: $mig_count"
  echo "- Última: $last_mig"
fi

# ---- Drizzle ----
if [[ -f drizzle.config.ts || -f drizzle.config.js ]]; then
  echo "### Drizzle"
  schema_path=$(grep -oE 'schema:\s*["\x27][^"'"'"']+["\x27]' drizzle.config.ts drizzle.config.js 2>/dev/null | head -1 | sed "s/schema:[[:space:]]*['\"]//;s/['\"]//")
  echo "Schema file: ${schema_path:-no detectado}"
  [[ -f "$schema_path" ]] && grep -E '^export (const|table)' "$schema_path" | head -20
  echo ""
fi

# ---- Laravel ----
if [[ -d database/migrations ]]; then
  echo "### Laravel Migrations"
  echo "Total: $(find database/migrations -name '*.php' 2>/dev/null | wc -l)"
  echo "Últimas 10:"
  find database/migrations -name '*.php' 2>/dev/null | sort | tail -10 | xargs basename -a | sed 's/^/- /'
  echo ""
fi
