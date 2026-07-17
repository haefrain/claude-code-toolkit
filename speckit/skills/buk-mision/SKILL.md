---
name: buk-mision
description: Orquesta una MISIÓN del proceso BUK sobre spec-kit — Pre kick-off, Discovery, Delivery y Rollout — y sincroniza los 9 tabs .md de la misión desde spec.md/plan.md/tasks.md. Usa esta skill siempre que el usuario mencione crear o avanzar una misión, sincronizar tabs o documentos de misión, generar tarjetas para Jira, preparar el rollout, activar/eliminar una feature flag de misión, o cerrar una misión con su retro — aunque solo diga "sigamos con la misión X" o "pasa a discovery/delivery".
---

# buk-mision — Fases de una misión BUK sobre spec-kit

**Fuente de verdad:** `spec.md`, `plan.md`, `tasks.md` (formato BUK vía overrides).
Los tabs `00–08` de `specs/NNN-<slug>/` se DERIVAN de ellos: para corregir contenido,
editar la fuente y re-sincronizar — nunca editar solo el tab.

## Fase 0 · Prerrequisito

Verificar que el repo tenga `.specify/` (Spec Kit inicializado). Si falta, **ofrecer
correr `/sdd-setup`** y esperar confirmación del usuario — sin `.specify/` los comandos
`/speckit.*` no existen y esta skill no puede operar. (buk-track sí funciona sin setup.)

## Fase 1 · Pre kick-off
1. Confirmar el track (leer `docs/tracks/<slug>/` completo antes de especificar; si no
   existe, ofrecer crearlo con buk-track o marcar misión aislada).
2. Correr `/speckit.specify` con el problema/tarea que dé el usuario + contexto del track.
3. Sincronizar tabs iniciales (ver procedimiento) y registrar el kick-off en `00-bitacora.md`.
4. Datos de negocio faltantes → `[PENDIENTE: …]`; preguntar, no inventar.

## Ecosistema Buk (plugin claude-toolkit@buk-skills-marketplace)

Si el plugin de Buk está activo en la sesión, COMPONER con sus skills oficiales en vez
de duplicar: **`checkpoint`** gestiona los kick-offs/checkpoints oficiales (usarla al
cerrar cada fase y reflejar los acuerdos en `00-bitacora.md`); **`user-discovery-report`**
arma el informe de señales (Amplitude/Clarity/Sentry) para Discovery;
**`edit-google-docs-by-buk`** permite volcar los tabs sincronizados al Google Doc oficial
del template — ofrecerlo tras cada sync (solo con OK explícito del usuario). Sin el
plugin, todo funciona igual con los archivos locales.

## Fase 2 · Discovery
1. `/speckit.clarify` para cerrar ambigüedades con el usuario.
2. `/speckit.plan` — antes, explorar el código real del repo; la técnica se basa en el
   estado actual, con diagramas mermaid del modelo REAL y alternativas evaluadas.
3. `/speckit.tasks` → tarjetas formato Jira (override). Si hay MCP de Atlassian
   conectado, ofrecer crearlas en Jira SOLO tras aprobación explícita del usuario.
4. `/speckit.analyze` para validar consistencia spec↔plan↔tasks↔constitution.
5. **Sincronizar tabs** y registrar checkpoint en la bitácora.

## Fase 3 · Delivery
1. Recordar/lanzar worktree dedicado: `claude --worktree <slug>` (constitution IV).
2. `/speckit.implement` respetando TDD estricto: por tarjeta, tests desde sus CA primero
   (red), código mínimo (green), refactor. `/speckit.converge` si el avance divergió.
3. Gate de cierre: suite verde + verificación en browser para UI + pase `/simplify` +
   docs del módulo actualizadas. Sin gate completo no hay PR.

## Fase 4 · Rollout y cierre
1. Completar `07-gtm.md`: nombre real de la FF, fases (interno → beta → olas → 100%),
   plan de rollback, instrumentación y checklist del revisor. `/speckit.checklist` puede
   generar checklists de calidad adicionales.
2. Recordar la tarjeta de **eliminación de la FF** al llegar al 100%.
3. Cierre: guiar `08-retro.md`, actualizar el track (index + estrategia + bitácora vía
   buk-track) y responder la pregunta CLAVE de la retro.

## Procedimiento de sincronización de tabs

En `specs/NNN-<slug>/`, generar/actualizar desde las plantillas `docs/plantillas/mision/`:

| Tab | Fuente |
|---|---|
| `index.md` | metadatos de spec.md + FF + links |
| `00-bitacora.md` | entradas dictadas por el usuario (nunca se regenera, solo se añade) |
| `01-negocio.md` | spec.md § 1 |
| `02-criterios-aceptacion.md` | spec.md § 3 |
| `03-tecnica.md` | plan.md §§ 1–4 |
| `04-alternativas.md` | plan.md § 5 |
| `05-pruebas.md` | CA + plan (tabla CP con `RF-xx-CA-yy`; mallas si hay datos críticos) |
| `06-experiencia.md` | spec (JTBD/flujos) + plan (UI); wireframes/compound con el usuario |
| `07-gtm.md` | plantilla + decisiones de rollout del usuario |
| `08-retro.md` | solo al cierre, con el usuario |

Reglas de sync: conservar ediciones manuales marcadas `<!-- manual -->`, mantener
`[PENDIENTE]` visibles, español y formato oficial de las plantillas, y avisar al final
qué tabs cambiaron (lista corta de rutas).
