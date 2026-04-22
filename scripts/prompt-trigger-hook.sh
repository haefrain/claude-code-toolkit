#!/usr/bin/env bash
# prompt-trigger-hook.sh — UserPromptSubmit hook.
# Lee el prompt del usuario desde stdin (JSON), detecta intenciones conocidas,
# e inyecta un recordatorio al contexto para que Claude use los scripts correctos.
#
# Input (stdin, JSON): { "prompt": "...", "cwd": "...", ... }
# Output (stdout): texto que Claude verá como contexto adicional. Silencio = no inyectar.
set -euo pipefail

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null || echo "")
cwd=$(echo "$input" | jq -r '.cwd // ""' 2>/dev/null || pwd)

[[ -z "$prompt" ]] && exit 0

# lowercase para match case-insensitive
p=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

triggers=()

# Detecta repo haefrain/*
is_haefrain_repo=0
remote=$(git -C "$cwd" remote get-url origin 2>/dev/null || true)
[[ "$remote" =~ github\.com[:/]haefrain/ ]] && is_haefrain_repo=1

# 1. Backlog / qué sigue
if echo "$p" | grep -qE '(backlog|qu[eé] (hay|tengo|sigue|me toca)|pr[oó]ximo issue|retomemos|retomar|qu[eé] pendiente)'; then
  [[ $is_haefrain_repo -eq 1 ]] && triggers+=("→ Usa \`~/.claude/scripts/gh-backlog.sh\` (detecta repo desde cwd). NO hagas \`gh issue list\` crudo ni leas bodies.")
fi

# 2. Auditoría
if echo "$p" | grep -qE '(audit[ao]|auditor[ií]a|revisar seguridad|buscar? pii|buscar? secretos|hardcoded)'; then
  triggers+=("→ Corre en paralelo \`~/.claude/scripts/audit-pii.sh\` y \`~/.claude/scripts/audit-secrets.sh\` ANTES de explorar archivos a mano.")
fi

# 3. Dependencias
if echo "$p" | grep -qE '(vulnerabilid|cve|dependenci[ao]s?|npm audit|composer audit|actualizar paquetes)'; then
  triggers+=("→ Usa \`~/.claude/scripts/dep-triage.sh\` en vez de \`npm audit\` crudo.")
fi

# 4. Root cause / modificar función
if echo "$p" | grep -qE '(arreglar|modificar|cambiar|refactori|fix) (la )?(funci[oó]n|endpoint|m[eé]todo|campo|columna)'; then
  triggers+=("→ ANTES de editar: aplica protocolo verify-root-cause (grep de callers/imports/escrituras). Caso ReclamaAI #46 sigue fresco.")
fi

# 5. Crear issue
if echo "$p" | grep -qE '(crear? (un )?issue|crear? (un )?ticket|abrir issue|redactar issue|nuevo issue)'; then
  triggers+=("→ ANTES de crear: revisa checklist de 'Calidad de los issues' en CLAUDE.md. Delegar al agente \`issue-manager\` para crearlo.")
fi

# 6. Cerrar issue
if echo "$p" | grep -qE '(cerrar? (el |un )?issue|marcar completado|close issue)'; then
  triggers+=("→ ANTES de cerrar: verifica que TODOS los criterios de aceptación estén ✅. Delegar al \`issue-manager\`.")
fi

# 7. Mapa del proyecto / orientación inicial
if echo "$p" | grep -qE '(estructura del proyecto|mapa del proyecto|de qu[eé] va|expl[ií]came el proyecto|orient[ae]me|qu[eé] tiene este|qu[eé] hay aqu[ií]|c[oó]mo est[aá] organizado|dame (una )?vista general)'; then
  triggers+=("→ Corre \`~/.claude/scripts/project-map.sh\` (devuelve stack + estructura + rutas + schema en <150 líneas). NO leas archivos uno por uno.")
fi

# 8. Git: diff, cambios, commitear
if echo "$p" | grep -qE '(qu[eé] cambi[oó]|qu[eé] modifiqu[eé]|ver (los )?cambios|listo para commitear|quiero commitear|antes de commit|diff del)'; then
  triggers+=("→ Usa \`~/.claude/scripts/changes-summary.sh\` para status + diff stat compacto. Si va a commitear: \`~/.claude/scripts/commit-ready.sh\`.")
fi

# 9. CI / tests / fallos
if echo "$p" | grep -qE '(ci (fall[oó]|est[aá])|tests? fall(ando|[oó])|github actions|pipeline|build roto|qu[eé] fall[oó])'; then
  triggers+=("→ Usa \`~/.claude/scripts/ci-status.sh\` para estado compacto. Para detalle de fallos: \`~/.claude/scripts/failing-tests.sh\`.")
fi

# 10. PR / pull request
if echo "$p" | grep -qE '(contexto del pr|qu[eé] tiene el pr|revisar pr|ver el pr|comentarios del pr)'; then
  triggers+=("→ Usa \`~/.claude/scripts/pr-context.sh\` para descripción + archivos + comentarios sin resolver del PR.")
fi

# 11. Schema DB / modelos
if echo "$p" | grep -qE '(schema (de )?pris|modelos de (la )?db|campos (de )?la db|qu[eé] modelos hay|tabla (de )?prisma)'; then
  triggers+=("→ Usa \`~/.claude/scripts/db-schema.sh\` — resumen de modelos + campos PII + migrations. NO leas schema.prisma completo.")
fi

# 12. GDPR / compliance completo
if echo "$p" | grep -qE '(gdpr|compliance|habeas data|triage de seguridad|revisi[oó]n legal|check completo)'; then
  triggers+=("→ Usa \`~/.claude/scripts/gdpr-quick-check.sh\` — corre PII + secrets + auth + rate-limit + prisma en un solo comando.")
fi

# 13. Actividad reciente / retomar
if echo "$p" | grep -qE '(qu[eé] se (hizo|trabaj[oó]|cambi[oó])|retomemos|actividad reciente|[uú]ltima semana|[uú]ltimos d[ií]as)'; then
  triggers+=("→ Usa \`~/.claude/scripts/recent-activity.sh 7\` para ver commits y archivos tocados en los últimos 7 días.")
fi

# 14. Bootstrap labels
if [[ $is_haefrain_repo -eq 1 ]] && echo "$p" | grep -qE '(bootstrap|configurar labels|crear labels|labels est[aá]ndar)'; then
  repo_name=""
  [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]] && repo_name="${BASH_REMATCH[1]}"
  triggers+=("→ Corre \`~/.claude/scripts/gh-bootstrap-labels.sh $repo_name\` — crea/actualiza las 26 labels en lote.")
fi

# Si hay triggers, emitir bloque de recordatorio
if [[ ${#triggers[@]} -gt 0 ]]; then
  echo "<!-- auto-trigger: CLAUDE.md -> Disparadores automáticos OBLIGATORIOS -->"
  echo ""
  echo "**Recordatorio automático del toolkit:**"
  for t in "${triggers[@]}"; do
    echo "$t"
  done
fi

exit 0
