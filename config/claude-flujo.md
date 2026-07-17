# Flujo de trabajo — plan, loops, paralelismo, memoria y arsenal (S03/S04/S06/S07/S08, guía 2026)

## Plan mode, modelo y esfuerzo (S03)

- **Regla del plan:** si el diff se describe en una frase → directo, sin plan. Si toca varios archivos o código desconocido → plan mode primero (Shift+Tab), refinar, aprobar, auto-accept.
- **Si algo se tuerce a mitad de implementación: RE-PLANEAR** (volver a plan mode), no parchar en caliente — parchar acumula deuda de contexto.
- **Segundo par de ojos:** en cambios grandes, un subagente revisa el plan «como staff engineer» antes de ejecutar.
- **Esfuerzo:** `high` como default de trabajo; `xhigh` para agéntico/coding complejo; `max` solo debugging duro o arquitectura (por sesión). Efraín lo setea con `/effort` (ver checklist).
- **Sesiones con nombre** (`claude --name "tema"`) siempre que haya más de una abierta.

## Loop programming (S04)

- Flujo repetido más de una vez al día → convertirlo en skill (`.claude/skills/<n>/SKILL.md`) → montarle `/loop`.
- Loop activo disponible: `/loop 30m /revisar-prs` (rutina CAPACWA, con ventana laboral integrada — no-op fuera de lunes-viernes 09-18).
- **Regla de diseño:** todo loop debe ser no-op fuera de su ventana/condición (patrón revisar-prs) y dejar rastro de qué hizo.
- `/schedule` para jobs en la nube que siguen con el equipo apagado (candidato: resumen nocturno de productos — pendiente de definir con Efraín).

## Paralelismo con worktrees (S06)

- Trabajo que necesita aislamiento → worktree nombrado: `claude --worktree <tema> --name "<tema>"` (+ `--tmux` si aplica).
- `/color` por sesión + notificaciones de terminal activas para no perderse entre sesiones.
- **Worktree de solo análisis:** uno dedicado a leer logs y correr queries, sin tocar código.
- Al cerrar: limpiar worktrees/ramas mergeadas (`/branch-cleanup`).
- Los subagentes de una misma sesión: JAMÁS dos escritores sobre el mismo repo a la vez.

## CLAUDE.md y memoria (S07)

- **Regla de oro (compounding):** toda corrección de Efraín termina actualizando el CLAUDE.md del repo (ya es regla dura en claude-verification.md).
- **Auto-memoria:** hechos duraderos (preferencias, entornos, decisiones) → memoria persistente; NO guardar lo que el repo ya registra.
- **Notas por tarea:** en trabajos largos, mantener notas en el repo (o handoff enriquecido con `/handoff`) y que el CLAUDE.md del repo las referencie.
- **En PRs:** con la GitHub App instalada, `@claude` en comentarios deja el aprendizaje para todo el equipo (instalación pendiente — checklist).

## Arsenal (S08)

- **Hooks activos del toolkit:** SessionStart(startup) contexto enriquecido · SessionStart(compact) reinyección de reglas críticas · UserPromptSubmit disparadores · PostToolUse marcador de código + tests · Stop verificación + handoff + issues · PreToolUse RTK.
- **Permisos:** preferir allowlist con wildcards en `.claude/settings.json` del repo (`Bash(pnpm run *)`, `Edit(docs/**)`) comiteada — la alternativa recomendada a saltarse permisos. `/permissions` para gestionarla.
- **`/btw`** para preguntas laterales sin interrumpir el trabajo en curso.
- **Movilidad (requisito de Efraín):** `/teleport` y `/remote-control` mueven/controlan sesiones entre terminal, web, desktop y la pestaña Code de la app móvil — requiere el equipo encendido y la sesión viva. Setup pendiente en checklist (keep-awake + app en el celular). Con esto las misiones SDD se pueden llevar desde el teléfono.
