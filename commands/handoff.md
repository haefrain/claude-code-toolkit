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

Si el handoff generado no refleja trabajo importante de esta sesión (decisiones de diseño, próximos pasos acordados con el usuario), edita el archivo añadiendo esa información en la sección "Próxima sesión" — vos tenés el contexto de la conversación que el script no puede capturar.
