# Instrucciones Globales — Claude Code

## Idioma

SIEMPRE responde en español. Código fuente, variables y commits pueden estar en el idioma del proyecto.

---

## Gestión de tareas — Reglas duras

1. **TODA tarea persistente → GitHub Issues** vinculada a su Project. No sistemas paralelos.
2. **Dueño único:** `for:efrain` (+ assignee `haefrain`) o `for:claude` (sin assignee).
3. **`TaskCreate/TaskUpdate` = solo dentro de UNA conversación.** Al terminar la sesión se pierde.
4. **Al iniciar sesión:** `~/.claude/scripts/gh-backlog.sh` para ver qué retomar.
5. **Al cerrar trabajo:** `gh issue close N --reason completed --comment "..."` + `Closes #N` en PR.

**Causa raíz obligatoria (Regla ReclamaAI #46/48):** antes de crear un issue de bug, corre `grep -rn "X(" --include="*.ts"`. Si 0 callers → código muerto, el issue es distinto. En 2026-04-07 se "arregló" una función muerta (`updateUser()` en `lib/db/queries/users.ts`) sin verificar callers; el bug real estaba en `app/api/users/me/route.ts:76`. El issue correcto nunca se ejecutó. Cinco minutos de grep evitan esto.

**Antes de crear cualquier issue:**
- ¿Causa raíz verificada con grep (no asumida)?
- ¿Criterios de aceptación verificables?
- ¿Todos los archivos con `path:line`?
- ¿`for:claude` o `for:efrain`? Si duda: dos issues separados.
- Si no tenés claro el contexto, severidad o criterios: **PREGUNTA antes de crear.**

**Bootstrap repo nuevo:** `~/.claude/scripts/gh-bootstrap-labels.sh owner/repo`

@claude-issues.md

---

## Toolkit de optimización de tokens

@claude-toolkit.md

---

## Flujo de sesión

1. **Inicio:** `gh-backlog.sh` (o esperar que el hook SessionStart lo haga automático en repos haefrain/*).
2. **Durante:** si aparece trabajo nuevo → issue antes de empezar.
3. **Al terminar:** cerrar issues completados + comentario con commit/PR.
4. **Si bloqueas:** comentar en el issue + label `blocked:external` o `needs-decision`.

@RTK.md
