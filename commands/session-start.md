---
description: Arranque de sesión — backlog for:claude, blockers y PRs abiertos en una sola respuesta compacta.
argument-hint: "[owner/repo opcional — si no, detecta desde cwd]"
---

Corre en paralelo estos tres comandos Bash y presenta el resultado en un bloque único:

1. `~/.claude/scripts/gh-backlog.sh $ARGUMENTS`
2. `gh issue list --label "blocked:external" --state open --limit 10 $( [[ -n "$ARGUMENTS" ]] && echo "--repo $ARGUMENTS" )` — issues bloqueados por terceros.
3. `gh pr list --state open --limit 10 $( [[ -n "$ARGUMENTS" ]] && echo "--repo $ARGUMENTS" )` — PRs abiertos.

Presenta el resumen así:

```
## Sesión iniciada — <repo>

### Backlog priorizado (for:claude)
<top 5 por severidad>

### Bloqueados por externos
<lista breve>

### PRs abiertos
<lista breve>

### Sugerencia
<el #issue que debería tomar primero y por qué — máximo 2 líneas>
```

**Importante:** no leas bodies de issues. Solo títulos + labels. La idea es gastar el mínimo de tokens posible al arranque.
