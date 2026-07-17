
<!-- BUK-SPECKIT:INICIO -->
## Proceso BUK (tracks y misiones) — reglas para el agente
- Gobernanza: `.specify/memory/constitution.md` manda sobre cualquier costumbre.
- Jerarquía: track (docs/tracks/<slug>/, skill buk-track) → misión (specs/NNN-<slug>/,
  skill buk-mision sobre /speckit.*). Leer los docs del track ANTES de especificar una misión.
- Fases de misión: Pre kick-off → Discovery → Delivery → Rollout. Un .md por tab,
  sincronizado desde spec/plan/tasks al cerrar cada fase.
- Delivery SIEMPRE en worktree dedicado y con TDD (tests desde los CA primero).
- Gate antes de PR: suite verde + browser si hay UI + /simplify + docs actualizadas.
- Nunca inventar datos de negocio, clientes o métricas: preguntar o dejar [PENDIENTE: …].
- Todo en español, formato oficial de las plantillas de docs/plantillas/.
- Si cometes un error de proceso: corrígelo y actualiza este CLAUDE.md para no repetirlo.
<!-- BUK-SPECKIT:FIN -->
