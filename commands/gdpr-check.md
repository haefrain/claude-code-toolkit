---
description: Triage express de compliance en un solo comando — PII en logs, secretos, campos sin cifrar, auth y rate limit.
argument-hint: "[path]"
---

Corre `~/.claude/scripts/gdpr-quick-check.sh $ARGUMENTS`.

Al terminar, clasifica los hallazgos en:
- 🔴 Crítico (fuga de datos activa, secretos expuestos)
- 🟠 Alto (PII sin cifrar en DB, endpoints críticos sin auth)
- 🟡 Medio (endpoints sin rate limit, logs con PII no sensible)

Luego preguntar: *"¿Creo los issues correspondientes via `issue-manager`?"* — NO crearlos sin confirmación.
