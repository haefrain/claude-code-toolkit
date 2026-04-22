---
description: Callers, imports y tests de un símbolo. Usar ANTES de modificar cualquier función/endpoint.
argument-hint: "<símbolo> [path]"
---

Corre `~/.claude/scripts/find-usages.sh $ARGUMENTS` y muestra el resultado.

Si el resultado muestra 0 callers → símbolo probablemente es código muerto. Reportarlo antes de modificar.
Si hay múltiples puntos de escritura → el issue/fix debe cubrir todos, no solo el primero encontrado.
