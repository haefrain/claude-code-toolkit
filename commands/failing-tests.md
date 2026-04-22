---
description: Extrae solo los tests fallidos del último CI run. Sin el dump completo del log.
argument-hint: "[run-id] [owner/repo]"
---

Corre `~/.claude/scripts/failing-tests.sh $ARGUMENTS`. Si no se especifica run-id, usa el último run fallido automáticamente. Mostrar el output y sugerir el siguiente paso concreto para arreglar el primer fallo.
