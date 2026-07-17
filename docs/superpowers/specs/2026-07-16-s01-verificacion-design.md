# Sección 01 — Verificación: hook Stop + contrato por repo

**Fecha:** 2026-07-16
**Estado:** aprobado por Efraín (diseño conversacional, sesión 2026-07-16)
**Origen:** guía de campo "Prácticas del equipo de Claude Code 2026", sección 01 (tip #1 oficial: cerrar el ciclo de feedback con verificación automática).

## Objetivo

Que ninguna sesión de Claude Code entregue trabajo con código modificado sin haber corrido la verificación del proyecto. Si la verificación falla, Claude sigue trabajando en vez de entregar a medias. Aplica en dos niveles:

- **Global:** el hook Stop del toolkit ejecuta la verificación en cualquier repo.
- **Por proyecto:** cada repo declara SUS comandos en `.claude/verify.sh` (contrato versionable); los repos sin contrato reciben autodetección barata + nudge para crearlo.

## Componentes

### 1. `scripts/verify-stop.sh` (nuevo)

Invocado como **primer paso** de `stop-hook.sh` (antes de handoff e issues).

Flujo:

1. Lee el JSON de stdin (`session_id`, `stop_hook_active`, `transcript_path`).
2. Busca el marcador `${TMPDIR}/claude-verify-pending-<session_id>`. Sin marcador → `exit 0` (sesiones de solo lectura no pagan peaje).
3. Localiza la raíz del repo (`git rev-parse --show-toplevel` desde `CLAUDE_PROJECT_DIR` o `$PWD`). Sin repo git → `exit 0`.
4. Contador anti-loop `${TMPDIR}/claude-verify-attempts-<session_id>`: si ya hubo **2 bloqueos**, borra marcador y contador, imprime advertencia visible («verificación sigue fallando tras 2 intentos — entrega manualmente verificada requerida») y deja parar (`exit 0`).
5. Si existe `<repo>/.claude/verify.sh` ejecutable → lo corre (modo rápido, sin `FULL`).
6. Si no existe → **autodetección barata**: solo scripts `lint` y `typecheck` de `package.json` (con el package manager detectado por lockfile), o `composer lint`/`phpstan` si hay `composer.json` con esos scripts. Nunca tests ni build en fallback. Además anexa al output el nudge: «este repo no tiene `.claude/verify.sh` — corré `/verify-setup`».
7. **Resultado:**
   - Pasa → borra marcador y contador, `exit 0` (stop-hook continúa con handoff normal).
   - Falla → incrementa contador y emite en stdout `{"decision":"block","reason":"<últimas ~50 líneas del fallo + instrucción de arreglar y volver a verificar>"}` con `exit 0`. El stop queda bloqueado y Claude continúa.
8. Robustez: `set -uo pipefail` sin `-e` global en la orquestación; cualquier error interno del hook (jq ausente, permisos, etc.) → `exit 0` silencioso. El hook jamás rompe la sesión.

**Integración con `stop-hook.sh`:** verify-stop.sh se invoca primero; si emitió una decisión `block`, stop-hook.sh reenvía ese JSON como su único stdout y termina ahí mismo (sin handoff ni recordatorio de issues — la sesión continúa, el handoff llegará en el stop definitivo). Solo si la verificación pasa se ejecuta el resto del stop-hook.

Registro en settings: el entry existente del Stop hook se actualiza para incluir `"timeout": 600` (los checks rápidos deben quedar < 5 min; 10 min es el techo duro).

### 2. `post-tool-hook.sh` (modificado)

Además de su función actual (recordar tests relacionados), en cada Edit/Write:

- Si `file_path` tiene extensión de código (`ts|tsx|js|jsx|mjs|cjs|vue|svelte|py|rb|php|go|rs|java|kt|swift|c|cpp|h|cs|sql|prisma|sh`) → agrega la ruta (única) al marcador `${TMPDIR}/claude-verify-pending-<session_id>`.
- Extensiones excluidas explícitamente: `md|mdx|txt|json|yml|yaml|toml|lock|csv` (documentación y config trivial no disparan verificación).
- `session_id` viene en el JSON de entrada del hook.

### 3. Contrato por repo: `.claude/verify.sh`

Convención:

```bash
#!/usr/bin/env bash
# Contrato de verificación — modo rápido por defecto, FULL=1 para suite completa.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# rápido (< 5 min): lint + typecheck + tests enfocados
<comandos del repo>

if [[ "${FULL:-0}" == "1" ]]; then
  # suite completa + build
  <comandos del repo>
fi
```

- Salida con código ≠ 0 = verificación fallida.
- El toolkit trae plantillas por stack en `config/templates/verify/`: `node.sh` (npm/pnpm/yarn/bun por lockfile), `laravel.sh`, `rails.sh`, `generic.sh` (esqueleto comentado).
- **Revisión S01.1 (2026-07-16, pedido de Efraín):** la mutación deja de ser un nivel aparte y pasa al **gate por defecto, scoped a los archivos afectados** (diff working tree + rama vs `VERIFY_BASE`; Infection `--git-diff-base`, Stryker `--mutate`, mutant `--since`), con presupuesto `MUTATE_MAX_FILES=10` (excedido → se difiere con aviso). `FULL=1` (suite completa + build) queda **exclusivamente a solicitud explícita de Efraín** — nunca proactivo. Repos con infra pesada de tests: mutación comentada en el gate, se corre al cierre de tarjeta. El nivel `MUTATION=1` se elimina.

### 4. Comando `/verify-setup` (nuevo: `commands/verify-setup.md`)

Bootstrap del contrato en el repo actual:

1. Detecta stack con precedencia determinista — el primero que matchee gana: `artisan`+`composer.json` (laravel, agregando al contrato los scripts del frontend si además hay `package.json` con `lint`/`typecheck`/`build` reales) > `package.json` (node, PM por lockfile) > `Gemfile` (rails) > generic. Scripts disponibles reales siempre leídos de `package.json`/`composer.json` — no inventa comandos.
2. Genera `.claude/verify.sh` desde la plantilla correspondiente, con los comandos detectados y ejecutable (`chmod +x`).
3. **Política de versionado:**
   - Remote `github.com/haefrain/*` → el archivo se comitea al repo.
   - Remote ajeno (p. ej. `bukhr/*`) → se crea local y se agrega `.claude/verify.sh` al exclude vía `git rev-parse --git-path info/exclude` (compatible con worktrees, donde `.git` es un archivo y no un directorio; mismo patrón que handoff).
4. Muestra el contrato generado y pide validar los comandos antes de darlo por bueno.

### 5. `load-context.sh` (modificado)

Al inicio de sesión, si el cwd es un repo git sin `.claude/verify.sh`, agrega una línea al contexto: «⚠️ Este repo no tiene contrato de verificación — corré `/verify-setup`». Silencioso si ya existe.

### 6. Lineamientos: `config/claude-verification.md` (nuevo)

Se importa con `@claude-verification.md` desde `config/CLAUDE.md` (junto a RTK y los demás). Contenido:

- **Evidencia antes de afirmaciones:** nunca declarar terminado sin comando corrido + salida real. «Debería funcionar» está prohibido.
- **Cierre estándar:** todo cambio no trivial termina con `/simplify` antes de entregar.
- **Prompts del repertorio** (usables por Efraín y auto-aplicables por Claude): «demuéstrame que esto funciona» (comparar comportamiento main vs rama), «examíname sobre estos cambios y no abras el PR hasta que pase tu examen», «con todo lo que sabes ahora, bota esto e implementa la solución elegante».
- **Regla de oro (compounding):** tras cada corrección de Efraín, actualizar el CLAUDE.md del repo para no repetir el error.
- **Frontend:** verificación en browser real (extensión de Chrome) cuando esté disponible.

### 7. `install.sh` (modificado)

- Copia `verify-stop.sh` y `config/templates/verify/` a `~/.claude/`.
- Copia `commands/verify-setup.md` a `~/.claude/commands/`.
- Copia `config/claude-verification.md` a `~/.claude/` y agrega la línea `@claude-verification.md` al `CLAUDE.md` global si falta.
- Actualiza el entry del Stop hook con `timeout: 600` (idempotente, respeta hooks ajenos).

## Casos borde

| Caso | Comportamiento |
|---|---|
| Sesión sin ediciones de código | Sin marcador → stop libre, cero costo |
| Repo sin git | `exit 0` silencioso |
| `verify.sh` ausente | Fallback barato (lint/typecheck si existen) + nudge `/verify-setup`; **no bloquea** si no hay nada que correr |
| `verify.sh` presente pero no ejecutable | Se corre con `bash` explícito |
| Verificación falla 3 veces | Al 3er stop se permite parar con advertencia visible (anti-loop) |
| `stop_hook_active: true` | Cuenta como reintento normal; el contador es quien corta |
| jq/git ausentes o error interno del hook | `exit 0` — el hook nunca rompe la sesión |
| Checks lentos | Contrato rápido < 5 min por convención; timeout duro 600s |
| Repos ajenos (bukhr/*) | Contrato local vía `.git/info/exclude`, nunca comiteado (ruta resuelta con `--git-path`, compatible con worktrees) |

## Criterios de aceptación

- [ ] En un repo dummy con test roto: editar código → intentar parar → el stop se bloquea con la razón del fallo; al arreglar, el stop pasa.
- [ ] En sesión sin ediciones de código: el stop no ejecuta verificación alguna.
- [ ] Con verificación rota 3 veces: la sesión puede parar con advertencia (no loop infinito).
- [ ] `/verify-setup` en repo `haefrain/*` genera contrato comiteable; en repo ajeno lo deja en `.git/info/exclude`.
- [ ] `bash -n` limpio en todos los scripts nuevos/modificados.
- [ ] `install.sh` reinstalado sobre un `~/.claude` existente no duplica hooks, permisos ni imports.
- [ ] SessionStart en repo sin contrato muestra el nudge; con contrato, no.

## Fuera de alcance (secciones futuras)

- Voz bidireccional (S02), defaults de effort (S03), loops (S04), SDD (S05), worktrees (S06), memoria (S07), arsenal (S08).
- Instalación de la extensión de Chrome (manual, checklist for:efrain en S09).
- Generación automática de `verify.sh` para stacks no contemplados (la plantilla `generic.sh` cubre el resto a mano).
