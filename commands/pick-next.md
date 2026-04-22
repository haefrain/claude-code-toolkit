---
description: Sugiere el próximo issue a tomar. Ordena por severidad y dependencias.
argument-hint: "[owner/repo opcional]"
---

1. Corre `~/.claude/scripts/gh-backlog.sh $ARGUMENTS` para ver el backlog priorizado.
2. Escoge el issue de mayor severidad que NO esté bloqueado (`blocked:external` o `needs-decision`).
3. Si hay dependencia declarada (`Bloqueado por: #NN`), verifica que #NN esté cerrado. Si no, pasa al siguiente.
4. Lee SOLO el body del issue elegido: `gh issue view <N> --repo <repo>`.
5. Reporta:
   - Número y título
   - Severidad + área
   - Resumen de 2 líneas del hallazgo
   - Primer criterio de aceptación
   - Archivos mencionados en el body (rutas)
   - **Siguiente acción concreta** que debería hacer Claude

No leas el body de issues que no elegiste.
