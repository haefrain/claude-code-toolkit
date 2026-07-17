# Sección 01 — Verificación: Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hook Stop que corre la verificación del repo cuando hubo código editado y bloquea la entrega si falla, con contrato `.claude/verify.sh` por repo, bootstrap `/verify-setup` y lineamientos globales.

**Architecture:** `post-tool-hook.sh` marca las sesiones que editaron código (archivo marcador por `session_id` en `$TMPDIR`); `verify-stop.sh` (nuevo) lee el marcador al Stop, corre el contrato del repo (o fallback barato) y emite `{"decision":"block"}` si falla (máx. 2 bloqueos); `stop-hook.sh` lo invoca primero y reenvía el bloqueo como único stdout. `/verify-setup` bootstrapea el contrato por repo desde plantillas; `install.sh` distribuye todo a `~/.claude/`.

**Tech Stack:** Bash 3.2-compatible (macOS), jq, git. Tests: scripts bash planos en `tests/` (sin frameworks).

**Spec:** `docs/superpowers/specs/2026-07-16-s01-verificacion-design.md`

## Global Constraints

- Bash compatible con macOS 3.2: sin `declare -A`, sin `mapfile`, sin `${var,,}`.
- Los hooks JAMÁS rompen la sesión: todo error interno → `exit 0` silencioso.
- Marcadores por sesión: `${TMPDIR%/}/claude-verify-pending-<session_id>` y `${TMPDIR%/}/claude-verify-attempts-<session_id>` (usar `${TMPDIR:-/tmp}`).
- Anti-loop: `MAX_ATTEMPTS=2` bloqueos por sesión; al tercero se permite parar con `systemMessage`.
- Extensiones que marcan código: `ts|tsx|js|jsx|mjs|cjs|vue|svelte|py|rb|php|go|rs|java|kt|swift|c|cpp|h|cs|sql|prisma|sh`. Nunca: `md|mdx|txt|json|yml|yaml|toml|lock|csv`.
- Fallback sin contrato: SOLO scripts `lint`/`typecheck` de `package.json` o `lint`/`phpstan` de `composer.json`. Nunca tests ni build.
- Salida JSON de hook = ÚNICO stdout (nunca mezclar JSON con texto plano).
- Repo de trabajo: `/Users/haefrain/AmericaProjects/claude-code-toolkit`, rama `s01-verificacion`.
- Mensajes de commit terminan con:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01VYPQzTR7Cb3uL2S9xZK5EF`

---

### Task 1: Harness de tests + marcador de código en post-tool-hook.sh

**Files:**
- Create: `tests/run.sh`
- Create: `tests/test-post-tool-marker.sh`
- Modify: `scripts/post-tool-hook.sh` (insertar tras la línea 14 `[[ -z "$file" ]] && exit 0`)

**Interfaces:**
- Produces: marcador `${TMPDIR%/}/claude-verify-pending-<session_id>` con una ruta de archivo editado por línea, sin duplicados. Lo consume `verify-stop.sh` (Task 2).

- [ ] **Step 1: Escribir el runner de tests**

Crear `tests/run.sh`:

```bash
#!/usr/bin/env bash
# run.sh — corre todos los tests del toolkit (scripts bash planos, sin frameworks).
set -uo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$dir"/test-*.sh; do
  bash "$t" || rc=1
done
if [[ $rc -eq 0 ]]; then echo "✅ Todos los tests pasaron"; else echo "❌ Hay tests fallando"; fi
exit $rc
```

Luego: `chmod +x tests/run.sh`

- [ ] **Step 2: Escribir el test que falla**

Crear `tests/test-post-tool-marker.sh`:

```bash
#!/usr/bin/env bash
# Verifica que post-tool-hook.sh registre archivos de código en el marcador de sesión.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
TMPDIR="$(mktemp -d)"; export TMPDIR
fail() { echo "FAIL(post-tool-marker): $1"; exit 1; }

# 1. Edit de .ts crea marcador con la ruta
echo '{"session_id":"t1","tool_name":"Edit","tool_input":{"file_path":"/x/a.ts"}}' \
  | bash "$SCRIPTS/post-tool-hook.sh" >/dev/null 2>&1
grep -qxF "/x/a.ts" "$TMPDIR/claude-verify-pending-t1" 2>/dev/null || fail "Edit .ts debe crear marcador"

# 2. Edit de .md NO crea marcador
echo '{"session_id":"t2","tool_name":"Edit","tool_input":{"file_path":"/x/a.md"}}' \
  | bash "$SCRIPTS/post-tool-hook.sh" >/dev/null 2>&1
[[ ! -f "$TMPDIR/claude-verify-pending-t2" ]] || fail ".md no debe marcar"

# 3. Mismo archivo dos veces → una sola línea
echo '{"session_id":"t1","tool_name":"Write","tool_input":{"file_path":"/x/a.ts"}}' \
  | bash "$SCRIPTS/post-tool-hook.sh" >/dev/null 2>&1
[[ "$(grep -c . "$TMPDIR/claude-verify-pending-t1")" -eq 1 ]] || fail "sin duplicados"

# 4. Tool distinto de Edit/Write no marca
echo '{"session_id":"t3","tool_name":"Read","tool_input":{"file_path":"/x/b.ts"}}' \
  | bash "$SCRIPTS/post-tool-hook.sh" >/dev/null 2>&1
[[ ! -f "$TMPDIR/claude-verify-pending-t3" ]] || fail "Read no debe marcar"

echo "OK: post-tool-marker"
```

Luego: `chmod +x tests/test-post-tool-marker.sh`

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `bash tests/test-post-tool-marker.sh`
Expected: `FAIL(post-tool-marker): Edit .ts debe crear marcador` (el hook aún no escribe marcadores)

- [ ] **Step 4: Implementar el marcador en post-tool-hook.sh**

En `scripts/post-tool-hook.sh`, insertar inmediatamente después de la línea `[[ -z "$file" ]] && exit 0` (línea 14) y antes del bloque `# Detectar si existe archivo de test relacionado`:

