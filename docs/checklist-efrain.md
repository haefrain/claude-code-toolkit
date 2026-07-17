# Checklist manual for:efrain — adopción guía 2026 (S09)

Acciones que requieren decisión o ejecución personal de Efraín (las instalaciones de herramientas — mutación, specify — Claude puede correrlas con tu OK explícito; están aquí porque decides tú cuándo y en qué repos). Las preguntas «P#» referencian el MD de preguntas del escritorio (`~/Desktop/preguntas-toolkit-2026-07-17.md`).

## Semana 1 — Verificación (S01) ✅ implementada

- [ ] Instalar la **extensión de Chrome de Claude Code** (verificación de frontend en browser real).
- [ ] Instalar herramientas de mutación en los repos activos: PHP `composer require --dev infection/infection`; JS/TS `npm i -D @stryker-mutator/core` + `stryker.conf` con `thresholds.break: 80`; Ruby gem `mutant` según licencia.
- [ ] Correr `/verify-setup` la primera vez que trabajes en cada repo (el nudge de SessionStart te lo recordará).

## Semana 2 — Voz y plan (S02/S03) ✅ implementadas

- [ ] Probar la entrada por voz: `/voice` en el CLI (requiere cuenta Claude.ai) y dictado nativo fn-fn.
- [ ] Probar la salida: `/voz on` → Claude habla resúmenes (Paulina; `/voz Mónica` para cambiar).
- [ ] Setear `/effort high` como hábito de sesión (`xhigh` para agéntico) — evaluar `auto` tras una semana.
- [ ] Habilitar `Shift+Enter` con `/terminal-setup` si aún no está.

## Semana 3 — Paralelismo y movilidad (S06/S08)

- [ ] Definir keep-awake del equipo para acceso remoto 24/7: opciones `caffeinate -dims` en un LaunchAgent, app Amphetamine, o `sudo pmset -a sleep 0` (pregunta P11 del MD).
- [ ] Instalar la app móvil de Claude y probar la pestaña **Code**; luego `/teleport` y `/remote-control` desde el celular contra una sesión viva del Mac.
- [ ] Probar el flujo worktree: `claude --worktree <tema> --name "<tema>"` + `/color`.
- [ ] Activar notificaciones de terminal.

## Semana 4 — SDD y loops (S04/S05) ✅ implementadas (primer loop productivo propio pendiente — P12)

- [ ] Instalar specify CLI: `uv tool install specify-cli` (requiere [uv](https://docs.astral.sh/uv/)); verificar con `specify --help`.
- [ ] Elegir el repo piloto del primer track real (pregunta P8 del MD) y correr `/sdd-setup` ahí.
- [ ] Instalar la GitHub App (`/install-github-app`) en repos `haefrain/*` para `@claude` en PRs (S07).
- [ ] Decidir el primer `/loop` productivo propio y su `/schedule` nocturno (P12 del MD).

## Métricas de adopción

- Revisar `/usage` semanalmente (+ tracker de menu bar).
- **La métrica honesta:** ¿cuántos PRs llegaron a merge sin que Efraín tocara el código? (Esta noche: 3 — #5, #6, #7.)
