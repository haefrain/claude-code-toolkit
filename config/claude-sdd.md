# SDD Buk — tracks y misiones (Sección 05, guía 2026)

Proceso de desarrollo dirigido por specs adaptado a Buk (Pre kick-off → Discovery → Delivery → Rollout), operado con GitHub Spec Kit + skills globales. Fuente de verdad del overlay: repo `claude-code-toolkit`, carpeta `speckit/`.

## Piezas

- **Skills globales** (disponibles en cualquier repo): `buk-track` — tracks (contenedor de misiones, 9 tabs en `docs/tracks/<slug>/`; funciona SIN setup usando las plantillas globales) y `buk-mision` — orquesta las 4 fases sobre `/speckit.*` y sincroniza los 9 tabs de `specs/NNN-<slug>/` (requiere `.specify/`; si falta, ofrece `/sdd-setup`).
- **`/sdd-setup`** — bootstrapea el repo: `specify init` + constitution + overrides + plantillas + reglas del agente.
- **Plantillas, overrides y constitution base:** `~/.claude/templates/buk-speckit/`.

## Reglas duras

1. **Jerarquía track → misión:** leer los docs del track ANTES de especificar una misión; la misión referencia, no duplica. Cada fase cerrada actualiza la bitácora.
2. **Delivery SIEMPRE con TDD** (tests desde los CA primero) y en worktree dedicado. Gate de cierre = contrato de verificación (`.claude/verify.sh`, Sección 01) + `/simplify` + docs actualizadas.
3. **Nunca inventar datos de negocio, clientes o métricas:** preguntar o dejar `[PENDIENTE: …]`. Todo en español, formato oficial de las plantillas.
4. **Política por propietario:** repos `haefrain/*` → artefactos SDD comiteados; repos ajenos (bukhr/*) o sin remote → exclude local + `CLAUDE.local.md` (JAMÁS tocar el CLAUDE.md del equipo).
5. La constitution del repo (`.specify/memory/constitution.md`) manda sobre costumbres y prompts puntuales.
6. SDD aplicará también a bugs grandes con un flujo ligero (por diseñar — no forzar la ceremonia completa de misión a un bugfix).

## Disparadores

| Cuando Efraín dice… | Usar |
|---|---|
| nuevo track / documenta el track / estado del track X / checkpoint del track | skill `buk-track` |
| nueva misión / sigamos con la misión X / pasa a discovery-delivery / sincroniza tabs / tarjetas para Jira / prepara el rollout / cierra la misión | skill `buk-mision` |
| inicializa SDD / configura spec kit en este repo | `/sdd-setup` |
