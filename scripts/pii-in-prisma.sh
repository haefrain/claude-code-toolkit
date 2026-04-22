#!/usr/bin/env bash
# pii-in-prisma.sh — detecta campos PII en schema.prisma sin cifrado declarado.
# Uso: pii-in-prisma.sh [path]
set -euo pipefail
path="${1:-.}"
cd "$path"

schema="${path}/prisma/schema.prisma"
[[ ! -f "$schema" ]] && schema="prisma/schema.prisma"
[[ ! -f "$schema" ]] && { echo "(prisma/schema.prisma no encontrado)"; exit 0; }

echo "## PII in Prisma — $schema"
echo ""

# Campos que por nombre probablemente son PII
PII_PATTERNS='(email|phone|tel[ef]|password|passwd|document|cedula|dni|nit|rut|cuil|ssn|passport|nombre|apellido|name|address|direccion|location|birthdate|fecha_nac|gender|sexo|income|salary|credit_card|card_number|bank_account|iban|cvv|pin)'

echo "### Campos PII detectados"
echo '```'
printf "%-30s %-25s %-12s %s\n" "Modelo" "Campo" "Tipo" "Estado"
printf "%-30s %-25s %-12s %s\n" "------" "-----" "----" "------"

current_model=""
while IFS= read -r line; do
  if [[ "$line" =~ ^model[[:space:]]+([A-Za-z]+) ]]; then
    current_model="${BASH_REMATCH[1]}"
  elif [[ -n "$current_model" && "$line" =~ ^[[:space:]]+([a-zA-Z_]+)[[:space:]]+([A-Za-z?]+) ]]; then
    field="${BASH_REMATCH[1]}"
    type="${BASH_REMATCH[2]}"
    # saltar meta-campos
    [[ "$field" =~ ^(id|createdAt|updatedAt|@@|}) ]] && continue

    if echo "$field" | grep -qiE "$PII_PATTERNS"; then
      # verificar si hay cifrado declarado (por nombre del campo o anotación)
      if echo "$field" | grep -qiE '(encrypted|cifrado|hashed)' || echo "$line" | grep -qiE '(@encrypted|@cipher|@hash|Encrypted)'; then
        printf "%-30s %-25s %-12s %s\n" "$current_model" "$field" "$type" "🔒 cifrado"
      else
        printf "%-30s %-25s %-12s %s\n" "$current_model" "$field" "$type" "⚠️ SIN CIFRAR"
      fi
    fi
  elif [[ "$line" =~ ^\} ]]; then
    current_model=""
  fi
done < "$schema"
echo '```'
echo ""

echo "### Modelos sin campo \`updatedAt\` (posible gap de auditoría)"
grep -A 30 '^model ' "$schema" | awk '
  /^model / { model=$2; has_updated=0 }
  /updatedAt/ { has_updated=1 }
  /^\}/ { if (!has_updated && model) print "- " model; model="" }
' | head -10

echo ""
echo "### Sugerencia"
echo "Campos ⚠️ SIN CIFRAR deberían usar cifrado en capa de aplicación."
echo "Ver patrón de cifrado existente con: grep -rn 'encrypt' lib/ app/ --include='*.ts' | head -10"