```bash
# ── Marcador de verificación (Sección 01) ─────────────────────
# Si se editó código, registrarlo para que verify-stop.sh verifique al Stop.
sid=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null || echo "")
ext="${file##*.}"
case "$ext" in
  ts|tsx|js|jsx|mjs|cjs|vue|svelte|py|rb|php|go|rs|java|kt|swift|c|cpp|h|cs|sql|prisma|sh)
    if [[ -n "$sid" ]]; then
      tmp="${TMPDIR:-/tmp}"; tmp="${tmp%/}"
      marker="$tmp/claude-verify-pending-$sid"
      grep -qxF "$file" "$marker" 2>/dev/null || echo "$file" >> "$marker"
    fi
    ;;
esac
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `bash tests/test-post-tool-marker.sh && bash -n scripts/post-tool-hook.sh`
Expected: `OK: post-tool-marker` y sin errores de sintaxis

- [ ] **Step 6: Commit**

```bash
git add tests/run.sh tests/test-post-tool-marker.sh scripts/post-tool-hook.sh
git commit -m "feat(hooks): marcador de código editado por sesión en post-tool-hook + harness de tests"
```

(Recordar el trailer de commit de Global Constraints.)

---

### Task 2: verify-stop.sh — verificación al Stop con anti-loop

**Files:**
- Create: `scripts/verify-stop.sh`
- Test: `tests/test-verify-stop.sh`

**Interfaces:**
- Consumes: marcador `claude-verify-pending-<sid>` (Task 1); contrato opcional `<repo>/.claude/verify.sh`.
- Produces (stdout): vacío = pasa/no aplica; `{"decision":"block","reason":"..."}` = bloquear stop; `{"systemMessage":"..."}` = anti-loop agotado, dejar parar. Siempre `exit 0`. Lo consume `stop-hook.sh` (Task 3).

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test-verify-stop.sh`:

```bash
#!/usr/bin/env bash
# Verifica el ciclo completo de verify-stop.sh: pasa, bloquea, anti-loop, fallback.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
TMPDIR="$(mktemp -d)"; export TMPDIR
repo="$(mktemp -d)"; git -C "$repo" init -q
fail() { echo "FAIL(verify-stop): $1"; exit 1; }
run() { echo '{"session_id":"v1","stop_hook_active":false}' \
  | (cd "$repo" && CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/verify-stop.sh"); }

# 1. Sin marcador → silencio
out=$(run); [[ -z "$out" ]] || fail "sin marcador debe callar"

# 2. verify.sh que falla → block con output y marcador persistente
mkdir -p "$repo/.claude"
printf '#!/bin/bash\necho boom; exit 1\n' > "$repo/.claude/verify.sh"
touch "$TMPDIR/claude-verify-pending-v1"
out=$(run)
echo "$out" | jq -e '.decision == "block"' >/dev/null || fail "debe bloquear al fallar"
echo "$out" | grep -q "boom" || fail "reason debe incluir el output del fallo"
[[ -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "marcador debe persistir tras fallo"
[[ "$(cat "$TMPDIR/claude-verify-attempts-v1")" == "1" ]] || fail "attempts debe ser 1"

# 3. Segundo fallo → sigue bloqueando
out=$(run)
echo "$out" | jq -e '.decision == "block"' >/dev/null || fail "2do fallo debe bloquear"
[[ "$(cat "$TMPDIR/claude-verify-attempts-v1")" == "2" ]] || fail "attempts debe ser 2"

# 4. Tercer intento → systemMessage y estado limpio (anti-loop)
out=$(run)
echo "$out" | jq -e '.systemMessage' >/dev/null || fail "anti-loop debe emitir systemMessage"
[[ ! -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "marcador limpio tras anti-loop"
[[ ! -f "$TMPDIR/claude-verify-attempts-v1" ]] || fail "attempts limpio tras anti-loop"

# 5. verify.sh que pasa → silencio y estado limpio
printf '#!/bin/bash\nexit 0\n' > "$repo/.claude/verify.sh"
touch "$TMPDIR/claude-verify-pending-v1"
out=$(run); [[ -z "$out" ]] || fail "pase debe callar"
[[ ! -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "marcador limpio tras pase"

# 6. Sin verify.sh y sin package.json/composer.json → pasa silencioso
rm -rf "$repo/.claude"
touch "$TMPDIR/claude-verify-pending-v1"
out=$(run); [[ -z "$out" ]] || fail "fallback sin nada que correr debe callar"
[[ ! -f "$TMPDIR/claude-verify-pending-v1" ]] || fail "marcador limpio en fallback vacío"

# 7. Fallback: package.json con script lint que falla → block con nudge
printf '{"scripts":{"lint":"exit 1"}}\n' > "$repo/package.json"
touch "$TMPDIR/claude-verify-pending-v1"
out=$(run)
echo "$out" | jq -e '.decision == "block"' >/dev/null || fail "fallback lint roto debe bloquear"
echo "$out" | grep -q "verify-setup" || fail "reason del fallback debe incluir nudge /verify-setup"
rm -f "$TMPDIR/claude-verify-pending-v1" "$TMPDIR/claude-verify-attempts-v1"

echo "OK: verify-stop"
```

Luego: `chmod +x tests/test-verify-stop.sh`

Nota: el caso 7 requiere `npm` instalado (usa `npm run lint`). Está garantizado en el Mac de Efraín; el test corre local, no en CI.

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `bash tests/test-verify-stop.sh`
Expected: FAIL — `scripts/verify-stop.sh` no existe todavía

- [ ] **Step 3: Implementar verify-stop.sh**

Crear `scripts/verify-stop.sh`:

