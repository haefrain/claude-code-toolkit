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
| retomemos / continúa / dónde quedamos | `load-context.sh` (automático via SessionStart; manual: `/load-context`) |
| genera handoff / guardar estado / cerrar sesión | `/handoff` (también automático via Stop hook) |
| inicializar codegraph / indexar proyecto | `/codegraph-init` |
| cómo funciona X / qué llama a X / impacto de cambiar X | tools MCP codegraph (`codegraph_context`, `codegraph_trace`, `codegraph_impact`) si hay índice — ANTES de grep manual |
| configurar verificación / verify del repo | `/verify-setup` (genera `.claude/verify.sh`) |

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

**Handoff & Contexto**
- `handoff-create.sh` — genera `{repo}/.claude/handoff/YYYYMMDD-HHMM.md` al cerrar sesión (cualquier repo git; excluido de git via `.git/info/exclude`). Retiene los 10 más recientes.
- `load-context.sh` — al iniciar sesión carga: handoff anterior + memorias del proyecto + estado codegraph + inventario de capacidades (commands/skills/agents/MCP del repo y globales). Silencioso si no hay nada.

**Hooks internos** (no llamar manualmente)
- `session-start-hook.sh` — SessionStart, corre load-context.sh en cualquier repo + backlog si repo haefrain/*
- `stop-hook.sh` — Stop, corre handoff-create.sh en cualquier repo + recordatorio de issues si haefrain/*
- `prompt-trigger-hook.sh` — UserPromptSubmit, inyecta recordatorio según keywords
- `post-tool-hook.sh` — PostToolUse, recuerda correr tests tras editar código
- `verify-stop.sh` — invocado por stop-hook.sh: corre `.claude/verify.sh` del repo si hubo código editado; bloquea el stop si falla (máx. 2 reintentos)

## Slash commands (`~/.claude/commands/`)

`/session-start` `/backlog` `/pick-next` `/map` `/audit-quick` `/deps-check`
`/issue-refine` `/verify-root-cause` `/changes-summary` `/recent-activity`
`/find-usages` `/search-docs` `/test-focus` `/ci-status` `/failing-tests`
`/db-schema` `/pr-context` `/commit-ready` `/branch-cleanup` `/rate-limit-audit`
`/auth-audit` `/pii-in-prisma` `/gdpr-check` `/explain-diff` `/undo-last`
`/handoff` `/load-context` `/codegraph-init` `/verify-setup`

## Máximo aprovechamiento de capacidades

Al inicio de cada sesión, `load-context.sh` inyecta el inventario de capacidades disponibles
(slash commands, skills, agents y MCP servers del repo + plugins globales + codegraph).
**Regla:** usá siempre la herramienta más específica disponible:
- script del toolkit > comando crudo
- tools MCP de codegraph > grep/read manual (si hay índice; si no, sugerí `/codegraph-init`)
- skill o plugin instalado > improvisación
- handoff de la sesión anterior > re-explorar el repo desde cero
