---
description: Recarga el contexto enriquecido en la sesión actual — handoff anterior, memorias del proyecto, codegraph y capacidades disponibles.
argument-hint: ""
---

Ejecuta y presenta el output:

```bash
bash ~/.claude/scripts/load-context.sh
```

Si hay output, preséntalo como contexto activo y tenelo en cuenta para el resto de la sesión — en particular la sección "Capacidades disponibles": usá siempre la herramienta más específica (script del toolkit > comando crudo; codegraph > grep manual; skill > improvisación).

Si no hay output (sin handoff previo), muestra:
"No hay contexto previo para este proyecto. Usá `/session-start` para cargar el backlog o `/codegraph-init` para inicializar el índice de código."
