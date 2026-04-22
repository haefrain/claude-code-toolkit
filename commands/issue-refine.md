---
description: Valida un issue contra el checklist de calidad de CLAUDE.md. No edita, solo reporta.
argument-hint: "<issue-number> [owner/repo]"
---

Toma el issue #$ARGUMENTS y valida el checklist de calidad de CLAUDE.md:

1. Lee el issue: `gh issue view <N> --repo <repo>`
2. Corre `~/.claude/scripts/gh-cross-ref.sh <N>` para validar referencias cruzadas.
3. Revisa:
   - ¿Título sigue convención `[PREFIJO-NNN] ...`?
   - ¿Tiene secciones "Hallazgo", "Por qué", "Criterios de aceptación", "Referencias"?
   - ¿Criterios de aceptación son verificables (no vagos)?
   - ¿Cada archivo mencionado trae `path:line`?
   - ¿Labels obligatorias: `severity:*`, `for:*`, `type:*`, al menos un `area:*`?
   - ¿Tiene assignee si es `for:efrain`?
   - ¿Las referencias #NN existen y están en estado coherente?
   - ¿Está agregado al Project v2 correspondiente?

Reporta en formato checklist con ✅/❌, y para cada ❌ sugiere el cambio concreto. **NO edites el issue.** Al final: *"¿Aplico estas correcciones vía `issue-manager`?"*.