```bash
#!/usr/bin/env bash
# verify-stop.sh — Verificación al Stop (Sección 01, guía 2026).
# Invocado desde stop-hook.sh ANTES de handoff/issues.
# Input stdin JSON: { "session_id": "...", "stop_hook_active": bool, ... }
# Contrato de salida (stdout):
#   vacío                     → pasó o no aplica
#   {"decision":"block",...}  → verificación falló: bloquear el stop
#   {"systemMessage":"..."}   → anti-loop agotado: dejar parar con advertencia
# SIEMPRE exit 0 — este hook jamás rompe la sesión.
set -uo pipefail

MAX_ATTEMPTS=2

input=$(cat)
sid=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null) || sid=""
[[ -z "$sid" ]] && exit 0

tmp="${TMPDIR:-/tmp}"; tmp="${tmp%/}"
marker="$tmp/claude-verify-pending-$sid"
attempts_f="$tmp/claude-verify-attempts-$sid"

# 1. Sin marcador → sesión sin ediciones de código
[[ -f "$marker" ]] || exit 0

# 2. Raíz del repo (sin repo git no hay contrato posible)
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || { rm -f "$marker" "$attempts_f"; exit 0; }

# 3. Anti-loop: al agotar los reintentos se permite parar con advertencia
attempts=$(cat "$attempts_f" 2>/dev/null || echo 0)
if [[ "$attempts" -ge "$MAX_ATTEMPTS" ]]; then
  rm -f "$marker" "$attempts_f"
  jq -cn --arg m "⚠️ verify-stop: la verificación falló $MAX_ATTEMPTS veces — se permite parar. Verificá manualmente antes de entregar." \
    '{systemMessage:$m}'
  exit 0
fi

# 4. Correr la verificación
out=""; rc=0; ran=""; nudge=""
if [[ -f "$root/.claude/verify.sh" ]]; then
  ran=".claude/verify.sh"
  out=$(cd "$root" && bash .claude/verify.sh 2>&1) || rc=$?
else
  # Fallback barato: SOLO lint/typecheck detectados. Nunca tests ni build.
  nudge=" ℹ️ Este repo no tiene .claude/verify.sh — corré /verify-setup para crear el contrato."
  if [[ -f "$root/package.json" ]]; then
    pm="npm run"
    [[ -f "$root/pnpm-lock.yaml" ]] && pm="pnpm"
    [[ -f "$root/yarn.lock" ]] && pm="yarn"
    [[ -f "$root/bun.lockb" || -f "$root/bun.lock" ]] && pm="bun run"
    for s in lint typecheck; do
      if jq -e --arg s "$s" '.scripts[$s] // empty' "$root/package.json" >/dev/null 2>&1; then
        ran="${ran}${pm} ${s}; "
        step_out=$(cd "$root" && $pm "$s" 2>&1) || rc=$?
        out="${out}${step_out}
"
      fi
    done
  elif [[ -f "$root/composer.json" ]]; then
    for s in lint phpstan; do
      if jq -e --arg s "$s" '.scripts[$s] // empty' "$root/composer.json" >/dev/null 2>&1; then
        ran="${ran}composer run ${s}; "
        step_out=$(cd "$root" && composer run "$s" 2>&1) || rc=$?
        out="${out}${step_out}
"
      fi
    done
  fi
  # Nada que correr → pasa (el nudge llega vía load-context al inicio de sesión)
  if [[ -z "$ran" ]]; then rm -f "$marker" "$attempts_f"; exit 0; fi
fi

# 5. Resultado
if [[ "$rc" -eq 0 ]]; then
  rm -f "$marker" "$attempts_f"
  exit 0
fi

echo $((attempts + 1)) > "$attempts_f"
tail_out=$(printf '%s' "$out" | tail -50)
reason="❌ Verificación falló (${ran}).${nudge} Arreglá los errores; al volver a entregar, la verificación correrá de nuevo.

${tail_out}"
jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
```

Luego: `chmod +x scripts/verify-stop.sh`

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `bash tests/test-verify-stop.sh && bash -n scripts/verify-stop.sh`
Expected: `OK: verify-stop` y sin errores de sintaxis

- [ ] **Step 5: Commit**

```bash
git add scripts/verify-stop.sh tests/test-verify-stop.sh
git commit -m "feat(hooks): verify-stop.sh — verificación al Stop con contrato por repo y anti-loop"
```

---

### Task 3: Integrar verify-stop.sh en stop-hook.sh

**Files:**
- Modify: `scripts/stop-hook.sh` (insertar tras `transcript=$(...)`, línea 9)
- Test: `tests/test-stop-hook.sh`

**Interfaces:**
- Consumes: contrato de salida de `verify-stop.sh` (Task 2).
- Produces: si hay `block` → lo reenvía como ÚNICO stdout y termina (sin handoff). Si hay `systemMessage` → genera handoff en silencio, reenvía el JSON y termina. Si silencio → comportamiento actual intacto.

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test-stop-hook.sh`:

```bash
#!/usr/bin/env bash
# Verifica que stop-hook.sh reenvíe el block de verify-stop.sh y no genere handoff al bloquear.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
TMPDIR="$(mktemp -d)"; export TMPDIR
repo="$(mktemp -d)"; git -C "$repo" init -q
fail() { echo "FAIL(stop-hook): $1"; exit 1; }
inp='{"session_id":"s1","stop_hook_active":false,"transcript_path":""}'

