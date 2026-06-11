# Claude Code Toolkit

**Scripts, slash commands, hooks, handoff entre sesiones, CodeGraph MCP y RTK preconfigurados para Claude Code. Una sola línea para instalar todo.**

---

## Instalación rápida (macOS / Ubuntu / WSL)

```bash
git clone https://github.com/haefrain/claude-code-toolkit.git
cd claude-code-toolkit
bash install.sh
```

Eso es todo. El instalador detecta el OS (Homebrew en macOS, apt en Ubuntu/WSL) y configura automáticamente:

- ✅ RTK (Rust Token Killer) en `~/.local/bin/`
- ✅ CodeGraph como MCP server de Claude Code (inteligencia de código)
- ✅ 26 scripts Bash en `~/.claude/scripts/`
- ✅ 28 slash commands en `~/.claude/commands/`
- ✅ Handoff automático entre sesiones (histórico en `.claude/handoff/` de cada repo, fuera de git)
- ✅ CLAUDE.md con reglas prescriptivas
- ✅ 5 hooks en `settings.json` (SessionStart, UserPromptSubmit, PostToolUse, Stop, PreToolUse)
- ✅ 30+ permisos pre-aprobados para que no aparezcan prompts de confirmación

---

## Qué incluye

### RTK — Rust Token Killer
Proxy CLI que filtra el output de comandos antes de mandarlo al contexto de Claude. Ahorra 60-90% de tokens en operaciones de desarrollo.

```bash
rtk gain          # estadísticas de ahorro
rtk gain --history # historial de comandos
rtk discover      # analiza sesiones pasadas para encontrar oportunidades
```

Se integra automáticamente via hook `PreToolUse` — cada comando Bash pasa por `rtk hook claude` antes de ejecutarse.

### CodeGraph — Inteligencia de código
Servidor MCP que indexa el grafo de símbolos del proyecto (callers, callees, impacto, trazas). Claude lo consulta automáticamente al cargar contexto y en preguntas tipo "¿qué llama a X?".

```bash
/codegraph-init            # Inicializar índice en el proyecto actual (desde Claude Code)
codegraph status .         # Ver estado del índice
codegraph query foo        # Buscar símbolo "foo"
codegraph context "tarea"  # Contexto relevante para una tarea
```

