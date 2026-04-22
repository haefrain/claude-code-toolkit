---
description: Busca un término solo en documentación (*.md, *.mdx, JSDoc). Evita leer código cuando la respuesta está documentada.
argument-hint: "<término> [path]"
---

Corre `~/.claude/scripts/search-docs.sh $ARGUMENTS` y muestra el resultado. Si encuentra matches relevantes, leer solo los archivos .md que los contienen — no explorar código fuente a menos que la doc sea insuficiente.
