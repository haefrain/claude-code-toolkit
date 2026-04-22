# Toolkit de Optimización de Tokens

**Regla:** tarea determinística (listar, buscar, parsear) → script. Juicio (redactar, priorizar, diseñar) → modelo. Nunca dumps crudos al contexto.

## Disparadores automáticos OBLIGATORIOS

| Cuando el usuario dice… | Ejecutar |
|---|---|
| backlog / qué sigue / próximo issue / retomemos | `gh-backlog.sh` |
| audita / PII / secretos / hardcoded | `audit-pii.sh` + `audit-secrets.sh` en paralelo |
| vulnerabilidades / CVE / dependencias | `dep-triage.sh` |
| explícame el proyecto / estructura / qué hay aquí | `project-map.sh` |
| qué cambié / quiero commitear / antes de commit | `changes-summary.sh` + `commit-ready.sh` |
| CI falló / tests fallaron / build roto | `ci-status.sh` + `failing-tests.sh` |
| contexto del PR / ver el PR | `pr-context.sh` |
| schema prisma / modelos DB | `db-schema.sh` |
| gdpr / compliance / check completo | `gdpr-quick-check.sh` |
| qué se trabajó / actividad reciente / últimos días | `recent-activity.sh 7` |
| arreglar/modificar función/endpoint/campo | protocolo verify-root-cause ANTES de editar |
| crear issue | checklist calidad + delegar a `issue-manager` |
| cerrar issue | verificar todos los criterios ✅ primero |
| bootstrap labels | `gh-bootstrap-labels.sh owner/repo` |

❌ Anti-patrón: `gh issue list` crudo / leer archivos uno por uno / explicarle al usuario que use el comando.

## Scripts (`~/.claude/scripts/`)

**Backlog/Issues**
- `gh-backlog.sh [repo]` — backlog for:claude priorizado por severidad
- `gh-bootstrap-labels.sh owner/repo` — crea/actualiza las 26 labels estándar
- `gh-cross-ref.sh <issue> [repo]` — valida referencias #NN en el body

**Auditoría de seguridad**
- `audit-pii.sh [path]` — PII en console.log/logger
- `audit-secrets.sh [path]` — tokens y claves hardcoded
- `rate-limit-audit.sh [path]` — endpoints sin rate limiting
- `auth-routes-audit.sh [path]` — endpoints sin auth
- `pii-in-prisma.sh [path]` — campos PII en schema sin cifrado
- `gdpr-quick-check.sh [path]` — combina los 5 anteriores

**Exploración de proyecto**
- `project-map.sh [path]` — stack + árbol + rutas + schema (<150 líneas). SIEMPRE primero.
- `db-schema.sh [path]` — modelos Prisma/Drizzle/Laravel con PII marcado
- `search-docs.sh <término> [path]` — busca en *.md, JSDoc
- `find-usages.sh <símbolo> [path]` — callers, imports, tests

**Git/CI**
- `changes-summary.sh [path]` — status + diff stat + commits
- `recent-activity.sh [days] [path]` — archivos y commits más activos
- `commit-ready.sh [path]` — lint + typecheck + sugerencia de commit
- `branch-cleanup.sh [base] [path]` — ramas mergeadas para borrar
- `ci-status.sh [repo]` — GitHub Actions en tabla compacta
- `failing-tests.sh [run-id] [repo]` — tests fallidos del último run
- `pr-context.sh [N] [repo]` — descripción + archivos + comentarios sin resolver
- `test-focus.sh [archivo] [path]` — solo tests del archivo modificado
- `dep-triage.sh [path]` — CVEs clasificados (npm/pnpm/composer/pip)

**Hooks internos** (no llamar manualmente)
- `session-start-hook.sh` — SessionStart, carga backlog si repo haefrain/*
- `prompt-trigger-hook.sh` — UserPromptSubmit, inyecta recordatorio según keywords
- `post-tool-hook.sh` — PostToolUse, recuerda correr tests tras editar código

## Slash commands (`~/.claude/commands/`)

`/session-start` `/backlog` `/pick-next` `/map` `/audit-quick` `/deps-check`
`/issue-refine` `/verify-root-cause` `/changes-summary` `/recent-activity`
`/find-usages` `/search-docs` `/test-focus` `/ci-status` `/failing-tests`
`/db-schema` `/pr-context` `/commit-ready` `/branch-cleanup` `/rate-limit-audit`
`/auth-audit` `/pii-in-prisma` `/gdpr-check` `/explain-diff` `/undo-last`
