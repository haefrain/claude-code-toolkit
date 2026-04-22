---
description: Auditoría rápida de PII en logs y secretos hardcoded en el path indicado.
argument-hint: "[path opcional, default .]"
---

Corre en paralelo estos dos comandos Bash:

1. `~/.claude/scripts/audit-pii.sh $ARGUMENTS`
2. `~/.claude/scripts/audit-secrets.sh $ARGUMENTS`

Presenta los resultados combinados. Para cada grupo de hits:
- Muestra máximo 5 ejemplos (los más representativos)
- Clasifica cada hit como: **confirmado**, **falso positivo probable**, o **requiere revisión manual**
- NO propongas fixes ni crees issues. Solo reporta.

Al final, si hay hits confirmados, sugiere: *"¿Quieres que delegue al agente `issue-manager` para crear issues [SEC-NNN]?"* — pero NO lo hagas sin confirmación.
