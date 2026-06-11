# Claude Code Toolkit v2 — Handoff + Load-context + Codegraph

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extender claude-code-toolkit con gestión de handoff entre sesiones (un archivo por sesión con timestamp, guardado en `.claude/handoff/` DENTRO de cada repo, excluido de git), carga de contexto enriquecida al inicio (handoff anterior + memorias + codegraph), y configuración automática de codegraph MCP — con soporte dual macOS (Homebrew) y Ubuntu/WSL2 (apt).

**Architecture:** Dos scripts nuevos (`handoff-create.sh`, `load-context.sh`) se integran en los hooks Stop y SessionStart existentes. Funcionan en **cualquier repo git** (sin filtro haefrain/*). `handoff-create.sh` genera `{repo}/.claude/handoff/YYYYMMDD-HHMM.md` al cerrar y registra `.claude/handoff/` en `.git/info/exclude` (ignore local — no modifica archivos del repo); `load-context.sh` carga el handoff más reciente al abrir junto con memorias del proyecto y un resumen de codegraph. El instalador detecta el OS y corre `codegraph install --target=claude-code -y` para configurar el MCP server automáticamente. El backlog automático (gh-backlog) conserva su filtro haefrain/* porque depende del workflow de issues propio.

**Tech Stack:** Bash 5+, jq, git, codegraph 0.9.7 (`@colbymchenry/codegraph`), Claude Code hooks (SessionStart / Stop), Homebrew (macOS) / apt (Linux)

**Decisiones clave (confirmadas con el usuario):**
- Handoff por sesión con timestamp (no acumulado por repo)
- Histórico DENTRO de `.claude/handoff/` de cada repo — portable con el proyecto, visible al hacer `ls`
- Nunca se sube a git: se usa `.git/info/exclude` (ignore local) en vez de tocar el `.gitignore` del proyecto
- Usable en cualquier repo git, no solo haefrain/*
- Componentes 100% nativos de Claude Code: slash commands `.md`, hooks de settings.json, MCP server

---

## Mapa de archivos

| Acción | Archivo | Responsabilidad |
|---|---|---|
| **Create** | `scripts/handoff-create.sh` | Genera `{repo}/.claude/handoff/YYYYMMDD-HHMM.md` al cerrar sesión + exclude local de git |
| **Create** | `scripts/load-context.sh` | Carga handoff anterior + memorias del proyecto + codegraph al abrir |
| **Create** | `commands/handoff.md` | Slash command `/handoff` — genera handoff manual |
| **Create** | `commands/load-context.md` | Slash command `/load-context` — recarga contexto |
| **Create** | `commands/codegraph-init.md` | Slash command `/codegraph-init` — inicializa índice |
| **Modify** | `scripts/stop-hook.sh` | Llamar `handoff-create.sh` SIEMPRE (antes del filtro haefrain) |
| **Modify** | `scripts/session-start-hook.sh` | Llamar `load-context.sh` antes del backlog |
| **Modify** | `install.sh` | Detección de OS (macOS/Linux) + paso de codegraph MCP |
| **Modify** | `config/claude-toolkit.md` | Documentar los scripts nuevos y sus disparadores |
| **Modify** | `README.md` | Actualizar tabla de scripts y sección de hooks |

---

## Task 0: Clonar el repositorio

**Files:**
- Create: `/Users/haefrain/AmericaProjects/claude-code-toolkit/` (todo el repo)

- [ ] **Step 1: Clonar via SSH**

```bash
cd /Users/haefrain/AmericaProjects
git clone git@github.com:haefrain/claude-code-toolkit.git
cd claude-code-toolkit
```

- [ ] **Step 2: Verificar la estructura clonada**

```bash
ls scripts/ commands/ config/
```

Expected output (fragmento):
```
scripts/:
audit-pii.sh  commit-ready.sh  post-tool-hook.sh  session-start-hook.sh  stop-hook.sh ...

commands/:
session-start.md  backlog.md ...

config/:
CLAUDE.md  claude-toolkit.md  RTK.md  claude-issues.md
```

- [ ] **Step 3: Crear directorio de documentación y copiar este plan**

```bash
mkdir -p docs/superpowers/plans
cp /Users/haefrain/.claude/plans/puedes-clonar-este-proyecot-delightful-planet.md \
   docs/superpowers/plans/2026-06-11-toolkit-v2-handoff-loadcontext-codegraph.md
```

---

## Task 1: Crear `scripts/handoff-create.sh`

**Files:**
- Create: `scripts/handoff-create.sh`

- [ ] **Step 1: Comportamiento esperado**

El script debe:
1. Leer stdin JSON con `transcript_path` (igual que `stop-hook.sh`)
2. Funcionar en **cualquier repo git** — salir en silencio solo si el cwd no es un repo git
3. Generar `{repo}/.claude/handoff/YYYYMMDD-HHMM.md` con branch, commits recientes, archivos modificados e issues mencionados
4. Registrar `.claude/handoff/` en `.git/info/exclude` para que git lo ignore SIN modificar el `.gitignore` del proyecto
5. Conservar solo los 10 handoffs más recientes

- [ ] **Step 2: Crear el script**

```bash
cat > scripts/handoff-create.sh << 'EOF'
#!/usr/bin/env bash
# handoff-create.sh — Genera un archivo de handoff al finalizar la sesión.
# Llamado desde stop-hook.sh (Stop hook de Claude Code). Funciona en cualquier repo git.
# Output: {repo}/.claude/handoff/YYYYMMDD-HHMM.md (excluido de git via .git/info/exclude)
set -euo pipefail

input=$(cat)
transcript=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null || echo "")

# ── Requiere estar en un repo git (cualquiera, no solo haefrain) ──
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "$git_root" ]] && exit 0

# ── Directorio de handoffs DENTRO del repo ─────────────────────
HANDOFF_DIR="$git_root/.claude/handoff"
mkdir -p "$HANDOFF_DIR"

# ── Excluir de git SIN tocar el .gitignore del proyecto ────────
# .git/info/exclude es un ignore local: git lo respeta pero no es un archivo del repo.
git_dir=$(git -C "$git_root" rev-parse --git-dir 2>/dev/null || true)
if [[ -n "$git_dir" ]]; then
  # git-dir puede ser relativo; normalizar
  [[ "$git_dir" != /* ]] && git_dir="$git_root/$git_dir"
  exclude_file="$git_dir/info/exclude"
  mkdir -p "$(dirname "$exclude_file")"
  if ! grep -qx '\.claude/handoff/' "$exclude_file" 2>/dev/null; then
    echo '.claude/handoff/' >> "$exclude_file"
  fi
fi

timestamp=$(date +%Y%m%d-%H%M)
handoff_file="$HANDOFF_DIR/${timestamp}.md"

# ── Recopilar información ──────────────────────────────────────
remote=$(git -C "$git_root" remote get-url origin 2>/dev/null || echo "(sin remote)")
branch=$(git -C "$git_root" branch --show-current 2>/dev/null || echo "unknown")

# 1. Archivos modificados (staged + unstaged)
modified_files=$(git -C "$git_root" diff --name-only HEAD 2>/dev/null | head -20 || true)
[[ -z "$modified_files" ]] && modified_files=$(git -C "$git_root" diff --name-only HEAD~1 2>/dev/null | head -20 || true)

# 2. Issues mencionados en el transcript
mentioned_issues=""
if [[ -n "$transcript" && -f "$transcript" ]]; then
  mentioned_issues=$(grep -oE '#[0-9]{2,4}' "$transcript" 2>/dev/null | sort -u | head -10 || true)
fi

# 3. Commits recientes de la sesión (últimas 2 horas; fallback: últimos 3)
recent_commits=$(git -C "$git_root" log --oneline --since="2 hours ago" --format="- %h %s" 2>/dev/null | head -10 || true)
[[ -z "$recent_commits" ]] && recent_commits=$(git -C "$git_root" log --oneline -3 --format="- %h %s" 2>/dev/null || true)

# ── Generar el archivo de handoff ─────────────────────────────
{
  echo "# Handoff — $(basename "$git_root") — ${timestamp}"
  echo ""
  echo "**Branch:** \`${branch}\`"
  echo "**Remote:** ${remote}"
  echo ""
  echo "## Lo que se trabajó esta sesión"
  echo ""
  if [[ -n "$recent_commits" ]]; then
    echo "**Commits recientes:**"
    echo "$recent_commits"
  else
    echo "_Sin commits en esta sesión_"
  fi
  echo ""
  echo "## Archivos modificados"
  echo ""
  if [[ -n "$modified_files" ]]; then
    echo "$modified_files" | sed 's/^/- /'
  else
    echo "_Sin cambios detectados en el working tree_"
  fi
  echo ""
  echo "## Issues trabajados"
  echo ""
  if [[ -n "$mentioned_issues" ]]; then
    echo "$mentioned_issues" | sed 's/^/- /'
  else
    echo "_No se mencionaron issues_"
  fi
  echo ""
  echo "## Próxima sesión"
  echo ""
  echo "1. Branch activo al cerrar: \`${branch}\`"
  echo "2. Revisá el backlog con \`/session-start\` o \`/backlog\`"
  echo "3. Si hay cambios sin commitear, revisá con \`/changes-summary\`"
  echo ""
  echo "---"
  echo "_Generado automáticamente por handoff-create.sh · ${timestamp}_"
} > "$handoff_file"

# ── Limpieza: retener solo los 10 handoffs más recientes ──────
ls -t "$HANDOFF_DIR"/*.md 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

echo "<!-- handoff-create: guardado en $handoff_file -->"
EOF
chmod +x scripts/handoff-create.sh
```

- [ ] **Step 3: Verificar sintaxis**

```bash
bash -n scripts/handoff-create.sh
```

Expected: sin output

- [ ] **Step 4: Prueba de integración — repo haefrain**

```bash
echo '{"transcript_path":""}' | \
  CLAUDE_PROJECT_DIR=/Users/haefrain/AmericaProjects/laravel-saas-api \
  bash scripts/handoff-create.sh
```

Expected output:
```
<!-- handoff-create: guardado en /Users/haefrain/AmericaProjects/laravel-saas-api/.claude/handoff/20260611-HHMM.md -->
```

- [ ] **Step 5: Verificar archivo, exclude y que git lo ignora**

```bash
ls -la /Users/haefrain/AmericaProjects/laravel-saas-api/.claude/handoff/
grep handoff /Users/haefrain/AmericaProjects/laravel-saas-api/.git/info/exclude
git -C /Users/haefrain/AmericaProjects/laravel-saas-api status --porcelain | grep -c handoff || echo "IGNORADO ✅"
```

Expected: archivo .md presente, línea `.claude/handoff/` en exclude, y "IGNORADO ✅" (git no lo ve)

- [ ] **Step 6: Prueba en repo NO-haefrain (cualquier repo git)**

```bash
tmpdir=$(mktemp -d) && git -C "$tmpdir" init -q && touch "$tmpdir/x" && git -C "$tmpdir" add . && git -C "$tmpdir" commit -qm init
echo '{"transcript_path":""}' | CLAUDE_PROJECT_DIR="$tmpdir" bash scripts/handoff-create.sh
ls "$tmpdir/.claude/handoff/"
rm -rf "$tmpdir"
```

Expected: handoff generado también en repo sin remote haefrain

- [ ] **Step 7: Commit**

```bash
git add scripts/handoff-create.sh
git commit -m "feat: add handoff-create.sh — per-session handoff inside repo .claude/, git-excluded"
```

---

## Task 2: Crear `scripts/load-context.sh`

**Files:**
- Create: `scripts/load-context.sh`

- [ ] **Step 1: Comportamiento esperado**

El script debe:
1. Buscar el handoff más reciente en `{repo}/.claude/handoff/*.md`
2. Leer memorias del proyecto desde `~/.claude/projects/{encoded-path}/memory/*.md` (el encoding de Claude Code conserva el guion inicial: `/Users/foo/bar` → `-Users-foo-bar`)
3. Consultar `codegraph status` y `codegraph context` si hay `.codegraph/` en el proyecto
4. Emitir markdown para inyectar en el contexto de Claude
5. Salir en silencio si no hay nada que inyectar

- [ ] **Step 2: Crear el script**

```bash
cat > scripts/load-context.sh << 'EOF'
#!/usr/bin/env bash
# load-context.sh — Carga contexto enriquecido al inicio de sesión.
# Llamado desde session-start-hook.sh (SessionStart hook). Funciona en cualquier repo git.
# Inyecta: handoff anterior + memorias del proyecto + codegraph status.
set -euo pipefail

cwd="${CLAUDE_PROJECT_DIR:-${1:-$PWD}}"
git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)

# ── 1. Cargar handoff de la sesión anterior (desde el repo) ────
handoff_content=""
if [[ -n "$git_root" && -d "$git_root/.claude/handoff" ]]; then
  last_handoff=$(ls -t "$git_root/.claude/handoff"/*.md 2>/dev/null | head -1 || true)
  if [[ -n "$last_handoff" && -f "$last_handoff" ]]; then
    handoff_content=$(cat "$last_handoff")
  fi
fi

# ── 2. Cargar memorias del proyecto (globales de Claude Code) ──
memory_content=""
PROJECT_MEMORY_BASE="$HOME/.claude/projects"
if [[ -d "$PROJECT_MEMORY_BASE" ]]; then
  # Claude Code codifica el path reemplazando / y . por -: /Users/foo/bar → -Users-foo-bar
  encoded_path=$(echo "$cwd" | tr '/.' '--')
  memory_dir="$PROJECT_MEMORY_BASE/$encoded_path/memory"
  if [[ -d "$memory_dir" ]]; then
    while IFS= read -r mf; do
      [[ -f "$mf" ]] || continue
      desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "$mf" 2>/dev/null || true)
      [[ -n "$desc" ]] && memory_content="${memory_content}- ${desc}\n"
    done < <(ls "$memory_dir"/*.md 2>/dev/null || true)
  fi
fi

# ── 3. Consultar codegraph (solo si hay índice) ───────────────
codegraph_status=""
codegraph_context=""
if command -v codegraph >/dev/null 2>&1 && [[ -n "$git_root" && -d "$git_root/.codegraph" ]]; then
  codegraph_status=$(codegraph status "$git_root" 2>/dev/null | head -8 || true)
  codegraph_context=$(codegraph context --path "$git_root" "retomando trabajo en sesión" 2>/dev/null | head -40 || true)
fi

# ── Salir en silencio si no hay nada que inyectar ─────────────
if [[ -z "$handoff_content" && -z "$memory_content" && -z "$codegraph_status" ]]; then
  exit 0
fi

# ── Emitir el contexto enriquecido ─────────────────────────────
echo "<!-- load-context: contexto enriquecido cargado -->"
echo ""

if [[ -n "$handoff_content" ]]; then
  echo "## Continuación de sesión anterior"
  echo ""
  echo "$handoff_content"
  echo ""
  echo "---"
  echo ""
fi

if [[ -n "$memory_content" ]]; then
  echo "## Memorias del proyecto"
  echo ""
  printf "%b" "$memory_content"
  echo ""
  echo "---"
  echo ""
fi

if [[ -n "$codegraph_status" ]]; then
  echo "## CodeGraph: estado del índice"
  echo ""
  echo "$codegraph_status"
  if [[ -n "$codegraph_context" ]]; then
    echo ""
    echo "$codegraph_context"
  fi
  echo ""
  echo "---"
  echo ""
fi
EOF
chmod +x scripts/load-context.sh
```

- [ ] **Step 3: Verificar sintaxis**

```bash
bash -n scripts/load-context.sh
```

Expected: sin output

- [ ] **Step 4: Prueba — directorio sin repo git (debe ser silencioso)**

```bash
CLAUDE_PROJECT_DIR=/tmp bash scripts/load-context.sh
```

Expected: sin output

- [ ] **Step 5: Prueba — repo con handoff existente (del Task 1)**

```bash
CLAUDE_PROJECT_DIR=/Users/haefrain/AmericaProjects/laravel-saas-api bash scripts/load-context.sh
```

Expected: markdown con sección "Continuación de sesión anterior" mostrando el handoff del Task 1

- [ ] **Step 6: Commit**

```bash
git add scripts/load-context.sh
git commit -m "feat: add load-context.sh — enriched session start with handoff + memory + codegraph"
```

---

## Task 3: Modificar `scripts/stop-hook.sh`

**Files:**
- Modify: `scripts/stop-hook.sh`

**Importante:** el handoff debe generarse en CUALQUIER repo, pero el chequeo de issues abiertos sigue siendo solo haefrain/*. Por eso la llamada a `handoff-create.sh` va ANTES del filtro haefrain.

- [ ] **Step 1: Ver el archivo actual**

```bash
cat scripts/stop-hook.sh
```

El archivo actual: lee stdin, detecta repo haefrain (sale si no es), busca issues en el transcript, lista los abiertos.

- [ ] **Step 2: Reemplazar el contenido completo del archivo**

```bash
cat > scripts/stop-hook.sh << 'EOF'
#!/usr/bin/env bash
# stop-hook.sh — Stop hook.
# 1. SIEMPRE: genera handoff de sesión (cualquier repo git) via handoff-create.sh.
# 2. Solo repos haefrain/*: recuerda cerrar issues mencionados en la sesión.
# Input stdin JSON: { "stop_hook_active": true, "transcript_path": "..." }
set -euo pipefail

input=$(cat)
transcript=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null || echo "")

# ── 1. Handoff de sesión (cualquier repo git) ─────────────────
echo "$input" | "$(dirname "$0")/handoff-create.sh" 2>/dev/null || true

# ── 2. Recordatorio de issues (solo haefrain/*) ───────────────
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
remote=$(git -C "$cwd" remote get-url origin 2>/dev/null || true)
[[ "$remote" =~ github\.com[:/]haefrain/ ]] || exit 0

repo=""
[[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]] && repo="${BASH_REMATCH[1]}"

# Buscar issues mencionados en el transcript (si está disponible)
mentioned_issues=""
if [[ -n "$transcript" && -f "$transcript" ]]; then
  mentioned_issues=$(grep -oE '#[0-9]{2,4}' "$transcript" 2>/dev/null | sort -u | sed 's/#//' | head -10 || true)
fi

if [[ -z "$mentioned_issues" ]]; then
  exit 0
fi

# Verificar cuáles siguen abiertos
open_mentioned=""
for n in $mentioned_issues; do
  state=$(gh issue view "$n" --repo "$repo" --json state -q .state 2>/dev/null || echo "")
  [[ "$state" == "OPEN" ]] && open_mentioned="$open_mentioned #$n"
done

open_mentioned=$(echo "$open_mentioned" | xargs)
[[ -z "$open_mentioned" ]] && exit 0

echo "<!-- stop-hook: issues abiertos detectados en sesión -->"
echo ""
echo "📋 **Issues mencionados en la sesión que siguen abiertos:** $open_mentioned"
echo "Si completaste el trabajo, cerrá con: \`gh issue close N --repo $repo --reason completed --comment \"...\"\`"
echo "Si no terminaste: agregá un comentario de estado en el issue."

exit 0
EOF
```

- [ ] **Step 3: Verificar sintaxis**

```bash
bash -n scripts/stop-hook.sh
```

Expected: sin output

- [ ] **Step 4: Prueba de integración en repo NO-haefrain**

```bash
tmpdir=$(mktemp -d) && git -C "$tmpdir" init -q && touch "$tmpdir/x" && git -C "$tmpdir" add . && git -C "$tmpdir" commit -qm init
echo '{"stop_hook_active":true,"transcript_path":""}' | CLAUDE_PROJECT_DIR="$tmpdir" bash scripts/stop-hook.sh
ls "$tmpdir/.claude/handoff/"
rm -rf "$tmpdir"
```

Expected: exit 0, handoff generado en el repo temporal (demuestra que funciona en cualquier repo)

- [ ] **Step 5: Prueba en repo haefrain**

```bash
echo '{"stop_hook_active":true,"transcript_path":""}' | \
  CLAUDE_PROJECT_DIR=/Users/haefrain/AmericaProjects/laravel-saas-api \
  bash scripts/stop-hook.sh 2>/dev/null
ls -t /Users/haefrain/AmericaProjects/laravel-saas-api/.claude/handoff/ | head -3
```

Expected: handoff nuevo + (si hay issues en transcript, recordatorio — aquí no hay, así que solo el handoff)

- [ ] **Step 6: Commit**

```bash
git add scripts/stop-hook.sh
git commit -m "feat: stop-hook generates handoff in any git repo before haefrain-only issue check"
```

---

## Task 4: Modificar `scripts/session-start-hook.sh`

**Files:**
- Modify: `scripts/session-start-hook.sh`

- [ ] **Step 1: Reemplazar el contenido completo del archivo**

```bash
cat > scripts/session-start-hook.sh << 'EOF'
#!/usr/bin/env bash
# session-start-hook.sh — se ejecuta vía hook SessionStart de Claude Code.
# 1. Carga contexto enriquecido (handoff anterior + memorias + codegraph) en CUALQUIER repo.
# 2. Solo en repos haefrain/*: carga el backlog automáticamente.
set -euo pipefail

# ── 1. Contexto enriquecido (todos los proyectos) ─────────────
"$(dirname "$0")/load-context.sh" 2>/dev/null || true

# ── 2. Backlog automático (solo repos haefrain/*) ─────────────
remote=$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" remote get-url origin 2>/dev/null || true)

if [[ ! "$remote" =~ github\.com[:/]haefrain/ ]]; then
  exit 0  # silencio si no es repo de haefrain
fi

repo=""
if [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
  repo="${BASH_REMATCH[1]}"
fi

echo "<!-- SessionStart hook: backlog cargado automáticamente -->"
echo ""
echo "# Contexto auto-cargado para sesión en $repo"
echo ""
"$(dirname "$0")/gh-backlog.sh" "$repo" 2>/dev/null || echo "(gh-backlog falló silenciosamente)"
echo ""
echo "---"
echo "Tip: usa /pick-next para el próximo issue sugerido, o /session-start para refrescar."
EOF
```

- [ ] **Step 2: Verificar sintaxis**

```bash
bash -n scripts/session-start-hook.sh
```

Expected: sin output

- [ ] **Step 3: Prueba — directorio sin repo (silencioso)**

```bash
CLAUDE_PROJECT_DIR=/tmp bash scripts/session-start-hook.sh 2>/dev/null
```

Expected: sin output

- [ ] **Step 4: Prueba — repo haefrain con handoff**

```bash
CLAUDE_PROJECT_DIR=/Users/haefrain/AmericaProjects/laravel-saas-api bash scripts/session-start-hook.sh 2>/dev/null
```

Expected:
```
<!-- load-context: contexto enriquecido cargado -->

## Continuación de sesión anterior
...
<!-- SessionStart hook: backlog cargado automáticamente -->
...
```

- [ ] **Step 5: Commit**

```bash
git add scripts/session-start-hook.sh
git commit -m "feat: session-start-hook loads enriched context in any repo before backlog"
```

---

## Task 5: Crear los tres slash commands nuevos

**Files:**
- Create: `commands/handoff.md`
- Create: `commands/load-context.md`
- Create: `commands/codegraph-init.md`

Son slash commands nativos de Claude Code: archivos `.md` con frontmatter YAML que se instalan en `~/.claude/commands/`.

- [ ] **Step 1: Crear commands/handoff.md**

```bash
cat > commands/handoff.md << 'EOF'
---
description: Genera manualmente un archivo de handoff con el estado actual de la sesión en .claude/handoff/ del repo.
argument-hint: ""
---

Ejecuta los siguientes comandos y presenta el resultado:

1. Genera el handoff:
```bash
echo '{"transcript_path":""}' | bash ~/.claude/scripts/handoff-create.sh
```

2. Muestra el contenido generado (el handoff queda en `.claude/handoff/` dentro del repo actual):
```bash
cat "$(git rev-parse --show-toplevel)/.claude/handoff/$(ls -t "$(git rev-parse --show-toplevel)/.claude/handoff/" | head -1)"
```

Presenta:
- La ruta del archivo generado
- El contenido del handoff (branch, commits, archivos, issues)
- Confirmación: "Handoff guardado en .claude/handoff/ (excluido de git). Al iniciar la próxima sesión se cargará automáticamente."
EOF
```

- [ ] **Step 2: Crear commands/load-context.md**

```bash
cat > commands/load-context.md << 'EOF'
---
description: Recarga el contexto enriquecido en la sesión actual — handoff anterior, memorias del proyecto y codegraph.
argument-hint: ""
---

Ejecuta y presenta el output:

```bash
bash ~/.claude/scripts/load-context.sh
```

Si hay output, preséntalo como contexto activo.
Si no hay output (sin handoff previo), muestra:
"No hay contexto previo para este proyecto. Usá `/session-start` para cargar el backlog o `/codegraph-init` para inicializar el índice de código."
EOF
```

- [ ] **Step 3: Crear commands/codegraph-init.md**

```bash
cat > commands/codegraph-init.md << 'EOF'
---
description: Inicializa y construye el índice CodeGraph en el proyecto actual para habilitar inteligencia de código en las sesiones.
argument-hint: ""
---

Ejecuta en secuencia:

```bash
codegraph init .
codegraph index .
codegraph status .
```

Presenta:
- Cuántos archivos y símbolos fueron indexados
- El estado final del índice (`codegraph status`)
- Confirmación: "CodeGraph inicializado. Las próximas sesiones tendrán inteligencia de código disponible en `/load-context`."

Si `codegraph` no está instalado, muestra:
"CodeGraph no está instalado. Corré `npm install -g @colbymchenry/codegraph` o reinstalá el toolkit con `bash install.sh`."
EOF
```

- [ ] **Step 4: Verificar los tres archivos**

```bash
head -5 commands/handoff.md commands/load-context.md commands/codegraph-init.md
```

Expected: frontmatter YAML visible en los tres

- [ ] **Step 5: Commit**

```bash
git add commands/handoff.md commands/load-context.md commands/codegraph-init.md
git commit -m "feat: add /handoff, /load-context, /codegraph-init slash commands"
```

---

## Task 6: Modificar `install.sh` — soporte macOS + codegraph

**Files:**
- Modify: `install.sh`

Tres modificaciones independientes.

### 6a — Detección de OS y función `pkg_install`

- [ ] **Step 1: Añadir detección de OS después de las funciones de color**

Localizar en install.sh el bloque:
```bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
fail() { echo -e "${RED}❌ $*${NC}"; exit 1; }
step() { echo -e "\n${BOLD}▶ $*${NC}"; }
```

Añadir inmediatamente después:

```bash
# ── Detección de OS ──────────────────────────────────────────────
OS_TYPE="linux"
[[ "$(uname -s)" == "Darwin" ]] && OS_TYPE="macos"

pkg_install() {
  local pkg="$1"
  if [[ "$OS_TYPE" == "macos" ]]; then
    if command -v brew >/dev/null 2>&1; then
      brew install "$pkg" >/dev/null 2>&1 && ok "$pkg instalado (brew)" \
        || warn "brew install $pkg falló — instalalo manualmente: brew install $pkg"
    else
      fail "Homebrew no encontrado. Instalalo en https://brew.sh y volvé a ejecutar install.sh"
    fi
  else
    sudo apt-get install -y "$pkg" >/dev/null 2>&1 && ok "$pkg instalado" \
      || fail "No se pudo instalar $pkg. Corré: sudo apt install $pkg"
  fi
}
```

### 6b — Reemplazar `check_cmd` para usar `pkg_install`

- [ ] **Step 2: Reemplazar la función `check_cmd` entera**

Por:

```bash
check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 ($(command -v "$1"))"
  else
    warn "$1 no encontrado — instalando..."
    case "$1" in
      jq|git|tree)
        pkg_install "$1" || true
        ;;
      gh)
        if [[ "$OS_TYPE" == "macos" ]]; then
          pkg_install "gh" || warn "gh no instalado — funcionalidad de issues/PRs limitada"
        else
          info "Instalando GitHub CLI (gh) via apt..."
          (type -p curl >/dev/null || sudo apt install curl -y) \
          && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
             | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
          && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
          && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
             | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
          && sudo apt update >/dev/null 2>&1 \
          && sudo apt install gh -y >/dev/null 2>&1 \
          && ok "gh instalado" \
          || warn "gh no instalado — funcionalidad de issues/PRs limitada"
        fi
        ;;
    esac
  fi
}
```

**Nota RTK:** el binario incluido en `bin/rtk` es x86-64 Linux. En macOS el paso de RTK del instalador usa el install script remoto de rtk-ai que detecta la plataforma; si falla en macOS, debe quedar como `warn` (no `fail`) para que el resto del toolkit se instale igual. Verificar que el bloque RTK existente use `warn` en su rama de fallo en macOS:

```bash
# En el bloque RTK existente, si OS_TYPE=macos y la instalación falla:
# warn "RTK no disponible para esta plataforma — el resto del toolkit funciona sin RTK"
# (en vez de fail)
```

Localizar el bloque RTK y cambiar la línea:
```bash
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh \
    || fail "No se pudo instalar RTK. Intentá manualmente: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
```
Por:
```bash
  if ! curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh; then
    if [[ "$OS_TYPE" == "macos" ]]; then
      warn "RTK no se pudo instalar en macOS — el resto del toolkit funciona sin RTK"
    else
      fail "No se pudo instalar RTK. Intentá manualmente: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
    fi
  fi
```

### 6c — Añadir paso de codegraph MCP

- [ ] **Step 3: Añadir el paso de codegraph ANTES de la sección "VERIFICACIÓN FINAL"**

Localizar la línea:
```bash
# ────────────────────────────────────────────────
# 8. VERIFICACIÓN FINAL
```

Insertar antes:

```bash
# ────────────────────────────────────────────────
# 8. CODEGRAPH MCP SERVER
# ────────────────────────────────────────────────
step "Configurando CodeGraph MCP"

if command -v codegraph >/dev/null 2>&1; then
  ok "codegraph ya instalado: $(codegraph --version)"
else
  if command -v npm >/dev/null 2>&1; then
    info "Instalando codegraph via npm..."
    npm install -g @colbymchenry/codegraph >/dev/null 2>&1 \
      && ok "codegraph instalado: $(codegraph --version 2>/dev/null || echo 'ok')" \
      || warn "npm install de codegraph falló — instalalo manualmente: npm install -g @colbymchenry/codegraph"
  else
    warn "npm no encontrado — instalá Node.js y luego: npm install -g @colbymchenry/codegraph"
  fi
fi

if command -v codegraph >/dev/null 2>&1; then
  info "Registrando codegraph como MCP server en Claude Code..."
  codegraph install --target=claude-code --location=global -y 2>/dev/null \
    && ok "CodeGraph MCP configurado en Claude Code" \
    || warn "codegraph install falló — corré manualmente: codegraph install --target=claude-code -y"
fi
```

(Renumerar el comentario de "VERIFICACIÓN FINAL" a 9 si se desea consistencia — opcional, es solo un comentario.)

- [ ] **Step 4: Añadir checks de codegraph en la "VERIFICACIÓN FINAL"**

Después de la línea:
```bash
check "Hook Stop configurado"          "jq -e '.hooks.Stop' $CLAUDE_DIR/settings.json"
```

Añadir:
```bash
check "CodeGraph instalado"            "codegraph --version"
```

(No verificar `.mcpServers.codegraph` en settings.json: `codegraph install` puede registrarlo en `~/.claude.json` u otra ubicación según la versión — el check de binario es suficiente y estable.)

- [ ] **Step 5: Verificar sintaxis del install.sh completo**

```bash
bash -n install.sh
```

Expected: sin output

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "feat(install): macOS/Homebrew support + codegraph MCP auto-install"
```

---

## Task 7: Actualizar `config/claude-toolkit.md`

**Files:**
- Modify: `config/claude-toolkit.md`

- [ ] **Step 1: Añadir a la tabla "Disparadores automáticos OBLIGATORIOS"**

```markdown
| retomemos / continúa / nueva sesión | `load-context.sh` (automático via SessionStart hook) |
| genera handoff / cerrar sesión / guardar estado | `/handoff` (también automático via Stop hook) |
| inicializar codegraph / indexar proyecto | `/codegraph-init` |
```

- [ ] **Step 2: Añadir subsección a "Scripts"**

```markdown
**Handoff & Contexto**
- `handoff-create.sh` — genera `{repo}/.claude/handoff/YYYYMMDD-HHMM.md` al cerrar sesión (cualquier repo git, excluido de git via .git/info/exclude). Retiene los 10 más recientes.
- `load-context.sh` — carga handoff anterior + memorias del proyecto + codegraph al iniciar. Silencioso si no hay nada.
```

- [ ] **Step 3: Añadir los nuevos commands a la lista de slash commands**

```markdown
`/handoff` `/load-context` `/codegraph-init`
```

- [ ] **Step 4: Commit**

```bash
git add config/claude-toolkit.md
git commit -m "docs: update claude-toolkit.md with handoff/load-context/codegraph entries"
```

---

## Task 8: Actualizar `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Añadir a la tabla de Scripts bash**

```markdown
| `handoff-create.sh` | Genera `{repo}/.claude/handoff/YYYYMMDD-HHMM.md` al cerrar sesión (excluido de git) |
| `load-context.sh` | Carga handoff anterior + memorias + codegraph al iniciar |
```

- [ ] **Step 2: Añadir a la lista de Slash Commands**

```
`/handoff` `/load-context` `/codegraph-init`
```

- [ ] **Step 3: Actualizar la tabla de Hooks (reemplazar filas SessionStart y Stop)**

```markdown
| `SessionStart` | Al abrir Claude Code en cualquier repo | Carga handoff anterior + memorias + codegraph; en repos haefrain/* también el backlog |
| `Stop` | Al terminar el turno | Genera handoff de sesión en `.claude/handoff/` del repo; en haefrain/* recuerda cerrar issues |
```

- [ ] **Step 4: Añadir sección "CodeGraph" después de la sección RTK**

```markdown
### CodeGraph — Inteligencia de código
Servidor MCP que indexa el grafo de símbolos del proyecto. Claude lo consulta automáticamente al cargar contexto.

```bash
/codegraph-init            # Inicializar índice en el proyecto actual
codegraph status .         # Ver estado del índice
codegraph query foo        # Buscar símbolo "foo"
codegraph context "tarea"  # Contexto relevante para una tarea
```

### Handoff entre sesiones
Al cerrar cada sesión, el Stop hook guarda un resumen en `.claude/handoff/YYYYMMDD-HHMM.md` **dentro del repo** (excluido de git automáticamente via `.git/info/exclude`). Al abrir la próxima sesión, SessionStart lo carga junto con las memorias del proyecto. Funciona en cualquier repo git.
```

- [ ] **Step 5: Actualizar "Requisitos" y "Instalación rápida"**

Requisitos — añadir:
```markdown
- `node` / `npm` — para codegraph (`npm install -g @colbymchenry/codegraph`)
```

Título de instalación — cambiar "## Instalación rápida (Ubuntu / WSL)" por:
```markdown
## Instalación rápida (macOS / Ubuntu / WSL)
```

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: update README with handoff, load-context and codegraph features"
```

---

## Task 9: Verificación final de integración

- [ ] **Step 1: Sintaxis de todos los scripts tocados**

```bash
for f in install.sh scripts/handoff-create.sh scripts/load-context.sh scripts/stop-hook.sh scripts/session-start-hook.sh; do
  bash -n "$f" && echo "✅ $f" || echo "❌ $f SYNTAX ERROR"
done
```

Expected: 5 líneas con ✅

- [ ] **Step 2: Flujo completo simulado — repo cualquiera**

```bash
tmpdir=$(mktemp -d) && git -C "$tmpdir" init -q && touch "$tmpdir/x" && git -C "$tmpdir" add . && git -C "$tmpdir" commit -qm init

# Stop → genera handoff
echo '{"stop_hook_active":true,"transcript_path":""}' | CLAUDE_PROJECT_DIR="$tmpdir" bash scripts/stop-hook.sh
# SessionStart → carga handoff
CLAUDE_PROJECT_DIR="$tmpdir" bash scripts/session-start-hook.sh

# git NO ve el handoff
git -C "$tmpdir" status --porcelain | grep handoff && echo "❌ GIT LO VE" || echo "✅ git lo ignora"
rm -rf "$tmpdir"
```

Expected: handoff generado, contexto cargado con "Continuación de sesión anterior", y "✅ git lo ignora"

- [ ] **Step 3: Flujo en repo haefrain real**

```bash
echo '{"stop_hook_active":true,"transcript_path":""}' | \
  CLAUDE_PROJECT_DIR=/Users/haefrain/AmericaProjects/laravel-saas-api bash scripts/stop-hook.sh 2>/dev/null
CLAUDE_PROJECT_DIR=/Users/haefrain/AmericaProjects/laravel-saas-api bash scripts/session-start-hook.sh 2>/dev/null | head -30
```

Expected: handoff + memorias + backlog en el output

- [ ] **Step 4: Commit final del plan y push**

```bash
git add docs/superpowers/plans/2026-06-11-toolkit-v2-handoff-loadcontext-codegraph.md
git commit -m "docs: add implementation plan for toolkit v2"
git push origin main
```

---

## Verificación end-to-end (post-instalación)

Después de ejecutar `bash install.sh` en el sistema destino:

1. **Hooks registrados:**
   ```bash
   jq '.hooks | keys' ~/.claude/settings.json
   # Expected: ["PostToolUse","SessionStart","Stop","UserPromptSubmit"]
   ```

2. **Codegraph disponible:**
   ```bash
   codegraph --version   # Expected: 0.9.x
   ```

3. **Scripts instalados:**
   ```bash
   ls ~/.claude/scripts/handoff-create.sh ~/.claude/scripts/load-context.sh
   ```

4. **Flujo real:** abrir Claude Code en CUALQUIER repo git, trabajar, cerrar sesión, verificar que existe `.claude/handoff/YYYYMMDD-HHMM.md` en el repo y que `git status` no lo muestra. Reabrir Claude Code — el handoff aparece en el contexto inicial.

5. **Codegraph:** correr `/codegraph-init` en un proyecto y verificar:
   ```bash
   codegraph status .
   # Expected: índice listo con N símbolos / M archivos
   ```

---

## Adenda (post-aprobación)

Requisito adicional incorporado durante la ejecución: **inventario de capacidades** en `load-context.sh`.
Al iniciar sesión también se inyecta:
- Slash commands, skills y agents del repo (`.claude/commands|skills|agents`)
- MCP servers del repo (`.mcp.json`)
- Plugins globales instalados (`~/.claude/plugins/installed_plugins.json`)
- Conteo de commands/scripts del toolkit global
- Aviso si codegraph está disponible pero sin índice (sugerir `/codegraph-init`)

Hallazgo de seguridad atendido: la versión de codegraph queda pineada (`@0.9.7`) en `install.sh`.
