---
description: Corre solo los tests relacionados al archivo modificado. Detecta jest/vitest/phpunit/pytest/flutter.
argument-hint: "[archivo] [path]"
---

Corre `~/.claude/scripts/test-focus.sh $ARGUMENTS`.

Si no se especifica archivo, el script lista los archivos modificados como candidatos. Si hay errores de test, reportarlos con el mensaje exacto — no intentar arreglarlos sin leer el archivo de test primero.
