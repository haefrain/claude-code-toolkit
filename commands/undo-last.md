---
description: Muestra cómo revertir la última acción de Claude (commit, branch, edición). Red de seguridad.
---

1. Corre `git log --oneline -5` y `git status`
2. Corre `git reflog -10` para ver las últimas operaciones

Luego muestra una tabla con las últimas acciones reversibles y el comando EXACTO para revertir cada una:

| Acción | Comando para revertir |
|---|---|
| Último commit (sin push) | `git reset --soft HEAD~1` |
| Último commit (ya pusheado) | `git revert HEAD` |
| Archivos editados sin stage | `git checkout -- <archivo>` |
| Archivos staged sin commit | `git restore --staged <archivo>` |
| Rama creada por error | `git branch -d <rama>` |

**IMPORTANTE:** No ejecutes ningún revert automáticamente. Solo mostrar opciones y esperar confirmación explícita del usuario.