### Handoff entre sesiones
Al cerrar cada sesión, el Stop hook guarda un resumen (branch, commits, archivos modificados, issues trabajados) en `.claude/handoff/YYYYMMDD-HHMM.md` **dentro del repo** — excluido de git automáticamente via `.git/info/exclude`, sin tocar tu `.gitignore`. Al abrir la próxima sesión, SessionStart lo carga junto con las memorias del proyecto y el inventario de capacidades disponibles (skills, plugins, MCP servers). Funciona en **cualquier repo git**, no solo haefrain/*.

```bash
/handoff        # Generar handoff manual en cualquier momento
/load-context   # Recargar el contexto enriquecido en la sesión actual
```

Se retienen los últimos 10 handoffs por repo (limpieza automática).

### Scripts Bash (`~/.claude/scripts/`)

| Script | Función |
|---|---|
| `gh-backlog.sh [repo]` | Backlog `for:claude` priorizado por severidad. Sin bodies. |
| `gh-bootstrap-labels.sh owner/repo` | Crea las 26 labels estándar de GitHub en un repo. |
| `gh-cross-ref.sh <issue>` | Valida referencias `#NN` en el body de un issue. |
| `project-map.sh [path]` | Stack + estructura + rutas + schema en <150 líneas. |
| `db-schema.sh [path]` | Modelos Prisma/Drizzle/Laravel con campos PII marcados. |
| `audit-pii.sh [path]` | PII en console.log, logger, errores. |
| `audit-secrets.sh [path]` | Claves y tokens hardcoded. |
| `rate-limit-audit.sh [path]` | Endpoints sin rate limiting. |
| `auth-routes-audit.sh [path]` | Endpoints sin protección de auth. |
| `pii-in-prisma.sh [path]` | Campos PII en schema.prisma sin cifrado. |
| `gdpr-quick-check.sh [path]` | Combina los 5 audits anteriores en un solo comando. |
| `dep-triage.sh [path]` | CVEs clasificados (npm/pnpm/yarn/composer/pip). |
| `changes-summary.sh [path]` | git status + diff stat + últimos commits. |
| `recent-activity.sh [days]` | Archivos y commits más activos en los últimos N días. |
| `commit-ready.sh [path]` | Lint + typecheck + diff stat + sugerencia de commit. |
| `ci-status.sh [repo]` | GitHub Actions en tabla compacta. |
| `failing-tests.sh [run-id]` | Tests fallidos del último CI run. |
| `pr-context.sh [N]` | Descripción + archivos + comentarios sin resolver de un PR. |
| `find-usages.sh <símbolo>` | Callers, imports y tests de un símbolo. |
| `search-docs.sh <término>` | Busca en `*.md`, `*.mdx` y JSDoc. |
| `test-focus.sh [archivo]` | Tests del archivo modificado (jest/vitest/phpunit/pytest/flutter). |
| `branch-cleanup.sh [base]` | Ramas mergeadas listas para borrar. |
| `handoff-create.sh` | Genera `{repo}/.claude/handoff/YYYYMMDD-HHMM.md` al cerrar sesión (excluido de git). |
| `load-context.sh` | Carga handoff anterior + memorias + codegraph + capacidades al iniciar. |

### Slash Commands (`~/.claude/commands/`)

Disponibles en Claude Code con `/nombre`:

`/session-start` `/backlog` `/pick-next` `/map` `/audit-quick` `/deps-check`
`/verify-root-cause` `/issue-refine` `/changes-summary` `/recent-activity`
`/find-usages` `/search-docs` `/test-focus` `/ci-status` `/failing-tests`
`/db-schema` `/pr-context` `/commit-ready` `/branch-cleanup` `/rate-limit-audit`
`/auth-audit` `/pii-in-prisma` `/gdpr-check` `/explain-diff` `/undo-last`
`/handoff` `/load-context` `/codegraph-init`

### Hooks automáticos

| Hook | Cuándo actúa | Qué hace |
|---|---|---|
| `SessionStart` | Al abrir Claude Code en cualquier repo | Carga handoff anterior + memorias + codegraph + capacidades; en repos `haefrain/*` también el backlog |
| `UserPromptSubmit` | Cada mensaje del usuario | Detecta intención y sugiere el script correcto |
| `PostToolUse` | Tras editar un archivo | Detecta tests relacionados y recuerda correrlos |
| `Stop` | Al terminar el turno | Genera handoff en `.claude/handoff/` del repo; en `haefrain/*` recuerda cerrar issues |
| `PreToolUse` | Antes de cada comando Bash | RTK filtra el output para ahorrar tokens |

### Disparadores automáticos integrados en CLAUDE.md

Claude usa los scripts automáticamente cuando detecta estas intenciones:

| Lo que decís | Script que se ejecuta |
|---|---|
| "backlog / qué sigue / próximo issue" | `gh-backlog.sh` |
| "audita / PII / secretos" | `audit-pii.sh` + `audit-secrets.sh` |
| "explícame el proyecto / estructura" | `project-map.sh` |
| "quiero commitear / qué cambié" | `changes-summary.sh` + `commit-ready.sh` |
| "CI falló / tests fallaron" | `ci-status.sh` + `failing-tests.sh` |
| "vulnerabilidades / CVE" | `dep-triage.sh` |
| "schema prisma / modelos DB" | `db-schema.sh` |
| "gdpr / compliance / check completo" | `gdpr-quick-check.sh` |
| "retomemos / dónde quedamos" | `load-context.sh` (handoff + memorias + capacidades) |
| "¿qué llama a X? / impacto de cambiar X" | tools MCP de codegraph |

---

## Estructura del repositorio

```
claude-code-toolkit/
├── install.sh                 # Instalador principal — ejecutar esto
├── bin/
│   └── rtk                    # Binario RTK (x86-64 Linux)
├── scripts/                   # Se instalan en ~/.claude/scripts/
│   ├── gh-backlog.sh
│   ├── handoff-create.sh
│   ├── load-context.sh
│   └── ... (26 scripts)
├── commands/                  # Se instalan en ~/.claude/commands/
│   ├── session-start.md
│   ├── handoff.md
│   └── ... (28 comandos)
└── config/                    # Se instalan en ~/.claude/
    ├── CLAUDE.md
    ├── claude-issues.md
    ├── claude-toolkit.md
    └── RTK.md
```

---

## Requisitos

- macOS (con [Homebrew](https://brew.sh)) o Ubuntu 20.04+ / WSL2
- Claude Code CLI instalado
- `git`, `jq` (el instalador los instala si faltan)
- `gh` (GitHub CLI) — opcional, para funciones de issues/PRs
- `node` / `npm` — para CodeGraph (el instalador lo instala via npm si está disponible)

---

## Actualizar

```bash
cd claude-code-toolkit
git pull
bash install.sh
```

El instalador hace backup antes de sobreescribir.

---

## Desinstalar

El instalador guarda un backup en `~/.claude/backups/toolkit-install-FECHA/`. Para restaurar:

```bash
cp ~/.claude/backups/toolkit-install-FECHA/settings.json ~/.claude/settings.json
cp ~/.claude/backups/toolkit-install-FECHA/CLAUDE.md ~/.claude/CLAUDE.md
rm -rf ~/.claude/scripts ~/.claude/commands
rm ~/.local/bin/rtk
```

---

## Licencia

MIT