# 1. Verificación rota → stop-hook emite el block y NO genera handoff
mkdir -p "$repo/.claude"
printf '#!/bin/bash\nexit 1\n' > "$repo/.claude/verify.sh"
touch "$TMPDIR/claude-verify-pending-s1"
out=$(echo "$inp" | (cd "$repo" && CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/stop-hook.sh"))
echo "$out" | jq -e '.decision == "block"' >/dev/null || fail "debe reenviar el block"
[[ ! -d "$repo/.claude/handoff" ]] || fail "no debe generar handoff al bloquear"

# 2. Verificación sana → sin JSON de bloqueo en stdout (flujo normal)
printf '#!/bin/bash\nexit 0\n' > "$repo/.claude/verify.sh"
touch "$TMPDIR/claude-verify-pending-s1"
rm -f "$TMPDIR/claude-verify-attempts-s1"
out=$(echo "$inp" | (cd "$repo" && CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/stop-hook.sh"))
echo "$out" | jq -e '.decision? // empty' >/dev/null 2>&1 && fail "pase no debe emitir decision"

echo "OK: stop-hook"
```

Luego: `chmod +x tests/test-stop-hook.sh`

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `bash tests/test-stop-hook.sh`
Expected: FAIL — stop-hook.sh aún no invoca verify-stop.sh (genera handoff y no emite block)

- [ ] **Step 3: Integrar en stop-hook.sh**

En `scripts/stop-hook.sh`, insertar después de la línea 9 (`transcript=$(...)`) y antes del bloque `# ── 1. Handoff de sesión`:

```bash
# ── 0. Verificación (Sección 01) — puede bloquear el stop ─────
verify_out=$(echo "$input" | bash "$(dirname "$0")/verify-stop.sh" 2>/dev/null || true)
if [[ -n "$verify_out" ]]; then
  decision=$(echo "$verify_out" | jq -r '.decision // ""' 2>/dev/null || echo "")
  if [[ "$decision" == "block" ]]; then
    # Bloquea: reenviar como ÚNICO stdout y salir. La sesión continúa;
    # el handoff llegará en el stop definitivo.
    echo "$verify_out"
    exit 0
  fi
  # systemMessage (anti-loop agotado): handoff en silencio + advertencia visible
  echo "$input" | "$(dirname "$0")/handoff-create.sh" >/dev/null 2>&1 || true
  echo "$verify_out"
  exit 0
fi
```

Actualizar también el comentario de cabecera del script (líneas 2-4) a:

```bash
# stop-hook.sh — Stop hook.
# 0. SIEMPRE: verificación de código editado via verify-stop.sh (puede bloquear el stop).
# 1. SIEMPRE: genera handoff de sesión (cualquier repo git) via handoff-create.sh.
# 2. Solo repos haefrain/*: recuerda cerrar issues mencionados en la sesión.
```

- [ ] **Step 4: Correr los tests y verificar que pasan**

Run: `bash tests/test-stop-hook.sh && bash tests/run.sh`
Expected: `OK: stop-hook` y `✅ Todos los tests pasaron`

- [ ] **Step 5: Commit**

```bash
git add scripts/stop-hook.sh tests/test-stop-hook.sh
git commit -m "feat(hooks): stop-hook corre verificación primero y bloquea entregas con código roto"
```

---

### Task 4: Plantillas de contrato por stack + contrato del propio toolkit

**Files:**
- Create: `config/templates/verify/node.sh`
- Create: `config/templates/verify/laravel.sh`
- Create: `config/templates/verify/rails.sh`
- Create: `config/templates/verify/generic.sh`
- Create: `.claude/verify.sh` (contrato del toolkit — dogfooding)

**Interfaces:**
- Produces: plantillas que `/verify-setup` (Task 5) copia a `<repo>/.claude/verify.sh`. Convención: éxito = exit 0; `FULL=1` = suite completa.

- [ ] **Step 1: Crear las cuatro plantillas**

`config/templates/verify/node.sh`:

```bash
#!/usr/bin/env bash
# Contrato de verificación — rápido por defecto, FULL=1 corre la suite completa.
# Generado por /verify-setup — AJUSTÁ los comandos a los scripts reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PM="npm run"   # npm run | pnpm | yarn | bun run — según lockfile

# ── Rápido (< 5 min): lint + typecheck ──
$PM lint
$PM typecheck

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa + build ──
  $PM test
  $PM build
fi
```

`config/templates/verify/laravel.sh`:

```bash
#!/usr/bin/env bash
# Contrato de verificación — rápido por defecto, FULL=1 corre la suite completa.
# Generado por /verify-setup — AJUSTÁ los comandos a las herramientas reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Rápido (< 5 min): estilo + análisis estático ──
vendor/bin/pint --test
vendor/bin/phpstan analyse --no-progress

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa ──
  php artisan test
fi
```

`config/templates/verify/rails.sh`:

```bash
#!/usr/bin/env bash
# Contrato de verificación — rápido por defecto, FULL=1 corre la suite completa.
# Generado por /verify-setup — AJUSTÁ los comandos a las herramientas reales del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Rápido (< 5 min): estilo ──
bundle exec rubocop --no-color

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa ──
  bundle exec rspec
fi
```

`config/templates/verify/generic.sh`:

```bash
#!/usr/bin/env bash
# Contrato de verificación — rápido por defecto, FULL=1 corre la suite completa.
# Generado por /verify-setup — COMPLETÁ con los comandos del repo.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Rápido (< 5 min): lint + typecheck + tests enfocados ──
# <comando de lint del repo>
# <comando de typecheck del repo>

if [[ "${FULL:-0}" == "1" ]]; then
  # ── Suite completa + build ──
  # <comando de tests del repo>
  # <comando de build del repo>
  :
fi
```

Luego: `chmod +x config/templates/verify/*.sh`

- [ ] **Step 2: Crear el contrato del propio toolkit**

Crear `.claude/verify.sh` (este SÍ se comitea — el toolkit es repo haefrain/*):

```bash
#!/usr/bin/env bash
# Contrato de verificación del claude-code-toolkit.
# Rápido por defecto; no hay suite lenta, FULL no agrega nada extra.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# Sintaxis de todos los scripts bash
for f in scripts/*.sh install.sh tests/*.sh config/templates/verify/*.sh .claude/verify.sh; do
  bash -n "$f"
done

# Tests del toolkit
bash tests/run.sh
```

Luego: `chmod +x .claude/verify.sh`

- [ ] **Step 3: Verificar que el contrato del toolkit pasa**

Run: `bash .claude/verify.sh`
Expected: `✅ Todos los tests pasaron` (bash -n silencioso + tests OK)

- [ ] **Step 4: Verificar sintaxis de las plantillas**

Run: `for f in config/templates/verify/*.sh; do bash -n "$f" && echo "OK $f"; done`
Expected: `OK` por cada una de las 4 plantillas

- [ ] **Step 5: Commit**

```bash
git add config/templates/verify/ .claude/verify.sh
git commit -m "feat(verify): plantillas de contrato por stack + contrato del propio toolkit"
```

---

### Task 5: Comando /verify-setup

**Files:**
- Create: `commands/verify-setup.md`

**Interfaces:**
- Consumes: plantillas en `~/.claude/templates/verify/` (instaladas por Task 8 desde `config/templates/verify/`).
- Produces: `<repo>/.claude/verify.sh` ejecutable, comiteado (repos `haefrain/*`) o excluido vía `.git/info/exclude` (repos ajenos).

- [ ] **Step 1: Crear el comando**

Crear `commands/verify-setup.md`:

```markdown
---
description: Bootstrapea el contrato de verificación .claude/verify.sh del repo actual desde la plantilla del stack detectado.
argument-hint: ""
---

Crea el contrato de verificación del repo actual. Seguí estos pasos EXACTOS:

## 1. Detectar el stack (no asumas — verificá archivos)

```bash
root=$(git rev-parse --show-toplevel) && ls "$root/package.json" "$root/composer.json" "$root/Gemfile" "$root/artisan" 2>/dev/null; ls "$root"/pnpm-lock.yaml "$root"/yarn.lock "$root"/bun.lock* "$root"/package-lock.json 2>/dev/null
```

- `package.json` → plantilla `node.sh` (PM según lockfile: pnpm-lock.yaml→`pnpm`, yarn.lock→`yarn`, bun.lock*→`bun run`, package-lock.json→`npm run`)
- `artisan` + `composer.json` → plantilla `laravel.sh`
- `Gemfile` → plantilla `rails.sh`
- Ninguno → plantilla `generic.sh`

## 2. Leer los scripts REALES del repo

Lee `package.json` (campo `scripts`) o `composer.json` (campo `scripts`) o los binstubs/gems disponibles. El contrato SOLO puede invocar comandos que existen — jamás inventes un script.

## 3. Generar el contrato

```bash
mkdir -p "$root/.claude" && cp ~/.claude/templates/verify/<plantilla> "$root/.claude/verify.sh" && chmod +x "$root/.claude/verify.sh"
```

Luego EDITÁ `.claude/verify.sh` reemplazando los comandos de la plantilla por los reales detectados en el paso 2:
- **Modo rápido** (siempre corre, presupuesto < 5 min): lint + typecheck + tests enfocados si son baratos.
- **Bloque `FULL=1`**: suite completa + build.

## 4. Política de versionado

```bash
git -C "$root" remote get-url origin
```

- Remote `github.com/haefrain/*` → agregá el archivo a git: `git -C "$root" add .claude/verify.sh` y sugerí comitearlo.
- Remote ajeno (bukhr/*, etc.) → NO lo comitees: `grep -qxF ".claude/verify.sh" "$root/.git/info/exclude" || echo ".claude/verify.sh" >> "$root/.git/info/exclude"`

## 5. Validar

1. Corré el contrato: `bash "$root/.claude/verify.sh"` — debe terminar en exit 0 sobre el repo limpio. Si falla por comandos inexistentes, corregí el contrato (no el repo).
2. Mostrale a Efraín el contrato final y qué política de versionado se aplicó.
3. Recordá: a partir de ahora el hook Stop correrá este contrato cuando haya código editado; si falla, Claude sigue trabajando en vez de entregar.
```

- [ ] **Step 2: Verificar formato del comando**

Run: `head -4 commands/verify-setup.md`
Expected: frontmatter con `description:` y `argument-hint:` (mismo formato que `commands/handoff.md`)

- [ ] **Step 3: Commit**

```bash
git add commands/verify-setup.md
git commit -m "feat(commands): /verify-setup — bootstrap del contrato de verificación por repo"
```

---

### Task 6: Nudge de contrato faltante en load-context.sh

**Files:**
- Modify: `scripts/load-context.sh` (dentro de la sección `# ── 4. Inventario de capacidades`, tras el bloque de CodeGraph sin índice, línea ~88)
- Test: `tests/test-load-context-nudge.sh`

**Interfaces:**
- Consumes: existencia de `<repo>/.claude/verify.sh`.
- Produces: línea de aviso en el contexto de SessionStart cuando falta el contrato.

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test-load-context-nudge.sh`:

```bash
#!/usr/bin/env bash
# Verifica el nudge de /verify-setup en load-context.sh según exista o no el contrato.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
repo="$(mktemp -d)"; git -C "$repo" init -q
fail() { echo "FAIL(load-context-nudge): $1"; exit 1; }

# 1. Repo sin contrato → el output menciona /verify-setup
out=$(CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/load-context.sh" "$repo" 2>/dev/null || true)
echo "$out" | grep -q "verify-setup" || fail "sin contrato debe sugerir /verify-setup"

# 2. Repo con contrato → sin nudge
mkdir -p "$repo/.claude"
printf '#!/bin/bash\nexit 0\n' > "$repo/.claude/verify.sh"
out=$(CLAUDE_PROJECT_DIR="$repo" bash "$SCRIPTS/load-context.sh" "$repo" 2>/dev/null || true)
echo "$out" | grep -q "verify-setup" && fail "con contrato no debe haber nudge"

echo "OK: load-context-nudge"
```

Luego: `chmod +x tests/test-load-context-nudge.sh`

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `bash tests/test-load-context-nudge.sh`
Expected: `FAIL(load-context-nudge): sin contrato debe sugerir /verify-setup`

- [ ] **Step 3: Implementar el nudge**

En `scripts/load-context.sh`, insertar después del bloque `# CodeGraph disponible pero sin índice → sugerir inicializar` (línea ~88) y antes de `# ── Salir en silencio`:

```bash
# Contrato de verificación (Sección 01) — nudge si falta
if [[ -n "$git_root" && ! -f "$git_root/.claude/verify.sh" ]]; then
  capabilities="${capabilities}- **Verificación:** ⚠️ este repo no tiene \`.claude/verify.sh\` — corré \`/verify-setup\` para crear el contrato de verificación\n"
fi
```

- [ ] **Step 4: Correr los tests y verificar que pasan**

Run: `bash tests/test-load-context-nudge.sh && bash tests/run.sh`
Expected: `OK: load-context-nudge` y `✅ Todos los tests pasaron`

- [ ] **Step 5: Commit**

```bash
git add scripts/load-context.sh tests/test-load-context-nudge.sh
git commit -m "feat(load-context): nudge /verify-setup en repos sin contrato de verificación"
```

---

### Task 7: Lineamientos claude-verification.md + imports en config

**Files:**
- Create: `config/claude-verification.md`
- Modify: `config/CLAUDE.md` (agregar sección antes de `@RTK.md`, línea 45)
- Modify: `config/claude-toolkit.md` (tabla de disparadores + lista de hooks internos + slash commands)

**Interfaces:**
- Produces: `@claude-verification.md` importado desde el CLAUDE.md global. Lo distribuye `install.sh` (Task 8).

- [ ] **Step 1: Crear config/claude-verification.md**

```markdown
# Verificación — Sección 01 (guía 2026)

**Principio (tip #1 del equipo de Claude Code):** si Claude puede comprobar su propio trabajo, itera hasta que esté bien. Sin verificación, el usuario es el ciclo de feedback.

## Reglas duras

1. **Evidencia antes de afirmaciones.** Nunca declarar algo terminado sin comando corrido + salida real. «Debería funcionar» está prohibido. Si los tests fallan, decirlo con la salida.
2. **Cierre estándar:** todo cambio no trivial termina con `/simplify` antes de entregar.
3. **Regla de oro (compounding):** tras cada corrección de Efraín, actualizar el CLAUDE.md del repo para no repetir el error. Claude escribe la regla, Efraín la aprueba.
4. **Frontend:** verificar en browser real (extensión de Chrome de Claude Code) cuando esté disponible — no solo tests.
5. **El hook Stop corre `.claude/verify.sh`** del repo cuando hubo código editado. Si falla, Claude sigue trabajando (máx. 2 reintentos). No intentes evadirlo: arreglá la causa.

## Contrato por repo

- `.claude/verify.sh` — modo rápido (< 5 min) siempre; `FULL=1 bash .claude/verify.sh` corre la suite completa.
- Repo sin contrato → crearlo con `/verify-setup` (detecta stack, usa plantillas de `~/.claude/templates/verify/`).
- Repos `haefrain/*`: el contrato se comitea. Repos ajenos (bukhr/*): local + `.git/info/exclude`.

## Prompts del repertorio (usarlos y auto-aplicarlos)

- «**Demuéstrame que esto funciona**» — comparar comportamiento entre main y la rama antes de declarar listo.
- «**Examíname sobre estos cambios** y no abras el PR hasta que pase tu examen.»
- Tras un primer intento mediocre: «con todo lo que sabes ahora, **bota esto e implementa la solución elegante**».
```

- [ ] **Step 2: Agregar la sección en config/CLAUDE.md**

En `config/CLAUDE.md`, insertar antes de la línea final `@RTK.md`:

```markdown
---

## Verificación

@claude-verification.md

```

- [ ] **Step 3: Actualizar config/claude-toolkit.md**

Tres ediciones puntuales:

1. En la tabla `## Disparadores automáticos OBLIGATORIOS`, agregar la fila:

```markdown
| configurar verificación / verify del repo | `/verify-setup` (genera `.claude/verify.sh`) |
```

2. En la sección `**Hooks internos** (no llamar manualmente)`, agregar:

```markdown
- `verify-stop.sh` — invocado por stop-hook.sh: corre `.claude/verify.sh` del repo si hubo código editado; bloquea el stop si falla (máx. 2 reintentos)
```

3. En la lista de `## Slash commands`, agregar `/verify-setup` al final de la lista existente.

- [ ] **Step 4: Verificar consistencia**

Run: `grep -c "verify" config/CLAUDE.md config/claude-toolkit.md config/claude-verification.md`
Expected: ≥1 en CLAUDE.md, ≥3 en claude-toolkit.md, ≥5 en claude-verification.md

- [ ] **Step 5: Commit**

```bash
git add config/claude-verification.md config/CLAUDE.md config/claude-toolkit.md
git commit -m "docs(config): lineamientos de verificación globales + disparadores en toolkit"
```

---

### Task 8: Distribución en install.sh

**Files:**
- Modify: `install.sh` (secciones 5 templates, 6 CLAUDE.md, 7b hooks)

**Interfaces:**
- Consumes: todos los artefactos de Tasks 2, 4, 5, 7.
- Produces: `~/.claude/scripts/verify-stop.sh`, `~/.claude/templates/verify/*.sh`, `~/.claude/commands/verify-setup.md`, `~/.claude/claude-verification.md`, import en CLAUDE.md global, `timeout: 600` en el Stop hook. Todo idempotente.

- [ ] **Step 1: Instalar plantillas de verify**

`verify-stop.sh` y `verify-setup.md` ya se copian con los globs existentes (`scripts/*.sh`, `commands/*.md`). Falta el directorio de plantillas. En `install.sh`, después del bloque `step "Instalando slash commands (~/.claude/commands/)"` (tras la línea 154 `ok "...comandos instalados..."`), agregar:

```bash
# Plantillas de contrato de verificación (Sección 01)
mkdir -p "$CLAUDE_DIR/templates/verify"
cp "$REPO_DIR/config/templates/verify/"*.sh "$CLAUDE_DIR/templates/verify/"
chmod +x "$CLAUDE_DIR/templates/verify/"*.sh
ok "$(ls "$CLAUDE_DIR/templates/verify/"*.sh | wc -l | xargs) plantillas de verificación instaladas"
```

- [ ] **Step 2: Instalar claude-verification.md y su import**

En la sección `step "Configurando CLAUDE.md"`:

1. Tras la línea 164 (`cp ... RTK.md ...`), agregar:

```bash
cp "$REPO_DIR/config/claude-verification.md" "$CLAUDE_DIR/claude-verification.md"
```

y actualizar el mensaje `ok` de la línea 165 a:

```bash
ok "Archivos de referencia instalados (claude-issues.md, claude-toolkit.md, RTK.md, claude-verification.md)"
```

2. Actualizar la variable `TOOLKIT_IMPORTS` (líneas 168-169) a:

```bash
TOOLKIT_IMPORTS="@claude-issues.md
@claude-toolkit.md
@claude-verification.md"
```

3. En el `case` de merge (opción por defecto `*`, líneas 204-213), agregar `echo "@claude-verification.md"` después de `echo "@claude-toolkit.md"`.

4. En la opción `3)` (conservar), agregar `echo "  @claude-verification.md"` después de `echo "  @claude-toolkit.md"`.

5. Después de cerrar el `fi` del bloque CLAUDE.md (línea 215), agregar el parche idempotente para instalaciones previas:

```bash
# Instalaciones previas del toolkit: agregar el import de verificación si falta
if [[ -f "$CLAUDE_MD" ]] && grep -q "@claude-toolkit.md" "$CLAUDE_MD" && ! grep -q "@claude-verification.md" "$CLAUDE_MD"; then
  printf '\n@claude-verification.md\n' >> "$CLAUDE_MD"
  ok "Import @claude-verification.md agregado a CLAUDE.md existente"
fi
```

- [ ] **Step 3: Timeout de 600s en el Stop hook**

En la sección 7b, después de la línea `_append_hook "Stop" ...` (línea 280) y antes del bloque RTK (línea 281), agregar:

```bash
# La verificación puede correr lint/tests: subir el timeout del Stop hook a 600s (idempotente)
current_settings=$(printf '%s' "$current_settings" | jq \
  '(.hooks.Stop // []) |= map(
     .hooks |= map(if .command == "bash ~/.claude/scripts/stop-hook.sh" then . + {timeout: 600} else . end)
   )')
```

- [ ] **Step 4: Verificar sintaxis y contrato completo**

Run: `bash -n install.sh && bash .claude/verify.sh`
Expected: sin errores de sintaxis y `✅ Todos los tests pasaron`

- [ ] **Step 5: Verificar idempotencia del parche de import (simulación)**

Run:

```bash
tmp=$(mktemp -d) && printf '# mi config\n@claude-issues.md\n@claude-toolkit.md\n' > "$tmp/CLAUDE.md" \
&& CLAUDE_MD="$tmp/CLAUDE.md" bash -c '
  ok(){ echo "ok: $1"; }
  if [[ -f "$CLAUDE_MD" ]] && grep -q "@claude-toolkit.md" "$CLAUDE_MD" && ! grep -q "@claude-verification.md" "$CLAUDE_MD"; then
    printf "\n@claude-verification.md\n" >> "$CLAUDE_MD"
    ok "import agregado"
  fi
  if [[ -f "$CLAUDE_MD" ]] && grep -q "@claude-toolkit.md" "$CLAUDE_MD" && ! grep -q "@claude-verification.md" "$CLAUDE_MD"; then
    echo "ERROR: se agregaría dos veces"
  else
    echo "idempotente OK"
  fi' \
&& grep -c "@claude-verification.md" "$tmp/CLAUDE.md"
```

Expected: `ok: import agregado`, `idempotente OK`, y conteo `1`

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "feat(install): distribuir verificación — plantillas, lineamientos, import y timeout del Stop hook"
```

---

### Task 9: Documentación en README + verificación final

**Files:**
- Modify: `README.md` (nueva subsección en la zona que describe hooks/flujo de sesión — ubicarla con `grep -n "hook" README.md`)

**Interfaces:**
- Consumes: todo lo anterior.
- Produces: rama lista para PR.

- [ ] **Step 1: Agregar sección al README**

Localizar la sección de hooks del README (`grep -n "Stop\|hook" README.md | head`) y agregar a continuación de la descripción del Stop hook existente:

```markdown
### Verificación al cierre (Sección 01 — guía 2026)

El tip #1 del equipo de Claude Code: cerrar el ciclo de feedback. Si la sesión editó código,
el hook Stop corre el contrato del repo antes de permitir la entrega:

1. `post-tool-hook.sh` marca los archivos de código editados (por sesión, en `$TMPDIR`).
2. Al parar, `verify-stop.sh` corre `.claude/verify.sh` del repo (modo rápido, < 5 min).
3. Si falla → el stop se bloquea con la razón y Claude sigue arreglando (máx. 2 reintentos).
4. Sin contrato → fallback barato (solo `lint`/`typecheck` detectados) + aviso para correr `/verify-setup`.

**Contrato por repo:** `.claude/verify.sh` — rápido por defecto, `FULL=1` corre la suite completa.
Se crea con `/verify-setup` desde plantillas por stack (`node`, `laravel`, `rails`, `generic`).
En repos propios (`haefrain/*`) se comitea; en ajenos queda local vía `.git/info/exclude`.

**Lineamientos globales:** `claude-verification.md` (importado en `CLAUDE.md`) — evidencia antes
de afirmaciones, `/simplify` como cierre estándar, y la regla de compounding: cada corrección
termina actualizando el CLAUDE.md del repo.
```

- [ ] **Step 2: Verificación final completa**

Run: `bash .claude/verify.sh && git status -sb`
Expected: `✅ Todos los tests pasaron`; solo `README.md` modificado pendiente

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): verificación al cierre — hook Stop, contrato por repo y /verify-setup"
```

- [ ] **Step 4: Revisión de criterios de aceptación de la spec**

Repasar `docs/superpowers/specs/2026-07-16-s01-verificacion-design.md` sección "Criterios de aceptación" y confirmar:

- Repo dummy con test roto bloquea y luego pasa → cubierto por `tests/test-verify-stop.sh` (casos 2-5) y `tests/test-stop-hook.sh`.
- Sesión sin ediciones no verifica → caso 1 de `tests/test-verify-stop.sh`.
- Anti-loop → caso 4 de `tests/test-verify-stop.sh`.
- `/verify-setup` políticas de versionado → revisión manual del comando (paso 4 del md).
- `bash -n` limpio → `.claude/verify.sh` lo corre sobre todos los scripts.
- `install.sh` idempotente → Step 5 de Task 8.
- Nudge de SessionStart → `tests/test-load-context-nudge.sh`.

Los criterios que dependen de instalación real (correr `install.sh` sobre `~/.claude` y probar el flujo en vivo) quedan para el cierre de la rama, con aprobación de Efraín.

---

### Task 10: Nivel MUTATION del contrato — mutation testing por stack

> **SUPERSEDED por S01.1 (2026-07-16):** la mutación pasó al gate por defecto, scoped a archivos afectados con presupuesto y umbrales bloqueantes; el nivel `MUTATION=1` fue eliminado. Ver spec §3. Esta tarea queda como registro histórico.

Pedido por Efraín (2026-07-16): medir que los tests del TDD realmente testeen algo real, con Infection (PHP), Stryker (JS/TS) y mutant (Ruby). Tercer nivel del contrato: `MUTATION=1 bash .claude/verify.sh`. Nunca corre en el gate rápido del Stop (es lento por diseño).

**Files:**
- Modify: `config/templates/verify/node.sh`, `laravel.sh`, `rails.sh`, `generic.sh` (bloque MUTATION al final)
- Modify: `commands/verify-setup.md` (detección de config de mutación)
- Modify: `config/claude-verification.md` (lineamiento del tercer nivel)
- Modify: `docs/superpowers/specs/2026-07-16-s01-verificacion-design.md` (convención del contrato)

**Interfaces:**
- Consumes: convención rápido/`FULL=1` de Task 4.
- Produces: convención `MUTATION=1` que la S05 (SDD) usará como gate de Delivery.

- [ ] **Step 1: Bloque MUTATION en las 4 plantillas** (añadir AL FINAL de cada una, después del bloque `FULL`)

`node.sh`:

```bash

if [[ "${MUTATION:-0}" == "1" ]]; then
  # ── Mutation testing (lento): mide que los tests maten mutantes ──
  npx stryker run
fi
```

`laravel.sh`:

```bash

if [[ "${MUTATION:-0}" == "1" ]]; then
  # ── Mutation testing (lento): mide que los tests maten mutantes ──
  vendor/bin/infection --min-msi=70 --threads=max
fi
```

`rails.sh`:

```bash

if [[ "${MUTATION:-0}" == "1" ]]; then
  # ── Mutation testing (lento): mide que los tests maten mutantes ──
  bundle exec mutant run
fi
```

`generic.sh`:

```bash

if [[ "${MUTATION:-0}" == "1" ]]; then
  # ── Mutation testing (lento): Infection (PHP) / Stryker (JS-TS) / mutant (Ruby) ──
  # <comando de mutation testing del repo>
  :
fi
```

- [ ] **Step 2: Detección en commands/verify-setup.md** — añadir al final de la sección `## 3. Generar el contrato`:

```markdown

**Nivel MUTATION:** si el repo tiene config de mutation testing (`infection.json5`/`infection.json`, `stryker.conf.*`, `.mutant.yml`), dejá el bloque `MUTATION=1` de la plantilla con el comando real del repo. Si no la tiene, dejá el bloque como viene (la herramienta del stack queda sugerida) y mencionale a Efraín que existe: mide que los tests maten mutantes (MSI), no que solo pasen.
```

- [ ] **Step 3: Lineamiento en config/claude-verification.md** — añadir al final de la sección `## Contrato por repo`:

```markdown
- Tercer nivel: `MUTATION=1 bash .claude/verify.sh` — mutation testing (Infection PHP / Stryker JS-TS / mutant Ruby): mide que los tests realmente maten mutantes (MSI), no que solo pasen. Lento por diseño: usarlo antes de PRs importantes o en jobs nocturnos, nunca en el gate rápido del Stop.
```

- [ ] **Step 4: Convención en la spec** — en `docs/superpowers/specs/2026-07-16-s01-verificacion-design.md`, sección `### 3. Contrato por repo`, añadir tras la línea de las plantillas:

```markdown
- Tercer nivel opcional `MUTATION=1`: mutation testing por stack (Infection/Stryker/mutant) — nunca en el gate rápido; pedido de Efraín 2026-07-16.
```

- [ ] **Step 5: Verificar**

Run: `for f in config/templates/verify/*.sh; do bash -n "$f" && echo "OK $f"; done && bash .claude/verify.sh`
Expected: `OK` × 4 y `✅ Todos los tests pasaron`

- [ ] **Step 6: Commit**

```bash
git add config/templates/verify/ commands/verify-setup.md config/claude-verification.md docs/superpowers/specs/2026-07-16-s01-verificacion-design.md
git commit -m "feat(verify): nivel MUTATION del contrato — Infection/Stryker/mutant por stack"
```
