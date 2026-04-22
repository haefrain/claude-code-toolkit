#!/usr/bin/env bash
# gh-bootstrap-labels.sh — crea el set estándar de labels de CLAUDE.md en un repo.
# Uso: gh-bootstrap-labels.sh owner/repo
set -euo pipefail

repo="${1:-}"
if [[ -z "$repo" ]]; then
  echo "uso: gh-bootstrap-labels.sh owner/repo" >&2; exit 1
fi

# Formato: "name|color|description"
labels=(
  "for:efrain|1f77b4|Requiere acción humana (dashboards, decisiones, infra externa)"
  "for:claude|9467bd|Ejecutable por Claude Code (código, docs, scripts)"
  "severity:critical|b60205|Fuga de datos, bloqueo legal, compromiso de seguridad"
  "severity:high|d93f0b|Impacto serio en usuario/negocio, riesgo de compliance"
  "severity:medium|fbca04|Importante pero no urgente"
  "severity:low|0e8a16|Mejora menor, nice-to-have"
  "area:gdpr|5319e7|Cumplimiento Ley 1581/GDPR, Habeas Data"
  "area:security|b60205|Vulnerabilidades, auth, secrets"
  "area:infra|0052cc|Servidores, Docker, Coolify, CI/CD"
  "area:payments|c2e0c6|Pagos, Wompi, lógica monetaria"
  "area:auth|fef2c0|Autenticación y autorización"
  "area:ui|c5def5|Interfaz de usuario"
  "area:docs|bfdadc|Documentación"
  "area:database|1d76db|Prisma, migraciones, esquema"
  "area:ai|8a2be2|OpenAI, Anthropic, prompts, AI SDK"
  "area:backups|fbca04|Respaldos y recuperación"
  "platform:web|0052cc|Web app"
  "platform:mobile|006b75|App móvil"
  "platform:backend|0e8a16|API/backend"
  "platform:shared|5319e7|Compartido entre plataformas"
  "blocked:external|000000|Bloqueado por acción externa (proveedor, legal, Efraín)"
  "needs-decision|888888|Requiere decisión antes de continuar"
  "type:bug|d73a4a|Bug"
  "type:feature|a2eeef|Nueva funcionalidad"
  "type:tech-debt|c5def5|Deuda técnica"
  "type:compliance|b60205|Compliance, legal, auditoría"
)

created=0
skipped=0
for entry in "${labels[@]}"; do
  IFS='|' read -r name color desc <<<"$entry"
  if gh label create "$name" --color "$color" --description "$desc" --repo "$repo" 2>/dev/null; then
    echo "+ $name"
    created=$((created+1))
  else
    # probablemente ya existe; intenta actualizar
    if gh label edit "$name" --color "$color" --description "$desc" --repo "$repo" >/dev/null 2>&1; then
      echo "= $name (actualizado)"
      skipped=$((skipped+1))
    else
      echo "! $name (falló)" >&2
    fi
  fi
done

echo ""
echo "Labels: $created creadas, $skipped ya existían"
