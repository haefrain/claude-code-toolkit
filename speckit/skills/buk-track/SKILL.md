---
name: buk-track
description: Crea y mantiene la documentación de un TRACK del proceso BUK (contenedor de misiones) en docs/tracks/<slug>/ con un .md por tab. Usa esta skill siempre que el usuario mencione crear, documentar, actualizar o cerrar un track, agregar una misión a un track, registrar un checkpoint o kick-off en la bitácora del track, o pida el estado de un track — aunque no diga la palabra "skill". Los tracks NO son features de spec-kit; las misiones sí (skill buk-mision).
---

# buk-track — Documentación de tracks BUK

Un track agrupa varias misiones y tiene 9 tabs propios como archivos `.md` en
`docs/tracks/<slug>/`, creados desde `docs/plantillas/track/`.

## Crear un track nuevo

1. **Slug:** kebab-case corto acordado con el usuario (`onboarding-masivo`).
2. **Explorar antes de escribir:** revisar el código del repo, `docs/` existente y
   `specs/` para entender el estado actual del sistema en el dominio del track. La
   documentación se basa en lo que HAY, no en supuestos.
3. **Scaffolding:** copiar las plantillas → `docs/tracks/<slug>/` (index + 00–08, sin
   renombrar). Fuente: `docs/plantillas/track/` del repo si existe; si no, el fallback
   global `~/.claude/templates/buk-speckit/plantillas/track/` (funciona en cualquier
   repo sin setup previo).
   **Repos ajenos** (remote no `haefrain/*` o sin remote): si `/sdd-setup` no corrió aún,
   ANTES de crear archivos agregá `docs/tracks/` al exclude local:
   `root=$(git rev-parse --show-toplevel); ef=$(git -C "$root" rev-parse --git-path info/exclude); [[ "$ef" = /* ]] || ef="$root/$ef"; grep -qxF "docs/tracks/" "$ef" 2>/dev/null || echo "docs/tracks/" >> "$ef"`
   — los artefactos SDD no se comitean a repos de terceros sin decisión de Efraín.
4. **Entrevista de negocio (no inventar):** preguntar al usuario, en tandas cortas, lo
   mínimo para `01-negocio.md`: problema en dolores del usuario, JTBD, scope propuesto,
   candidatos a pilotos, criterios de éxito (qué/cómo/cuándo). Todo dato de negocio,
   cliente o métrica que el usuario no dé queda como `[PENDIENTE: …]` — NUNCA se inventa.
5. **Llenar lo inferible del código:** en `02-requerimientos.md` (RNF técnicos
   evidentes), `03-tecnica.md` (arquitectura actual, integraciones existentes, diagrama
   mermaid del modelo de datos REAL) y `04-alternativas.md` (opciones técnicas reales
   del contexto). Marcar cada inferencia con su origen (`<!-- inferido de app/models/… -->`).
6. **Registrar el kick-off** en `00-bitacora.md` con acuerdos y action items dictados
   por el usuario.

## Mantener un track

- **Checkpoints:** cada vez que el usuario reporte un checkpoint, añadir la entrada a
  `00-bitacora.md` (agenda/acuerdos/action items) y propagar los cambios acordados al
  tab que corresponda (scope → 01, RNF → 02, arquitectura → 03, misiones → 05, GTM → 07).
- **Misiones:** al crear o cerrar una misión (skill buk-mision), actualizar la tabla de
  `index.md` (estado + link a `specs/NNN-slug/`) y `05-estrategia-desarrollo.md`.
  Proponer siempre solo las próximas 2–3 misiones.
- **Retro de cierre:** al cerrar el track, guiar `08-retro.md` con las preguntas del
  template y dejar la pregunta CLAVE respondida explícitamente.

## Reglas

- Español, tono BUK, respetar títulos y tablas de las plantillas (formato oficial).
- Convenciones de IDs de la constitution (JTBD/RF/S/RNF).
- Diagramas siempre en mermaid con fuente en el propio archivo.
- El track declara lineamientos generales; la profundidad vive en cada misión — no
  duplicar contenido entre niveles.
