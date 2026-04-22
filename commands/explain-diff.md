---
description: Resume un diff en 3 categorías — cambios mecánicos, cambios de lógica y riesgos. Sin leer cada archivo completo.
argument-hint: "[ref o rango de commits, ej: HEAD~3..HEAD o main..branch]"
---

1. Corre `git diff $ARGUMENTS` (si no hay argumento, usa `git diff HEAD`)
2. Corre `git diff --stat $ARGUMENTS` para el resumen de archivos

Luego resume en exactamente 3 secciones:

**Cambios mecánicos** — renombres, formateo, imports, tipos, refactors sin cambio de comportamiento. Una línea por item.

**Cambios de lógica** — condiciones nuevas, flujos alterados, efectos secundarios, cambios en DB o API. Una línea por item.

**Riesgos** — breaking changes, migraciones sin rollback, auth alterada, campos PII tocados, dependencias subidas. Si no hay ninguno: "(ninguno detectado)".

Máximo 15 líneas totales. Si el diff es muy grande, avisarlo y pedir que se acote.
